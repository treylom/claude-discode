import asyncio
import sys
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

from fastapi.testclient import TestClient

SCRIPTS_DIR = Path(__file__).resolve().parent
if str(SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_DIR))


class SearchServerHealthTest(unittest.TestCase):
    def test_health_endpoint_returns_ok(self):
        import search_server

        client = TestClient(search_server.app)
        response = client.get('/health')

        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data['status'], 'ok')
        self.assertIn('models_ready', data)


class SearchModeTest(unittest.TestCase):
    def test_valid_modes_accepted(self):
        import search_server

        client = TestClient(search_server.app)

        for mode in ['hybrid', 'quick', 'deep']:
            with self.subTest(mode=mode), \
                 patch.object(search_server._models_ready, 'wait', return_value=True), \
                 patch.object(search_server.app.state, 'conn', 'CONN', create=True), \
                 patch.object(search_server.app.state, 'index_dir', 'INDEX', create=True), \
                 patch.object(search_server.graph_search, 'hybrid_search', return_value=[]):
                response = client.get('/api/search', params={'q': 'test', 'mode': mode})

            self.assertEqual(response.status_code, 200)
            data = response.json()
            self.assertEqual(data['source'], 'hybrid')
            self.assertEqual(data['results'], [])

    def test_invalid_mode_rejected(self):
        import search_server

        client = TestClient(search_server.app)
        response = client.get('/api/search', params={'q': 'test', 'mode': 'dense'})

        self.assertEqual(response.status_code, 400)
        self.assertEqual(
            response.json()['detail'],
            "Invalid mode: dense. Valid: ['deep', 'hybrid', 'quick']",
        )


class SearchServerLazyGraphTest(unittest.TestCase):
    def test_load_runtime_state_defers_graph_build(self):
        # v2.3.3 drift fix: search_server 안 `get_connection` symbol 없음 — 실제 `_open_readonly_connection`.
        # Path.exists mock 으로 v2.3.1 graceful fix 의 db_p.exists() branch 도 cover.
        import search_server

        with patch.object(search_server, '_open_readonly_connection', return_value='CONN') as open_conn, \
             patch('pathlib.Path.exists', return_value=True), \
             patch.object(search_server, 'build_networkx_graph') as build_graph:
            state = search_server._load_runtime_state()

        open_conn.assert_called_once()
        # _warm_models is now called in background thread (lifespan), not in _load_runtime_state
        build_graph.assert_not_called()
        self.assertEqual(state['conn'], 'CONN')
        self.assertIsNone(state['graph'])


class SearchServerV231ConnNoneRegressionTest(unittest.TestCase):
    """v2.3.1 + v2.3.2 conn=None regression tests (Phase 2 finding 안 backfill)."""

    def test_load_runtime_state_graceful_when_db_missing(self):
        # v2.3.1: db_path.exists() False 시 conn = None
        import search_server

        with patch('pathlib.Path.exists', return_value=False):
            state = search_server._load_runtime_state()

        self.assertIsNone(state['conn'])
        self.assertIsNone(state['graph'])

    def test_api_search_returns_503_when_conn_none(self):
        # v2.3.2: /api/search conn=None → HTTPException 503
        import search_server

        client = TestClient(search_server.app)
        with patch.object(search_server.app.state, 'conn', None, create=True), \
             patch.object(search_server._models_ready, 'wait', return_value=True):
            response = client.get('/api/search', params={'q': 'test', 'mode': 'hybrid'})

        self.assertEqual(response.status_code, 503)
        self.assertIn('error', response.json()['detail'])

    def test_get_graph_returns_503_when_conn_none(self):
        # v2.3.2: _get_graph() conn=None → HTTPException 503
        import search_server
        from fastapi import HTTPException

        app = SimpleNamespace(state=SimpleNamespace(conn=None, graph=None))
        with self.assertRaises(HTTPException) as ctx:
            search_server._get_graph(app)
        self.assertEqual(ctx.exception.status_code, 503)

    def test_ready_endpoint_returns_503_when_db_not_ready(self):
        # v2.3.2: /ready endpoint 별도 — conn=None 시 503
        import search_server

        client = TestClient(search_server.app)
        with patch.object(search_server.app.state, 'conn', None, create=True):
            response = client.get('/ready')

        self.assertEqual(response.status_code, 503)
        detail = response.json()['detail']
        self.assertFalse(detail['ready'])
        self.assertEqual(detail['reason'], 'db_not_ready')

    def test_get_graph_builds_once_and_reuses_cached_graph(self):
        import search_server

        app = SimpleNamespace(state=SimpleNamespace(conn='CONN', graph=None))

        with patch.object(search_server, 'build_networkx_graph', side_effect=['GRAPH']) as build_graph:
            first = search_server._get_graph(app)
            second = search_server._get_graph(app)

        self.assertEqual(first, 'GRAPH')
        self.assertEqual(second, 'GRAPH')
        self.assertEqual(app.state.graph, 'GRAPH')
        build_graph.assert_called_once_with('CONN')

    def test_reload_clears_hybrid_cache(self):
        import search_server

        app = search_server.app
        original_state = {
            'db_path': getattr(app.state, 'db_path', None),
            'index_dir': getattr(app.state, 'index_dir', None),
            'conn': getattr(app.state, 'conn', None),
            'graph': getattr(app.state, 'graph', None),
        }

        app.state.db_path = 'dummy.db'
        app.state.index_dir = 'dummy-index'
        app.state.conn = 'OLD_CONN'
        app.state.graph = 'OLD_GRAPH'

        try:
            async def run_test():
                with patch.object(search_server.graph_search, 'clear_hybrid_cache') as clear_hybrid, \
                     patch.object(search_server, '_load_runtime_state', return_value={
                         'db_path': 'new.db',
                         'index_dir': 'new-index',
                         'conn': 'NEW_CONN',
                         'graph': None,
                     }) as load_state, \
                     patch.object(search_server, '_replace_runtime_state') as replace_state:
                    response = await search_server.reload_models()

                clear_hybrid.assert_called_once_with()
                load_state.assert_called_once()
                replace_state.assert_called_once_with(app, {
                    'db_path': 'new.db',
                    'index_dir': 'new-index',
                    'conn': 'NEW_CONN',
                    'graph': None,
                })
                self.assertEqual(response['status'], 'reloaded')
                self.assertEqual(response['db_path'], 'dummy.db')
                self.assertEqual(response['index_dir'], 'dummy-index')

            asyncio.run(run_test())
        finally:
            for key, value in original_state.items():
                setattr(app.state, key, value)


if __name__ == '__main__':
    unittest.main()
