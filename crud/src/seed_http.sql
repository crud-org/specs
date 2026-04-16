-- ============================================================
-- HTTP Protocol Spec: Tables + Seed Data
-- ============================================================

-- Endpoint → CRUD operation mapping
CREATE TABLE IF NOT EXISTS http_endpoints (
    signature TEXT PRIMARY KEY,
    http_method TEXT NOT NULL,
    url_pattern TEXT NOT NULL,
    crud_operation TEXT NOT NULL,
    base_section_code TEXT NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 0
);

-- Structured HTTP rules (constraint-based)
-- is_global: 0 = specific to endpoint, 1 = global (shown in "Inherited rules" tab)
CREATE TABLE IF NOT EXISTS http_rules (
    code TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    entity TEXT NOT NULL CHECK(entity IN ('Method', 'Status', 'URL path', 'URL path component', 'URL query parameter', 'Header', 'Body')),
    request_response TEXT NOT NULL CHECK(request_response IN ('Request', 'Response')),
    requirement TEXT NOT NULL CHECK(requirement IN ('MUST', 'SHOULD', 'MAY')),
    verb TEXT NOT NULL DEFAULT 'be_=',
    key TEXT,
    value TEXT,
    value_shortcode TEXT,
    condition TEXT,
    signatures TEXT NOT NULL DEFAULT '[]',
    base_rule_codes TEXT NOT NULL DEFAULT '[]',
    is_global INTEGER NOT NULL DEFAULT 0,
    display_order INTEGER NOT NULL DEFAULT 99999
);

-- ============================================================
-- Endpoints
-- ============================================================

INSERT OR IGNORE INTO http_endpoints (signature, http_method, url_pattern, crud_operation, base_section_code, sort_order) VALUES
  ('GET /:collection/:id',    'GET',    '/:collection/:id', 'get',            'G41',  1),
  ('GET /:collection',        'GET',    '/:collection',     'list',           'G421', 2),
  ('POST /:collection',       'POST',   '/:collection',     'create',         'G43',  3),
  ('PATCH /:collection/:id',  'PATCH',  '/:collection/:id', 'patchById',      'G441', 4),
  ('PATCH /:collection',      'PATCH',  '/:collection',     'patchByQuery',   'G442', 5),
  ('PUT /:collection/:id',    'PUT',    '/:collection/:id', 'replaceById',    'G451', 6),
  ('PUT /:collection',        'PUT',    '/:collection',     'replaceByQuery', 'G452', 7),
  ('DELETE /:collection/:id', 'DELETE', '/:collection/:id', 'deleteById',     'G461', 8),
  ('DELETE /:collection',     'DELETE', '/:collection',     'deleteByQuery',  'G462', 9);

-- ============================================================
-- Clear existing rules
-- ============================================================

DELETE FROM http_rules;

-- ============================================================
-- Global Rules (is_global = 1, all 9 signatures)
-- ============================================================

INSERT INTO http_rules (code, name, entity, request_response, requirement, verb, key, value, value_shortcode, condition, signatures, base_rule_codes, is_global, display_order) VALUES

-- Global Request rules
('HTTP_PATH_COLLECTION', '/:collection', 'URL path component', 'Request', 'MUST', 'be_=',
 'collection', 'a Collection [Slug](/base/terminology/#slug)', ':collection', NULL,
 '["GET /:collection/:id","GET /:collection","POST /:collection","PATCH /:collection/:id","PATCH /:collection","PUT /:collection/:id","PUT /:collection","DELETE /:collection/:id","DELETE /:collection"]',
 '["COLLECTION_SLUG"]', 1, 10),

('HTTP_HEADER_ACCEPT_REQ', 'Accept', 'Header', 'Request', 'MUST', 'be_=',
 'Accept', 'a valid media type indicating the accepted content format', 'media type', NULL,
 '["GET /:collection/:id","GET /:collection","POST /:collection","PATCH /:collection/:id","PATCH /:collection","PUT /:collection/:id","PUT /:collection","DELETE /:collection/:id","DELETE /:collection"]',
 '["META_RES_PREFERENCE"]', 1, 30),

('HTTP_HEADER_CRUD_VERSION_REQ', 'X-CRUD-Version', 'Header', 'Request', 'MUST', 'be_=',
 'X-CRUD-Version', 'the CRUD API Spec version', 'version', NULL,
 '["GET /:collection/:id","GET /:collection","POST /:collection","PATCH /:collection/:id","PATCH /:collection","PUT /:collection/:id","PUT /:collection","DELETE /:collection/:id","DELETE /:collection"]',
 '["META_CRUD_VERSION"]', 1, 31),

('HTTP_HEADER_CORRELATION_ID_REQ', 'X-Correlation-ID', 'Header', 'Request', 'SHOULD', 'be_=',
 'X-Correlation-ID', 'a fresh [`uuid-hex`](/base/terminology/#uuid-hex)', 'UUID', NULL,
 '["GET /:collection/:id","GET /:collection","POST /:collection","PATCH /:collection/:id","PATCH /:collection","PUT /:collection/:id","PUT /:collection","DELETE /:collection/:id","DELETE /:collection"]',
 '["META_CORRELATION_ID"]', 1, 32),

('HTTP_HEADER_PREFER_HANDLING', 'Prefer: handling=...', 'Header', 'Request', 'MAY', 'be_=',
 'Prefer', '`handling=lenient` or `handling=strict` for validation level negotiation', 'handling', NULL,
 '["GET /:collection/:id","GET /:collection","POST /:collection","PATCH /:collection/:id","PATCH /:collection","PUT /:collection/:id","PUT /:collection","DELETE /:collection/:id","DELETE /:collection"]',
 '["META_WARN_PREFERENCE"]', 1, 33),

-- Global Response rules
('HTTP_HEADER_CONTENT_TYPE_RES', 'Content-Type', 'Header', 'Response', 'MUST', 'be_=',
 'Content-Type', 'matching the `Accept` request media type', 'media type', NULL,
 '["GET /:collection/:id","GET /:collection","POST /:collection","PATCH /:collection/:id","PATCH /:collection","PUT /:collection/:id","PUT /:collection","DELETE /:collection/:id","DELETE /:collection"]',
 '["META_RES_PREFERENCE"]', 1, 60),

('HTTP_HEADER_CRUD_VERSION_RES', 'X-CRUD-Version', 'Header', 'Response', 'MUST', 'be_=',
 'X-CRUD-Version', 'the CRUD API Spec version', 'version', NULL,
 '["GET /:collection/:id","GET /:collection","POST /:collection","PATCH /:collection/:id","PATCH /:collection","PUT /:collection/:id","PUT /:collection","DELETE /:collection/:id","DELETE /:collection"]',
 '["META_CRUD_VERSION"]', 1, 61),

('HTTP_HEADER_CORRELATION_ID_RES', 'X-Correlation-ID', 'Header', 'Response', 'MUST', 'be_=',
 'X-Correlation-ID', 'the request''s Correlation ID or a new [`uuid-hex`](/base/terminology/#uuid-hex)', 'UUID',
 'If the Client sent a Correlation ID, the Server MUST echo it. Otherwise, the Server MUST generate a new one.',
 '["GET /:collection/:id","GET /:collection","POST /:collection","PATCH /:collection/:id","PATCH /:collection","PUT /:collection/:id","PUT /:collection","DELETE /:collection/:id","DELETE /:collection"]',
 '["META_CORRELATION_ID"]', 1, 62),

('HTTP_RES_ERROR', '{ error }', 'Body', 'Response', 'MUST', 'be_=',
 NULL, 'an error payload with at least an error code and a human-readable message, as specified in [Section 3.4.3](/base/general/#343-error-handling)', 'error',
 'When the response status code is greater than 399.',
 '["GET /:collection/:id","GET /:collection","POST /:collection","PATCH /:collection/:id","PATCH /:collection","PUT /:collection/:id","PUT /:collection","DELETE /:collection/:id","DELETE /:collection"]',
 '["RES_ERROR_DATA"]', 1, 80);

-- ============================================================
-- Specific Rules (is_global = 0)
-- ============================================================

INSERT INTO http_rules (code, name, entity, request_response, requirement, verb, key, value, value_shortcode, condition, signatures, base_rule_codes, is_global, display_order) VALUES

-- Methods (display_order = 1)
('HTTP_METHOD_GET', 'GET', 'Method', 'Request', 'MUST', 'be_=',
 NULL, 'GET', 'GET', NULL,
 '["GET /:collection/:id","GET /:collection"]',
 '[]', 0, 1),

('HTTP_METHOD_POST', 'POST', 'Method', 'Request', 'MUST', 'be_=',
 NULL, 'POST', 'POST', NULL,
 '["POST /:collection"]',
 '[]', 0, 1),

('HTTP_METHOD_PATCH', 'PATCH', 'Method', 'Request', 'MUST', 'be_=',
 NULL, 'PATCH', 'PATCH', NULL,
 '["PATCH /:collection/:id","PATCH /:collection"]',
 '[]', 0, 1),

('HTTP_METHOD_PUT', 'PUT', 'Method', 'Request', 'MUST', 'be_=',
 NULL, 'PUT', 'PUT', NULL,
 '["PUT /:collection/:id","PUT /:collection"]',
 '[]', 0, 1),

('HTTP_METHOD_DELETE', 'DELETE', 'Method', 'Request', 'MUST', 'be_=',
 NULL, 'DELETE', 'DELETE', NULL,
 '["DELETE /:collection/:id","DELETE /:collection"]',
 '[]', 0, 1),

-- URL Path (display_order = 10-11)
('HTTP_PATH_ID', '/:id = ID', 'URL path component', 'Request', 'MUST', 'be_=',
 'id', 'a [Resource ID](/base/general/#313-resource-ids)', ':id', NULL,
 '["GET /:collection/:id","PATCH /:collection/:id","PUT /:collection/:id","DELETE /:collection/:id"]',
 '["SUB_ID","SUB_ID_REPLACE"]', 0, 11),

-- Query Parameters (display_order = 20-26)
('HTTP_QP_FIELDS', '?fields = Projection', 'URL query parameter', 'Request', 'MAY', 'be_=',
 'fields', 'a [Projection Parameter](/base/general/#331-projection-parameter)', 'Projection', NULL,
 '["GET /:collection/:id","GET /:collection","POST /:collection","PATCH /:collection/:id","PATCH /:collection","PUT /:collection/:id","PUT /:collection"]',
 '["PARAM_PROJECTION","PARAM_PROJECTION_WRITE"]', 0, 20),

('HTTP_QP_QUERY', '?q = Search Query', 'URL query parameter', 'Request', 'MAY', 'be_=',
 'q', 'a [Search Query](/base/general/#321-definition-and-representation)', 'Search Query',
 'Client MAY omit to list all Documents.',
 '["GET /:collection"]',
 '["SUB_SEARCH_QUERY","SUB_EMPTY"]', 0, 21),

('HTTP_QP_QUERY_WRITE', '?q = Search Query', 'URL query parameter', 'Request', 'MUST', 'be_=',
 'q', 'a [Search Query](/base/general/#321-definition-and-representation)', 'Search Query', NULL,
 '["PATCH /:collection","PUT /:collection","DELETE /:collection"]',
 '["SUB_SEARCH_QUERY_WRITE"]', 0, 21),

('HTTP_QP_SORT', '?sort = Sorting', 'URL query parameter', 'Request', 'MAY', 'be_=',
 'sort', 'a [Sorting Parameter](/base/operation/#423-sorting-parameter)', 'Sorting', NULL,
 '["GET /:collection"]',
 '["PARAM_SORTING"]', 0, 22),

('HTTP_QP_PAGE', '?page, ?limit', 'URL query parameter', 'Request', 'MAY', 'be_=',
 'page, limit', 'Pagination Parameters', 'Pagination', NULL,
 '["GET /:collection"]',
 '["PARAM_PAGINATION"]', 0, 23),

('HTTP_QP_EXPECT_MATCH', '?expectMatch', 'URL query parameter', 'Request', 'MAY', 'be_=',
 'expectMatch', 'the expected number of Documents to match', 'count',
 'If the matched count differs, the Server MUST fail the operation.',
 '["PATCH /:collection/:id","PUT /:collection","DELETE /:collection"]',
 '["PARAM_EXPECT_MATCH"]', 0, 25),

('HTTP_QP_DENY_UPSERT', '?denyUpsert', 'URL query parameter', 'Request', 'MAY', 'be_=',
 'denyUpsert', '`true` to prevent Document creation if not found', 'true', NULL,
 '["PUT /:collection/:id"]',
 '["PARAM_DENY_UPSERT"]', 0, 26),

-- Request Headers (display_order = 30-35)
('HTTP_HEADER_CONTENT_TYPE_JSON', 'Content-Type: application/json', 'Header', 'Request', 'MUST', 'be_=',
 'Content-Type', '`application/json`', 'application/json', NULL,
 '["POST /:collection","PUT /:collection/:id","PUT /:collection"]',
 '["DOC_JSON"]', 0, 30),

('HTTP_HEADER_CONTENT_TYPE_PATCH', 'Content-Type: application/json-patch+json', 'Header', 'Request', 'MUST', 'be_=',
 'Content-Type', '`application/json-patch+json`', 'json-patch+json', NULL,
 '["PATCH /:collection/:id","PATCH /:collection"]',
 '[]', 0, 30),

('HTTP_HEADER_PREFER_RETURN', 'Prefer: return=...', 'Header', 'Request', 'MAY', 'be_=',
 'Prefer', '`return=representation` (default) or `return=minimal`', 'return', NULL,
 '["POST /:collection","PATCH /:collection/:id","PATCH /:collection","PUT /:collection/:id","PUT /:collection"]',
 '["META_PREFER_REPRESENTATION","META_PREFER_STATUS"]', 0, 34),

-- Request Body (display_order = 40)
('HTTP_BODY_CREATE', '{ Document / Document[] }', 'Body', 'Request', 'MUST', 'be_=',
 NULL, 'a single Document or a list of multiple Documents', 'Document(s)', NULL,
 '["POST /:collection"]',
 '["SUB_DOCUMENTS_CREATE","SUB_WITH_IDS"]', 0, 40),

('HTTP_BODY_PATCH', '[ JSON Patch ]', 'Body', 'Request', 'MUST', 'be_=',
 NULL, 'a [JSON Patch](https://jsonpatch.com/) operations list', 'JSON Patch', NULL,
 '["PATCH /:collection/:id","PATCH /:collection"]',
 '["SUB_JSON_PATCH"]', 0, 40),

('HTTP_BODY_REPLACE', '{ Document }', 'Body', 'Request', 'MUST', 'be_=',
 NULL, 'a complete replacement Document', 'Document',
 'The replacement Document SHOULD NOT include a Resource ID.',
 '["PUT /:collection/:id","PUT /:collection"]',
 '["SUB_DOCUMENT_REPLACE","SUB_NO_ID"]', 0, 40),

-- Response Status Codes (display_order = 50-59)
('HTTP_STATUS_200', '200 OK', 'Status', 'Response', 'MUST', 'be_=',
 NULL, '200', '200', NULL,
 '["GET /:collection/:id","GET /:collection","PATCH /:collection/:id","PATCH /:collection","PUT /:collection/:id","PUT /:collection"]',
 '[]', 0, 50),

('HTTP_STATUS_201', '201 Created', 'Status', 'Response', 'MUST', 'be_=',
 NULL, '201', '201', NULL,
 '["POST /:collection"]',
 '[]', 0, 50),

('HTTP_STATUS_201_UPSERT', '201 Created', 'Status', 'Response', 'MUST', 'be_=',
 NULL, '201', '201',
 'If the Resource ID is not found and the Server creates a new Document (upsert).',
 '["PUT /:collection/:id"]',
 '["META_UPSERTED"]', 0, 51),

('HTTP_STATUS_204', '204 No Content', 'Status', 'Response', 'MUST', 'be_=',
 NULL, '204', '204', NULL,
 '["DELETE /:collection/:id","DELETE /:collection"]',
 '["RES_EMPTY"]', 0, 50),

('HTTP_STATUS_204_MINIMAL', '204 No Content', 'Status', 'Response', 'MUST', 'be_=',
 NULL, '204', '204',
 'When the Client sends `Prefer: return=minimal`.',
 '["POST /:collection","PATCH /:collection/:id","PATCH /:collection","PUT /:collection/:id","PUT /:collection"]',
 '["META_PREFER_STATUS"]', 0, 51),

('HTTP_STATUS_404', '404 Not Found', 'Status', 'Response', 'MUST', 'be_=',
 NULL, '404', '404',
 'If the Server cannot find any Document matching the Input Subject.',
 '["GET /:collection/:id","PATCH /:collection/:id","DELETE /:collection/:id"]',
 '["RES_MATCHING_REQUIRED"]', 0, 52),

('HTTP_STATUS_409', '409 Conflict', 'Status', 'Response', 'MUST', 'be_=',
 NULL, '409', '409',
 'If the Client sends Documents with Resource IDs that conflict with existing ones.',
 '["POST /:collection"]',
 '["RES_CONFLICT"]', 0, 53),

('HTTP_STATUS_400', '400 Bad Request', 'Status', 'Response', 'MUST', 'be_=',
 NULL, '400', '400',
 'If the Server cannot create Documents with Resource IDs sent by the Client.',
 '["POST /:collection"]',
 '["RES_NO_IDS"]', 0, 54),

('HTTP_STATUS_412_MATCH', '412 Precondition Failed', 'Status', 'Response', 'MUST', 'be_=',
 NULL, '412', '412',
 'If the matched count differs from the `expectMatch` parameter.',
 '["PATCH /:collection/:id","PUT /:collection","DELETE /:collection"]',
 '["PARAM_EXPECT_MATCH"]', 0, 55),

('HTTP_STATUS_412_UPSERT', '412 Precondition Failed', 'Status', 'Response', 'MUST', 'be_=',
 NULL, '412', '412',
 'If the Document is not found and the Client explicitly denied upsert via `?denyUpsert=true`.',
 '["PUT /:collection/:id"]',
 '["RES_UPSERT_PREVENTED"]', 0, 56),

-- Response Headers (display_order = 60-65)
('HTTP_RES_MATCHED_COUNT', 'X-Matched-Count', 'Header', 'Response', 'SHOULD', 'be_=',
 'X-Matched-Count', 'the total number of Documents matched by the query', 'count', NULL,
 '["GET /:collection","PATCH /:collection","PUT /:collection","DELETE /:collection"]',
 '["META_MATCHED_COUNT"]', 0, 63),

('HTTP_RES_MODIFIED_COUNT', 'X-Modified-Count', 'Header', 'Response', 'SHOULD', 'be_=',
 'X-Modified-Count', 'the total number of Documents modified by the operation', 'count', NULL,
 '["POST /:collection","PATCH /:collection/:id","PATCH /:collection","PUT /:collection/:id","PUT /:collection","DELETE /:collection/:id","DELETE /:collection"]',
 '["META_MODIFIED_COUNT"]', 0, 64),

('HTTP_RES_CONTENT_LOCATION', 'Content-Location', 'Header', 'Response', 'MUST', 'be_=',
 'Content-Location', 'the `GET /:collection/:id` endpoint URL of the written Document', 'GET URL',
 'When the write operation targets a single Document and the Client prefers `return=representation`.',
 '["POST /:collection","PATCH /:collection/:id","PUT /:collection/:id"]',
 '[]', 0, 65),

('HTTP_RES_LOCATION', 'Location', 'Header', 'Response', 'MUST', 'be_=',
 'Location', 'the `GET /:collection/:id` endpoint URL of the written Document', 'GET URL',
 'When the write operation targets a single Document and the Client sends `Prefer: return=minimal`.',
 '["POST /:collection","PATCH /:collection/:id","PUT /:collection/:id"]',
 '[]', 0, 66),

-- Response Body (display_order = 70-75)
('HTTP_RES_DOCUMENT', '{ Document }', 'Body', 'Response', 'MUST', 'be_=',
 NULL, 'a single Document', 'Document', NULL,
 '["GET /:collection/:id"]',
 '["RES_DOCUMENTS_FOUND"]', 0, 70),

('HTTP_RES_DOCUMENTS', '[ Documents ]', 'Body', 'Response', 'MUST', 'be_=',
 NULL, 'a list of Documents', 'Documents', NULL,
 '["GET /:collection"]',
 '["RES_DOCUMENTS_FOUND"]', 0, 70),

('HTTP_RES_WRITTEN', '{ Document(s) }', 'Body', 'Response', 'MUST', 'be_=',
 NULL, 'the Document(s) written by the operation, including Resource IDs', 'Document(s)',
 'When the Client prefers `return=representation` (default behavior).',
 '["POST /:collection","PATCH /:collection/:id","PATCH /:collection","PUT /:collection/:id","PUT /:collection"]',
 '["RES_DOCUMENTS_WRITTEN","RES_WITH_IDS","META_RES_DEFAULT"]', 0, 70),

('HTTP_RES_EMPTY', '∅', 'Body', 'Response', 'MUST', 'be_=',
 NULL, 'empty (no body)', '∅', NULL,
 '["DELETE /:collection/:id","DELETE /:collection"]',
 '["RES_EMPTY"]', 0, 70);
