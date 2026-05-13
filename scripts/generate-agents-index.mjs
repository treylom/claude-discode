// generate-agents-index.mjs — produce agents.yaml from .agents/*.yaml
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import yaml from 'js-yaml';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const agentsDir = path.join(ROOT, '.agents');
const indexPath = path.join(ROOT, 'agents.yaml');
const apply = process.argv.includes('--apply');

if (!fs.existsSync(agentsDir)) {
  console.error(`FAIL: ${agentsDir} not found`);
  process.exit(1);
}

const files = fs.readdirSync(agentsDir).filter(f => f.endsWith('.yaml')).sort();
const agents = files.map(f => {
  const doc = yaml.load(fs.readFileSync(path.join(agentsDir, f), 'utf8'));
  return {
    name: doc.name,
    version: doc.version,
    tier: doc.tier,
    description: doc.description,
    file: `.agents/${f}`
  };
});

const index = {
  index_version: 1,
  generated_at: new Date().toISOString().slice(0, 10),
  count: agents.length,
  agents
};

const out = yaml.dump(index, { lineWidth: 120, noRefs: true });
if (apply) {
  fs.writeFileSync(indexPath, out);
  console.log(`wrote ${indexPath} (${agents.length} agents)`);
} else {
  process.stdout.write(out);
}
