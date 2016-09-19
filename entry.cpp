#include <emscripten/bind.h>
#include "pg_query.h"

using namespace emscripten;

/* Map to structs we can export */
typedef struct {
	std::string message; // exception message
	std::string funcname; // source function of exception (e.g. SearchSysCache)
	std::string filename; // source of exception (e.g. parse.l)
	int lineno; // source of exception (e.g. 104)
	int cursorpos; // char in query at which exception occurred
	std::string context; // additional context (optional, can be NULL)
} ParseError;

typedef struct {
	std::string parse_tree;
	std::string stderr_buffer;
	ParseError error;
} ParseResult;

ParseResult raw_parse(intptr_t input) {
	PgQueryParseResult tmp_result;
	ParseResult result;

	tmp_result = pg_query_parse(reinterpret_cast<char*>(input));

	if (tmp_result.error) {
		ParseError error;

		error.message   = std::string(tmp_result.error->message);
		error.funcname  = std::string(tmp_result.error->funcname);
		error.filename  = std::string(tmp_result.error->filename);
		error.lineno    = int(tmp_result.error->lineno);
		error.cursorpos = int(tmp_result.error->cursorpos);

		if (tmp_result.error->context) {
			error.context = std::string(tmp_result.error->context);
		}

		result.error = error;
	}

	if (tmp_result.stderr_buffer) {
		result.stderr_buffer = std::string(tmp_result.stderr_buffer);
	}

	result.parse_tree = std::string(tmp_result.parse_tree);

	pg_query_free_parse_result(tmp_result);

	return result;
}

EMSCRIPTEN_BINDINGS(my_module) {
	value_object<ParseResult>("ParseResult")
		.field("parse_tree", &ParseResult::parse_tree)
		.field("stderr_buffer", &ParseResult::stderr_buffer)
		.field("error", &ParseResult::error)
		;

	value_object<ParseError>("ParseError")
		.field("message", &ParseError::message)
		.field("funcname", &ParseError::funcname)
		.field("filename", &ParseError::filename)
		.field("lineno", &ParseError::lineno)
		.field("cursorpos", &ParseError::cursorpos)
		.field("context", &ParseError::context)
		;

	function("raw_parse", &raw_parse);
}
