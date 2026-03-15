const fs = require('fs');
const path = require('path');

const LOG_FILE = path.join(__dirname, '..', '..', 'runtime', 'import-logs.ndjson');

function appendImportLog(payload) {
  const line = JSON.stringify(payload) + '\n';
  fs.appendFileSync(LOG_FILE, line, 'utf-8');
}

module.exports = {
  appendImportLog,
};
