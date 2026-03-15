const fs = require('fs');
const path = require('path');

const RULE_FILE = path.join(__dirname, '..', 'config', 'adapter-rules.sample.json');

function getAdapterRules() {
  const rawText = fs.readFileSync(RULE_FILE, 'utf-8');
  return JSON.parse(rawText);
}

module.exports = {
  getAdapterRules,
};