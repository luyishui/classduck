const express = require('express');

const { checkRelease } = require('../services/releaseService');

function createReleaseRoutes() {
  const router = express.Router();

  router.get('/v1/release/check', (req, res) => {
    try {
      const currentVersion = String(req.query.currentVersion || '0.0.0');
      const platform = String(req.query.platform || 'android');

      const data = checkRelease({ currentVersion, platform });
      res.status(200).json({
        traceId: req.traceId,
        data,
      });
    } catch (error) {
      res.status(500).json({
        traceId: req.traceId,
        errorCode: 'RELEASE_CHECK_FAILED',
        message: 'Failed to check latest release.',
      });
    }
  });

  return router;
}

module.exports = {
  createReleaseRoutes,
};