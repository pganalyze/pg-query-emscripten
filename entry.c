#include <pg_query.h>
#include <stdio.h>
#include <string.h>

char* parse(const char* input) {
  PgQueryParseResult result;
  char* retval;

  pg_query_init();

  result = pg_query_parse(input);

  if (result.error) {
    size_t i;
    char* msg = result.error->message;

    // Make sure the message is a valid JSON string
    for (i=0; msg[i] != '\0'; i++) {
      if (msg[i] == '"') { msg[i] = '\''; }
    }

    asprintf(&retval, "{\"error\": \"%s\"}", msg);
    return retval;
  }

  asprintf(&retval, "{\"parse_tree\": %s}", result.parse_tree);

  pg_query_free_parse_result(result);

  return retval;
}
