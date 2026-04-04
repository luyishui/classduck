# ClassDuck Adapters (Source of Truth)

This folder is the canonical source for school adapter definitions.

## Boundary
- Source folder: `backend/python_import_service/adapters/`
- Runtime artifact folders (generated):
  - `backend/python_import_service/data/school_configs/`
  - `backend/python_import_service/data/scripts/`

Do not manually edit runtime artifacts. Use adapter scripts to publish generated files.

## Layout
- `core/`: parser base classes and helper utilities
- `undergraduate/`: undergraduate schools
- `master/`: graduate schools
- `general/`: generic portals/systems
- `schemas/`: JSON schema definitions
- `index/`: adapter indexes and source mapping
- `scripts/`: adapter maintenance scripts
- `tests/`: fixtures and expected outputs
