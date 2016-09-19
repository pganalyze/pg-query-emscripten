## pg_query_emscripten

Parse any valid PostgreSQL query in your browser using Javascript!

This builds a pure Javascript port of [libpg_query](https://github.com/lfittl/libpg_query) using emscripten, that allows you to parse SQL in the browser into the PostgreSQL parse tree.

Example use cases might include automatically checking for bad query patterns (e.g. LIMIT/OFFSET), understanding which tables a query references, or using structural pg_dump output to produce a schema diagram on the fly.

## Author

* [Lukas Fittl](https://github.com/lfittl)

## LICENSE

Copyright (c) 2016 Lukas Fittl<br>
Licensed under the MIT License.
