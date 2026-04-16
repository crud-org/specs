# specs

Monorepo for the project's specifications.

- **[crud/](crud/)** — CRUD API Base Specification. Astro Starlight site. Prose in `.mdx`, **normative content in [crud/src/crud.db](crud/src/crud.db) (SQLite)**.
- **[unquery/](unquery/)** — UnQuery filter spec. Single [unquery/spec.md](unquery/spec.md), no build.

Both are **protocol-/storage-agnostic** standards. Follow [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119) keywords + SemVer. License: [MPL 2.0](http://mozilla.org/MPL/2.0/).

---

## `crud/` — content lives in two places

### 1. Prose → MDX under [crud/src/content/docs/base/](crud/src/content/docs/base/)

Standard Starlight (sidebar `autogenerate: { directory: 'base' }` in [crud/astro.config.mjs](crud/astro.config.mjs); `title` + `description` frontmatter required). Section headings carry a numeric prefix:

```mdx
## 3.1.1 Resource Types and Collections

<RulesCardGrid sectionCode="G311" />
```

Defined terms appear in **bold + double quotes** on first use: `A "**Resource**" is...`.

### 2. Normative rules + verbs/operations → SQLite at [crud/src/crud.db](crud/src/crud.db)

**Do not duplicate DB content in MDX prose.** Three [crud/src/components/](crud/src/components/) Astro components query it server-side at build/render time and render the canonical view. Read the component sources for exact queries / props.

Tables (use `sqlite3 crud/src/crud.db ".schema"` for full schema):

| Table | Purpose |
|---|---|
| `crud_sections` | Canonical section index. `id` = section code, `name` = title. |
| `crud_api_rules` | Normative rules. Multi-spec via `spec` UUID column. |
| `crud_verbs` | The 6 CRUD verbs (`get`, `list`, `create`, `patch`, `replace`, `delete`). |
| `crud_operations` | Verb × subject combinations (e.g. `patchById`, `deleteByQuery`). |

#### Section code convention

`G` + dotted section number with dots removed: `3.1.1` → `G311`, `3.4.3` → `G343`. Both parent (`G31`) and leaf (`G311`) codes coexist. A rule's `section_codes` is a JSON array — query with `json_each`. Some rules reference codes (e.g. `G4xx`) not yet in `crud_sections` — those are upcoming sections, not orphans.

#### Rule code convention

`crud_api_rules.code` is a **semantic SCREAMING_SNAKE_CASE identifier** with a topical prefix that mirrors the rule's domain — not an arbitrary ID. Existing prefixes: `DOC_`, `ID_`, `COLLECTION_`, `PROPS_`, `META_`, `PARAM_`, `SEARCH_QUERY_`, `SORTING_`. Match the prefix when adding new rules in the same domain.

#### Adding a rule

Insert with `code`, `requirement` (`MUST`/`SHOULD`/`MAY`), `rule` (markdown — only `[link](url)`, `` `code` ``, `**bold**`, and `\$` are rendered; see [RulesCardGrid.astro](crud/src/components/RulesCardGrid.astro)), `section_codes` (JSON array), and `spec` (UUID of the target spec — pick from existing rows, do not invent).

---

## Gotchas

- **`bun build` runs `starlight-links-validator`** — broken internal links fail the build. Run it before committing structural changes.
- **`node:sqlite` requires Node ≥ 22** and is wired via `vite.ssr.external` in [crud/astro.config.mjs](crud/astro.config.mjs). Don't remove that entry.
- **Mermaid theme is fixed** to `forest` with `autoTheme: true` — diagrams in MDX use standard ` ```mermaid ` fences.
