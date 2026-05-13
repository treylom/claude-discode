import sqlite3
import sys
import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch

SCRIPTS_DIR = Path(__file__).resolve().parent
if str(SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_DIR))

import graph_search


def _candidate(name, **overrides):
    candidate = {
        'entity': name,
        'name': name,
        'type': 'note',
        'source_note': f'{name.lower()}.md',
        'description': f'{name} description',
        'centrality_score': 0.0,
        'source': 'dense',
        'alias_matched': False,
        'matched_alias': '',
    }
    candidate.update(overrides)
    return candidate


class HybridSearchCacheTest(unittest.TestCase):
    def setUp(self):
        if hasattr(graph_search, 'clear_hybrid_cache'):
            graph_search.clear_hybrid_cache()

    def tearDown(self):
        if hasattr(graph_search, 'clear_hybrid_cache'):
            graph_search.clear_hybrid_cache()

    def test_hybrid_search_caches_repeated_queries(self):
        call_count = 0

        def fake_fts5_search(conn, query, limit):
            nonlocal call_count
            call_count += 1
            return [
                {'name': 'Alpha', 'type': 'note', 'description': 'A', 'source_note': 'alpha.md', 'centrality_score': 1.0},
                {'name': 'Beta', 'type': 'note', 'description': 'B', 'source_note': 'beta.md', 'centrality_score': 0.8},
                {'name': 'Gamma', 'type': 'note', 'description': 'C', 'source_note': 'gamma.md', 'centrality_score': 0.6},
            ]

        with patch.object(graph_search, '_EMBEDDING_AVAILABLE', False), \
             patch.object(graph_search, 'fts5_search', side_effect=fake_fts5_search), \
             patch.object(graph_search, '_decompose_query', return_value=[]):
            first = graph_search.hybrid_search(
                MagicMock(),
                'cached query',
                top_k=3,
                sparse_weight=1.0,
                decomposed_weight=0.0,
                entity_weight=0.0,
            )
            second = graph_search.hybrid_search(
                MagicMock(),
                'cached query',
                top_k=3,
                sparse_weight=1.0,
                decomposed_weight=0.0,
                entity_weight=0.0,
            )

        self.assertEqual(call_count, 1)
        self.assertEqual(first, second)
        self.assertIsNot(first, second)
        self.assertIsNot(first[0], second[0])


class HybridSearchCommunitySummaryTest(unittest.TestCase):
    def setUp(self):
        if hasattr(graph_search, 'clear_hybrid_cache'):
            graph_search.clear_hybrid_cache()

    def tearDown(self):
        if hasattr(graph_search, 'clear_hybrid_cache'):
            graph_search.clear_hybrid_cache()

    def test_hybrid_search_includes_summary_matched_community_entities(self):
        conn = sqlite3.connect(':memory:')
        conn.row_factory = sqlite3.Row
        conn.execute(
            'CREATE TABLE communities (id INTEGER PRIMARY KEY, level INTEGER, name TEXT, summary TEXT)'
        )
        conn.execute(
            'CREATE TABLE entities (id INTEGER PRIMARY KEY, name TEXT, type TEXT, description TEXT, source_note TEXT, centrality_score REAL, community_id INTEGER)'
        )
        conn.execute(
            'INSERT INTO communities (id, level, name, summary) VALUES (1, 1, ?, ?)',
            ('정치와 사회', '정치 사회 글쓰기와 민주주의 연구를 연결하는 허브')
        )
        conn.execute(
            'INSERT INTO entities (id, name, type, description, source_note, centrality_score, community_id) VALUES (1, ?, ?, ?, ?, ?, ?)',
            ('Hub-001', 'note', '커뮤니티 허브 노트', 'hub-001.md', 0.9, 1)
        )
        conn.commit()

        with patch.object(graph_search, '_EMBEDDING_AVAILABLE', False), \
             patch.object(graph_search, 'fts5_search', return_value=[]), \
             patch.object(graph_search, '_decompose_query', return_value=[]):
            results = graph_search.hybrid_search(
                conn,
                '정치 사회 연결',
                top_k=5,
                sparse_weight=1.0,
                decomposed_weight=0.0,
                entity_weight=0.0,
            )

        self.assertTrue(results)
        self.assertEqual(results[0]['entity'], 'Hub-001')
        self.assertIn('community', results[0]['source'])
        conn.close()


class RerankFilterTest(unittest.TestCase):
    def test_negative_scores_filtered(self):
        candidates = [
            _candidate('Alpha', description='Alpha candidate'),
            _candidate('Beta', description='Beta candidate'),
            _candidate('Gamma', description='Gamma candidate'),
            _candidate('Delta', description='Delta candidate'),
        ]
        ce = MagicMock()
        ce.predict.return_value = [0.8, -0.1, 0.2, -0.7]

        with patch.object(graph_search, '_get_cross_encoder', return_value=ce):
            results = graph_search.rerank('alpha query', candidates, top_k=4)

        self.assertEqual([result['entity'] for result in results], ['Alpha', 'Gamma', 'Beta'])
        self.assertNotIn('Delta', [result['entity'] for result in results])
        self.assertEqual(results[2]['rerank_score'], -0.1)

    def test_min_3_safeguard(self):
        candidates = [
            _candidate('Alpha'),
            _candidate('Beta'),
            _candidate('Gamma'),
            _candidate('Delta'),
        ]
        ce = MagicMock()
        ce.predict.return_value = [-0.8, -0.2, -1.1, -0.5]

        with patch.object(graph_search, '_get_cross_encoder', return_value=ce):
            results = graph_search.rerank('negative query', candidates, top_k=4)

        self.assertEqual(len(results), 3)
        self.assertEqual([result['entity'] for result in results], ['Beta', 'Delta', 'Alpha'])
        self.assertEqual([result['rerank_score'] for result in results], [-0.2, -0.5, -0.8])


class AliasRerankerTest(unittest.TestCase):
    def test_alias_prefix_injected(self):
        candidates = [
            _candidate(
                'Alpha',
                alias_matched=True,
                matched_alias='Some Alias',
                source='like',
                source_note='alpha.md',
                description='Alias candidate',
            )
        ]
        captured_pairs = []
        ce = MagicMock()

        def capture_pairs(pairs):
            captured_pairs.extend(pairs)
            return [0.9]

        ce.predict.side_effect = capture_pairs

        with patch.object(graph_search, '_get_cross_encoder', return_value=ce):
            graph_search.rerank('alias query', candidates, top_k=1)

        self.assertEqual(len(captured_pairs), 1)
        self.assertEqual(
            captured_pairs[0],
            ('alias query', '[alias: Some Alias] Alpha alpha.md Alias candidate'),
        )

    def test_no_alias_prefix_for_non_alias(self):
        candidates = [
            _candidate(
                'Alpha',
                alias_matched=False,
                matched_alias='',
                source='dense',
                source_note='alpha.md',
                description='Plain candidate',
            )
        ]
        captured_pairs = []
        ce = MagicMock()

        def capture_pairs(pairs):
            captured_pairs.extend(pairs)
            return [0.4]

        ce.predict.side_effect = capture_pairs

        with patch.object(graph_search, '_get_cross_encoder', return_value=ce):
            graph_search.rerank('plain query', candidates, top_k=1)

        self.assertEqual(len(captured_pairs), 1)
        self.assertEqual(
            captured_pairs[0],
            ('plain query', 'Alpha alpha.md Plain candidate'),
        )
        self.assertNotIn('[alias:', captured_pairs[0][1])


if __name__ == '__main__':
    unittest.main()
