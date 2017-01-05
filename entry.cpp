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
	std::string normalized_query;
	ParseError error;
} NormalizeResult;

typedef struct {
	std::string parse_tree;
	std::string stderr_buffer;
	ParseError error;
} ParseResult;

typedef struct {
	std::string plpgsql_funcs;
	ParseError error;
} PlpgsqlParseResult;

typedef struct {
  std::string hexdigest;
  std::string stderr_buffer;
  ParseError error;
} FingerprintResult;

ParseError transform_error(PgQueryError tmp_error) {
	ParseError error;

	error.message   = std::string(tmp_error.message);
	error.funcname  = std::string(tmp_error.funcname);
	error.filename  = std::string(tmp_error.filename);
	error.lineno    = int(tmp_error.lineno);
	error.cursorpos = int(tmp_error.cursorpos);

	if (tmp_error.context) {
		error.context = std::string(tmp_error.context);
	}

	return error;
}

NormalizeResult raw_normalize(intptr_t input) {
	PgQueryNormalizeResult tmp_result;
	NormalizeResult result;

	tmp_result = pg_query_normalize(reinterpret_cast<char*>(input));

	if (tmp_result.error) {
		result.error = transform_error(*tmp_result.error);
	}

	result.normalized_query = std::string(tmp_result.normalized_query);

	pg_query_free_normalize_result(tmp_result);

	return result;
}

ParseResult raw_parse(intptr_t input) {
	PgQueryParseResult tmp_result;
	ParseResult result;

	tmp_result = pg_query_parse(reinterpret_cast<char*>(input));

	if (tmp_result.error) {
		result.error = transform_error(*tmp_result.error);
	}
	if (tmp_result.stderr_buffer) {
		result.stderr_buffer = std::string(tmp_result.stderr_buffer);
	}

	result.parse_tree = std::string(tmp_result.parse_tree);

	pg_query_free_parse_result(tmp_result);

	return result;
}

PlpgsqlParseResult raw_parse_plpgsql(intptr_t input) {
	PgQueryPlpgsqlParseResult tmp_result;
	PlpgsqlParseResult result;

	tmp_result = pg_query_parse_plpgsql(reinterpret_cast<char*>(input));

	if (tmp_result.error) {
		result.error = transform_error(*tmp_result.error);
	}

	result.plpgsql_funcs = std::string(tmp_result.plpgsql_funcs);

	pg_query_free_plpgsql_parse_result(tmp_result);

	return result;
}

FingerprintResult raw_fingerprint(intptr_t input) {
	PgQueryFingerprintResult tmp_result;
	FingerprintResult result;

	tmp_result = pg_query_fingerprint(reinterpret_cast<char*>(input));

	if (tmp_result.error) {
		result.error = transform_error(*tmp_result.error);
	}
	if (tmp_result.stderr_buffer) {
		result.stderr_buffer = std::string(tmp_result.stderr_buffer);
	}

	result.hexdigest = std::string(tmp_result.hexdigest);

	pg_query_free_fingerprint_result(tmp_result);

	return result;
}

EMSCRIPTEN_BINDINGS(my_module) {
	value_object<NormalizeResult>("NormalizeResult")
		.field("normalized_query", &NormalizeResult::normalized_query)
		.field("error", &NormalizeResult::error)
		;

	value_object<ParseResult>("ParseResult")
		.field("parse_tree", &ParseResult::parse_tree)
		.field("stderr_buffer", &ParseResult::stderr_buffer)
		.field("error", &ParseResult::error)
		;

	value_object<PlpgsqlParseResult>("PlpgsqlParseResult")
		.field("plpgsql_funcs", &PlpgsqlParseResult::plpgsql_funcs)
		.field("error", &PlpgsqlParseResult::error)
		;

	value_object<FingerprintResult>("FingerprintResult")
		.field("hexdigest", &FingerprintResult::hexdigest)
		.field("stderr_buffer", &FingerprintResult::stderr_buffer)
		.field("error", &FingerprintResult::error)
		;

	value_object<ParseError>("ParseError")
		.field("message", &ParseError::message)
		.field("funcname", &ParseError::funcname)
		.field("filename", &ParseError::filename)
		.field("lineno", &ParseError::lineno)
		.field("cursorpos", &ParseError::cursorpos)
		.field("context", &ParseError::context)
		;

	function("raw_normalize", &raw_normalize);
	function("raw_parse", &raw_parse);
	function("raw_parse_plpgsql", &raw_parse_plpgsql);
	function("raw_fingerprint", &raw_fingerprint);
}
