#!/usr/bin/env node
/**
 * build-markdown.mjs
 * Exports MDX spec files to a single pure Markdown document by resolving
 * Astro component calls against the SQLite DB (src/crud.db).
 *
 * Usage:
 *   node scripts/build-markdown.mjs [sourceDir] [outputFile]
 *
 * Defaults:
 *   sourceDir  →  src/content/docs/base   (relative to project root)
 *   outputFile →  dist-markdown/base.md   (relative to project root)
 *
 * Examples:
 *   node scripts/build-markdown.mjs
 *   node scripts/build-markdown.mjs src/content/docs/http dist-markdown/http.md
 */

import { mkdirSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { DatabaseSync } from 'node:sqlite';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const rootDir   = join(__dirname, '..');

const [,, sourceDirArg, outputFileArg] = process.argv;
const sourceDir  = resolve(rootDir, sourceDirArg  ?? 'src/content/docs/base');
const outputFile = resolve(rootDir, outputFileArg ?? 'dist-markdown/base.md');

const dbPath = join(rootDir, 'src/crud.db');
const db = new DatabaseSync(dbPath);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** The inline format stored in the DB is already Markdown-compatible.
 *  Only \$ needs unescaping. */
function inlineToMd(text) {
  return text.replace(/\\\$/g, '$');
}

function escapePipes(cell) {
  return cell.replace(/\|/g, '\\|');
}

// ---------------------------------------------------------------------------
// DB queries
// ---------------------------------------------------------------------------

function getSectionDescription(code) {
  const row = db.prepare('SELECT description FROM crud_sections WHERE id = ?').get(code);
  return row?.description ? inlineToMd(row.description) : null;
}

function getRules(code) {
  return db.prepare(`
    SELECT r.code, r.requirement, r.rule
    FROM crud_api_rules r, json_each(r.section_codes) sc
    WHERE sc.value = ?
      AND r.code IS NOT NULL
    ORDER BY
      CASE r.requirement WHEN 'MUST' THEN 1 WHEN 'SHOULD' THEN 2 ELSE 3 END,
      r.code
  `).all(code);
}

function getVerbs() {
  return db.prepare(
    'SELECT verb, type, description FROM crud_verbs ORDER BY sort_order ASC'
  ).all();
}

function getOperations() {
  return db.prepare(`
    SELECT o.operation_name, v.verb, o.subject
    FROM crud_operations o
    JOIN crud_verbs v ON v.url = o.verb_id
    ORDER BY v.sort_order ASC, o.operation_name ASC
  `).all();
}

function getTerm(termId) {
  return db.prepare('SELECT label, definition FROM crud_terms WHERE id = ?').get(termId);
}

// ---------------------------------------------------------------------------
// Markdown renderers
// ---------------------------------------------------------------------------

function rulesTable(code) {
  const rules = getRules(code);
  if (!rules.length) return '';
  const rows = rules.map(r =>
    `| \`${r.code}\` | **${r.requirement}** | ${escapePipes(inlineToMd(r.rule))} |`
  );
  return [
    '| Code | Requirement | Rule |',
    '|------|-------------|------|',
    ...rows,
  ].join('\n');
}

function verbsTable() {
  const rows = getVerbs().map(v =>
    `| \`${v.verb}\` | ${v.type} | ${escapePipes(inlineToMd(v.description))} |`
  );
  return [
    '| Verb | Type | Description |',
    '|------|------|-------------|',
    ...rows,
  ].join('\n');
}

function operationsTable() {
  const rows = getOperations().map(o =>
    `| \`${o.operation_name}\` | \`${o.verb}\` | ${escapePipes(o.subject)} |`
  );
  return [
    '| Operation | Verb | Subject |',
    '|-----------|------|---------|',
    ...rows,
  ].join('\n');
}

function termDefinition(termId) {
  const term = getTerm(termId);
  if (!term) return '';
  return `**${inlineToMd(term.label)}**: ${inlineToMd(term.definition)}`;
}

// ---------------------------------------------------------------------------
// MDX → Markdown processor
// ---------------------------------------------------------------------------

/** Returns { title, sortKey, md } */
function processMdx(src) {
  let md = src;

  // 1. Extract frontmatter title + strip the block
  let title = '';
  md = md.replace(/^---\r?\n([\s\S]*?)\r?\n---\r?\n/, (_, fm) => {
    const m = fm.match(/^title:\s*(.+)$/m);
    if (m) title = m[1].trim();
    return '';
  });

  // 2. Strip import lines
  md = md.replace(/^import .+\r?\n/gm, '');

  // 3. Remove web-only sections (not meaningful in plain Markdown)
  md = md.replace(/^## Interactive version\b[\s\S]*?(?=\n## |\n# |$)/m, '');

  // 4. Strip decorative --- lines (layout separators in the web version)
  md = md.replace(/^---\r?\n/gm, '');

  // 5. Prepend H1 from frontmatter title
  if (title) md = `# ${title}\n\n${md}`;

  // 6. Resolve Astro components -------------------------------------------

  // <SectionDescription sectionCode="XXX" />
  md = md.replace(/<SectionDescription\s+sectionCode="([^"]+)"\s*\/>/g, (_, code) => {
    return getSectionDescription(code) ?? '';
  });

  // <RulesCardGrid [open] sectionCode="XXX" />  — attribute order-agnostic
  md = md.replace(/<RulesCardGrid[^/]*sectionCode="([^"]+)"[^/]*\/>/g, (_, code) => {
    return rulesTable(code);
  });

  // <CrudVerbsTable />
  md = md.replace(/<CrudVerbsTable\s*\/>/g, verbsTable);

  // <CrudOperationsTable />
  md = md.replace(/<CrudOperationsTable\s*\/>/g, operationsTable);

  // <TermDefinition termId="XXX" />
  md = md.replace(/<TermDefinition\s+termId="([^"]+)"\s*\/>/g, (_, id) => {
    return termDefinition(id);
  });

  // 7. Tidy up excess blank lines
  md = md.replace(/\n{3,}/g, '\n\n').trim() + '\n';

  // Sort key: leading integer from title (e.g. "3. General …" → 3), fallback to Infinity
  const sortKey = Number(title.match(/^(\d+)\./)?.[1] ?? Infinity);

  return { title, sortKey, md };
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

const files = readdirSync(sourceDir).filter(f => f.endsWith('.mdx'));

const sections = files
  .map(file => {
    const src = readFileSync(join(sourceDir, file), 'utf8');
    const result = processMdx(src);
    console.log(`  ✓  ${file}  (${result.title || 'no title'})`);
    return result;
  })
  .sort((a, b) => a.sortKey - b.sortKey)
  .map(s => s.md);

mkdirSync(dirname(outputFile), { recursive: true });
writeFileSync(outputFile, sections.join('\n\n---\n\n'));

db.close();

const rel = outputFile.startsWith(rootDir) ? outputFile.slice(`${rootDir}/`.length) : outputFile;
console.log(`\nWritten to ${rel}`);
