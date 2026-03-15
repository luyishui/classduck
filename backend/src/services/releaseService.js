const fs = require('fs');
const path = require('path');

const RELEASE_FILE = path.join(__dirname, '..', 'config', 'release.sample.json');

function compareVersions(a, b) {
  const av = String(a).split('.').map((n) => Number(n) || 0);
  const bv = String(b).split('.').map((n) => Number(n) || 0);
  const len = Math.max(av.length, bv.length);

  for (let i = 0; i < len; i++) {
    const ai = av[i] ?? 0;
    const bi = bv[i] ?? 0;
    if (ai > bi) return 1;
    if (ai < bi) return -1;
  }
  return 0;
}

function getReleaseInfo() {
  const rawText = fs.readFileSync(RELEASE_FILE, 'utf-8');
  return JSON.parse(rawText);
}

function checkRelease({ currentVersion, platform }) {
  const release = getReleaseInfo();
  const latestVersion = String(release.latestVersion || '0.0.0');
  const cmp = compareVersions(String(currentVersion || '0.0.0'), latestVersion);

  return {
    hasNewVersion: cmp < 0,
    latestVersion,
    currentVersion: String(currentVersion || '0.0.0'),
    updateUrl: platform === 'ios' ? release.iosStoreUrl : release.androidStoreUrl,
    releaseNotes: Array.isArray(release.releaseNotes) ? release.releaseNotes.join('\n') : '',
  };
}

module.exports = {
  checkRelease,
};