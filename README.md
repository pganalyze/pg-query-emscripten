## pg-query-emscripten [ ![](https://img.shields.io/npm/v/pg-query-emscripten.svg)](https://www.npmjs.com/package/pg-query-emscripten)

Parse any valid PostgreSQL query in your browser using Javascript!

This builds a pure Javascript port of [libpg_query](https://github.com/lfittl/libpg_query) using emscripten, that allows you to parse SQL in the browser into the PostgreSQL parse tree.

Example use cases might include automatically checking for bad query patterns (e.g. LIMIT/OFFSET), understanding which tables a query references, or using structural pg_dump output to produce a schema diagram on the fly.

### Usage (Plain JS)

```html
<script src="https://unpkg.com/pg-query-emscripten"></script>
<script>
  console.log(PgQuery.parse("SELECT 1"));
</script>
```

### Usage (npm)

```
npm install pg-query-emscripten --save
```

Then import using your favorite tool, e.g.

```javascript
import PgQuery from 'pg-query-emscripten';

console.log(PgQuery.parse("SELECT 1"));
```

### Author

* [Lukas Fittl](https://github.com/lfittl)

### LICENSE

Copyright (c) 2018 Lukas Fittl<br>
Licensed under the MIT License.
