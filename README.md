# Easy random sampling in PostgreSQL

Source code to accompany my November&nbsp;24,&nbsp;2026 article,
"A random sampling index in PostgreSQL - Avoid a DevOps rat race"
(
[LinkedIn](https://www.linkedin.com/pulse/random-sampling-postgresql-avoid-devops-rat-race-paul-marcelin-vrirc) |
[blog](https://sqlxpert.github.io/2026/11/24/postgresql-random-sampling-index-avoid-devops-rat-race.html)
),
about defining a systematic stratified sample index in PostgreSQL, to get accurate and precise results for large data sets without bigger hardware or more hardware

## SQL formatting

<details>
  <summary>SQL formatting conventions</summary>

### Current or potential comma-separated lists

- Context examples: `select`&nbsp;: `from`&nbsp;, `group by`&nbsp;, `order by`
- 1&nbsp;item per line; indent 1&nbsp;extra space for comma
- Conspicuous **leading comma** prevents syntax errors when items are added
- Put the comma on a line by itself if entries are likely to be added or
  removed at the beginning, commented out individually, or copied and pasted

### Boolean expressions

- Context examples: `select`&nbsp;: `where`&nbsp;, `having`
- No extra indentation unless and until logical operators (`not`, `or`, `and`)
  are added
- Then, use line breaks, indentation, and parentheses so that the expression
  can be read naturally and parallel arms of the expression can easily be
  recognized

### Operators and keywords

- Align or space out pairs based on the _longer_ possibility

  ```sql
    =  >    asc   true
   !=  >=  desc  false
  ```

### Table and column references

- Always define a range variable (a table alias, in familiar language) when
  using a `values` list or a call to a function (like `generate_series` in
  PostgreSQL) in place of a table name
- Always define a column alias if the column would otherwise have no known
  name, or an ambiguous name
- For clarity, follow these rules even if the column is not _currently_
  referenced elsewhere, or if it is referenced based solely on its order (as in
  the case of `insert`&nbsp;)
- Generally, avoid `*` for a column list
- It is OK to use `select *` with quantifiers like `exists()` or in a common
  table expression where the column list has been specified immediately above,
  for example, in a `union`

</details>

## Licenses

|Scope|Link|Included Copy|
|:---|:---|:---|
|Source code, and source code in documentation|[GNU General Public License (GPL) 3.0](http://www.gnu.org/licenses/gpl-3.0.html)|[LICENSE-CODE.md](/LICENSE-CODE.md)|
|Documentation, including this ReadMe file|[GNU Free Documentation License (FDL) 1.3](http://www.gnu.org/licenses/fdl-1.3.html)|[LICENSE-DOC.md](/LICENSE-DOC.md)|

Copyright Paul Marcelin

Contact: `marcelin` at `cmu.edu` (replace "at" with `@`)
