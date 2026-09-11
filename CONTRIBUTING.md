# Contributing

## Branch workflow

1. Pull the latest `main` and create a focused feature or fix branch.
2. Develop and test exploratory SQL in `queries/` or a shared Databricks workspace.
3. Move finalized reusable SQL into the matching numbered `src/` layer.
4. Add or update a persistent validation check in `tests/` for every production table.
5. Update the corresponding dbt model and schema test when the mart changes.
6. Run the local checks, commit, push the branch, and open a pull request.
7. Ask a teammate to review the grain, joins, checks, and documentation before merge.

```bash
python3 scripts/check_repository.py
sqlfluff lint src tests/*.sql queries dashboards --dialect databricks
dbt parse
```

## SQL conventions

- Use `snake_case` for schemas, tables, columns, and aliases.
- State the purpose and grain at the top of each production SQL file.
- Avoid `SELECT *` in production transformations.
- Qualify production tables with catalog and schema variables through `IDENTIFIER()`.
- Use `TRY_CAST` at ingestion boundaries and make rejected values visible in validation.
- Keep one stable grain per table and document it.
- Prefer explicit column lists so source changes cannot silently alter outputs.
- Join BI facts directly to conformed dimensions; do not create dimension-to-dimension snowball joins.
- Follow [`docs/naming-conventions.md`](docs/naming-conventions.md).

## Numbering

Execution order is encoded in filenames. Insert a new file in its logical layer and update its runner notebook. Do not reuse a number for two production steps.

## Pull request checklist

- [ ] The query has a documented purpose and grain.
- [ ] Inputs and outputs use the intended layer.
- [ ] A corresponding test covers keys, required fields, domains, and relationships.
- [ ] The check includes expectation, threshold, severity, and owner metadata.
- [ ] Local structure and SQL checks pass.
- [ ] Documentation reflects any model or threshold change.
