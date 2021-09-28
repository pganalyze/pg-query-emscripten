## pg-query-emscripten [![](https://img.shields.io/npm/v/pg-query-emscripten.svg)](https://www.npmjs.com/package/pg-query-emscripten)

Parse any valid PostgreSQL query in your browser using Javascript!

This builds a pure Javascript port of [libpg_query](https://github.com/lfittl/libpg_query) using emscripten, that allows you to parse SQL in the browser into the PostgreSQL parse tree.

Example use cases might include automatically checking for bad query patterns (e.g. LIMIT/OFFSET), understanding which tables a query references, or using structural pg_dump output to produce a schema diagram on the fly.

### Usage

```
npm install pg-query-emscripten --save
```

```javascript
import Module from "pg-query-emscripten";

let pgQuery;

(async () => {
  pgQuery = await new Module();

  console.log(pgQuery.parse("select 1"));
})();
```

### Author

- [Lukas Fittl](https://github.com/lfittl)
- [Philip Trauner](https://github.com/PhilipTrauner)

### LICENSE

Copyright (c) 2018 Lukas Fittl<br>
Licensed under the MIT License.
