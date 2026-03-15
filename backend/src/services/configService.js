const fs = require('fs');
const path = require('path');

const CONFIG_FILE = path.join(__dirname, '..', 'config', 'schools.sample.json');

function getSchoolConfigList() {
  const rawText = fs.readFileSync(CONFIG_FILE, 'utf-8');
  return JSON.parse(rawText);
}

module.exports = {
  getSchoolConfigList,
};
