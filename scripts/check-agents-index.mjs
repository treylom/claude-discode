// check-agents-index.mjs — verify agents.yaml index matches .agents/*.yaml
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import yaml from 'js-yaml';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const agentsDir = path.join(ROOT, '.agents');
const indexPath = path.join(ROOT, 'agents.yaml');

if (!fs.existsSync(agentsDir)) {
  console.error(`FAIL: ${agentsDir} not found`);
  process.exit(1);
}

const files = fs.readdirSync(agentsDir).filter(f => f.endsWith('.yaml'));
const declared = files.map(f => {
  const doc = yaml.load(fs.readFileSync(path.join(agentsDir, f), 'utf8'));
  return doc.name;
}).filter(Boolean).sort();

let indexed = [];
if (fs.existsSync(indexPath)) {
  const doc = yaml.load(fs.readFileSync(indexPath, 'utf8'));
  indexed = (doc.agents ?? []).map(a => a.name).filter(Boolean).sort();
} else {
  console.error(`FAIL: ${indexPath} not found — run scripts/generate-agents-index.mjs --apply`);
  process.exit(1);
}

const missing = declared.filter(n => !indexed.includes(n));
const extra = indexed.filter(n => !declared.includes(n));

if (missing.length || extra.length) {
  console.error('FAIL index mismatch');
  if (missing.length) console.error('  missing in agents.yaml:', missing);
  if (extra.length) console.error('  extra in agents.yaml:', extra);
  process.exit(1);
}
console.log(`PASS index (count=${declared.length})`);
