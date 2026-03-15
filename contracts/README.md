# API Contracts

## Purpose
This directory stores frontend-backend contracts.

## Contract Policy
1. Contract-first development.
2. Backward-compatible changes should not break existing clients.
3. Breaking changes require a new API version folder.
4. Error code and traceId are required in failure responses.

## Structure
- openapi/: REST API specs
- schemas/: JSON schema files used by runtime validation
- changelog/: contract change records
