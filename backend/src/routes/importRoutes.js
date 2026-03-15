const express = require('express');
const { appendImportLog } = require('../services/importLogService');

function isValidImportLog(payload) {
  const requiredKeys = [
    'traceId',
    'schoolId',
    'errorCode',
    'message',
    'appVersion',
    'platform',
    'occurredAt',
  ];

  return requiredKeys.every((key) => typeof payload[key] === 'string' && payload[key].length > 0);
}

function createImportRoutes() {
  const router = express.Router();

  router.post('/v1/import/logs', (req, res) => {
    const payload = req.body || {};

    if (!isValidImportLog(payload)) {
      return res.status(400).json({
        traceId: req.traceId,
        errorCode: 'INVALID_PAYLOAD',
        message: 'Import log payload is invalid.',
      });
    }

    appendImportLog(payload);

    return res.status(202).json({
      accepted: true,
      traceId: req.traceId,
    });
  });

  return router;
}

module.exports = {
  createImportRoutes,
};
