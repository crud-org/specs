# Universal Query String Filter Specification (UnQuery)

## 1. Introduction

This document defines a standardized format for representing search filters in query strings using a structured JSON-based syntax. The goal is to provide a universal approach to converting filters into formats compatible with SQL and NoSQL databases.

## 2. Query String Format

Each key in the query string represents a field to be filtered. Keys must be alphanumeric and may include hyphens (`-`) and underscores (`_`). Dot notation or bracket notation is not supported.

Each key’s value can take one of the following forms:

1.  **SQL Expression**: A string containing SQL filtering operators, such as `BETWEEN 1 AND 100` or `IN ('A', 'B')`. SQL expressions must be recognizable by standard SQL operators.
    
2.  **JSON Query Format**: A structured JSON-based query format for filtering data. This format is inspired by MongoDB's query syntax but is designed to be compatible with any database system that supports JSON-based filtering, including NoSQL databases (e.g., MongoDB, CouchDB) and relational databases with JSON capabilities (e.g., PostgreSQL, MySQL).
    
3.  **String Literal**: A simple string value interpreted as an exact equality comparison (`field = 'value'`).
    

## 3. Special Parameter: `q`

If the `q` parameter is present, it takes precedence over all other filters and can contain:

-   A complete SQL expression (only the `WHERE` clause content).
    
-   A complete JSON-based query expressed in a structured format.
    

## 4. JSON-Based Query Conversion

**Supported Operators**: The JSON-based query format follows a structure inspired by MongoDB. The following operators are supported:

-   **Comparison Operators**: `$eq`, `$ne`, `$gt`, `$gte`, `$lt`, `$lte`
    
-   **Logical Operators**: `$and`, `$or`, `$not`, `$nor`
    
-   **Existence Operators**: `$exists`, `$type`
    
-   **Array Operators**: `$in`, `$nin`, `$all`, `$size`
    
-   **Evaluation Operators**: `$regex`, `$expr`
    
-   **Element Operators**: `$mod`
    
-   **Geospatial Operators**: `$geoWithin`, `$geoIntersects`, `$near`, `$nearSphere`
    

**Note**: Queries involving nested properties (e.g., `user.address.city`) must always use this JSON query format, as SQL expressions do not support deeply nested fields.

This query format is designed to be compatible with JSON-supported databases, including NoSQL databases like MongoDB and SQL databases with JSON capabilities, such as PostgreSQL and MySQL. The structure follows a common key-value filtering approach, allowing easy adaptation across different database technologies.

## 5. SQL Conversion

The conversion of query string parameters to SQL follows these rules:

-   SQL expressions are used as-is.
    
-   JSON objects are converted into equivalent SQL expressions.
    
-   String literals are converted into exact match expressions (`field = 'value'`).
    
-   All expressions are enclosed in parentheses and joined using `AND`.
    

### 5.1 Supported SQL Operators

-   **Comparison Operators**: `=`, `!=`, `<>`, `>`, `<`, `>=`, `<=`
    
-   **Logical Operators**: `AND`, `OR`, `NOT`
    
-   **Pattern Matching**: `LIKE`, `ILIKE`
    
-   **Set Membership**: `IN`, `ALL`, `ANY`, `SOME`
    
-   **Range Conditions**: `BETWEEN`
    
-   **NULL Handling**: `IS NULL`, `IS NOT NULL`, `IS TRUE`, `IS FALSE`
    
-   **Existence Checking**: `EXISTS`
    

## 6. Error Handling and Validation

-   **Invalid Keys**: Keys must only contain alphanumeric characters, hyphens, or underscores. Any other characters result in an error.
    
-   **Malformed JSON**: If a JSON object is incorrectly formatted, it is treated as a string literal.
    
-   **SQL Injection Protection**: When converting to SQL, all input values are sanitized to prevent SQL injection attacks.
    
-   **Nested Fields**: SQL expressions cannot represent nested properties. If a query requires filtering inside nested objects, the JSON-based query format must be used.
    
-   **Database Compatibility**: While this format follows MongoDB's query structure, it is applicable to any database that supports JSON querying, including relational databases with JSON column support.
    

## 7. Implementation Considerations

-   The parsing logic should first check for the presence of the `q` parameter before processing other keys.
    
-   If an entry is determined to be a valid SQL expression, it should be used as-is without modification.
    
-   When translating JSON-based queries into SQL, a conversion function should be employed to map JSON operators to SQL equivalents.
    
-   SQL expressions should be enclosed in parentheses to ensure correct precedence when joining multiple conditions.
    

## 8. Security Considerations

-   **SQL Injection Risks**: Special attention should be given to sanitizing and validating input before executing queries.
    
-   **JSON Query Validation**: Ensure that JSON objects do not contain unexpected fields that could lead to unwanted query behaviors.

## 9. References

1. [RFC 3986: Uniform Resource Identifier (URI): Generic Syntax](https://datatracker.ietf.org/doc/html/rfc3986)
2. [RFC 8259: The JavaScript Object Notation (JSON) Data Interchange Format](https://datatracker.ietf.org/doc/html/rfc8259)
3. [MongoDB Query Operators](https://www.mongodb.com/docs/manual/reference/operator/query/)
4. [ISO/IEC 9075: SQL Standard](https://www.iso.org/standard/63555.html)
