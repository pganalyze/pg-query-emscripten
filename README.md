## pg-query-emscripten [![](https://img.shields.io/npm/v/pg-query-emscripten.svg)](https://www.npmjs.com/package/@cybertec/pg-query-emscripten)

### Usage

```
yarn add @cybertec/pg-query-emscripten
```

```javascript
import Module from "@cybertec/pg-query-emscripten";

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
