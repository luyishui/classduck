# Backend Workspace

## Purpose
This directory hosts backend services used by ClassDuck.

## Scope
- School configuration service
- Import log ingestion service
- Version and rollout strategy service

## Rules
1. Keep frontend and backend logic separated.
2. All external API contracts must be defined in ../contracts.
3. Any API change must update contracts and version notes first.

## Initial Service Modules
- config-service: serves school list and parser metadata
- import-log-service: receives import failure diagnostics
- release-service: serves feature flags and update metadata

## Next Step
Create independent service projects under this directory with clear ownership and API versioning.
