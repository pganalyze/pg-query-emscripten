#include <emscripten/bind.h>
#include "pg_query.h"

#if PG_VERSION_NUM >= 130002
#include "protobuf/pg_query.pb-c.h"
#endif

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
  std::string fingerprint_str;
  std::string stderr_buffer;
  ParseError error;
} FingerprintResult;


#if PG_VERSION_NUM >= 130002
typedef struct {
	std::string text;
	uint32_t start;
	uint32_t end;
	std::string token_kind;
	std::string keyword_kind;
} Token;

typedef struct {
	uint32_t version;
	std::vector<Token> tokens;
	std::string stderr_buffer;
	ParseError error;
} ScanResult;
#endif

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

// Scanner not avaliable in older versions
#if PG_VERSION_NUM >= 130002
ScanResult raw_scan(intptr_t input) {
	PgQueryScanResult tmp_result;
	ScanResult result;

	PgQuery__ScanResult *scan_result;
	PgQuery__ScanToken *scan_token;
	const ProtobufCEnumValue *token_kind;
	const ProtobufCEnumValue *keyword_kind;
	
	std::string casted_input = std::string(reinterpret_cast<char*>(input));

	tmp_result = pg_query_scan(casted_input.c_str());
	scan_result = pg_query__scan_result__unpack(
		NULL, tmp_result.pbuf.len, (uint8_t *) tmp_result.pbuf.data
	);

	result.version = scan_result->version;

	for (size_t j = 0; j < scan_result->n_tokens; j++) {
		scan_token = scan_result->tokens[j];
		token_kind = protobuf_c_enum_descriptor_get_value(
			&pg_query__token__descriptor, scan_token->token
		);
		keyword_kind = protobuf_c_enum_descriptor_get_value(
			&pg_query__keyword_kind__descriptor, scan_token->keyword_kind
		);

		Token token;

		token.text = casted_input.substr(scan_token->start, scan_token->end - scan_token->start);
		token.start = scan_token->start;
		token.end = scan_token->end;
		token.token_kind = token_kind->name;
		token.keyword_kind = keyword_kind->name;

		result.tokens.push_back(token);
	}

	if (tmp_result.error) {
		result.error = transform_error(*tmp_result.error);
	}
	if (tmp_result.stderr_buffer) {
		result.stderr_buffer = std::string(tmp_result.stderr_buffer);
	}

	pg_query__scan_result__free_unpacked(scan_result, NULL);
	pg_query_free_scan_result(tmp_result);

	return result;
}
#endif


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

#if PG_VERSION_NUM >= 130002
	result.fingerprint_str = std::string(tmp_result.fingerprint_str);
#endif


#if PG_VERSION_NUM == 100000	
	result.fingerprint_str = std::string(tmp_result.hexdigest);
#endif

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
		.field("fingerprint_str", &FingerprintResult::fingerprint_str)
		.field("stderr_buffer", &FingerprintResult::stderr_buffer)
		.field("error", &FingerprintResult::error)
		;


#if PG_VERSION_NUM >= 130002
	value_object<Token>("Token")
		.field("text", &Token::text)
		.field("start", &Token::start)
		.field("end", &Token::end)
		.field("token_kind", &Token::token_kind)
		.field("keyword_kind", &Token::keyword_kind)	
		;

	register_vector<Token>("VectorToken");

	value_object<ScanResult>("ScanResult")
		.field("version", &ScanResult::version)
		.field("tokens", &ScanResult::tokens)
		.field("stderr_buffer", &ScanResult::stderr_buffer)
		.field("error", &ScanResult::error)
		;
#endif 

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
#if PG_VERSION_NUM >= 130002
	function("raw_scan", &raw_scan);
#endif 
}
