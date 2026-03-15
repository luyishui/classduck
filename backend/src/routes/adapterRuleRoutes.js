const express = require('express');

const { getAdapterRules } = require('../services/adapterRuleService');

function createAdapterRuleRoutes() {
  const router = express.Router();

  router.get('/v1/config/adapters', (req, res) => {
    try {
      const data = getAdapterRules();
      res.status(200).json(data);
    } catch (error) {
      res.status(500).json({
        traceId: req.traceId,
        errorCode: 'ADAPTER_RULE_READ_FAILED',
        message: 'Failed to read adapter rules.',
      });
    }
  });

  return router;
}

module.exports = {
  createAdapterRuleRoutes,
};