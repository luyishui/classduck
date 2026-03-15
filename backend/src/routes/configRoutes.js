const express = require('express');

const { getSchoolConfigList } = require('../services/configService');

function createConfigRoutes() {
  const router = express.Router();

  router.get('/v1/config/schools', (req, res) => {
    try {
      const data = getSchoolConfigList();
      res.status(200).json(data);
    } catch (error) {
      res.status(500).json({
        traceId: req.traceId,
        errorCode: 'CONFIG_READ_FAILED',
        message: 'Failed to read school config list.',
      });
    }
  });

  return router;
}

module.exports = {
  createConfigRoutes,
};
