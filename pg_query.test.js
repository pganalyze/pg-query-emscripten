import Module from "./pg_query";

let pgQuery;

beforeAll(async () => {
	pgQuery = await new Module();
});

test("normalize", () => {
	expect(pgQuery.normalize("select 1")).toStrictEqual({
		error: null,
		normalized_query: "select $1",
	});
});

test("parse", () => {
	const initial = pgQuery.parse("select 1");
	// Tests shouldn't be version dependent
	const { version, ...expected } = initial["parse_tree"];

	expect(expected).toStrictEqual({
		stmts: [
			{
				stmt: {
					SelectStmt: {
						targetList: [
							{
								ResTarget: {
									val: {
										A_Const: {
											ival: { ival: 1 },
											location: 7,
										},
									},
									location: 7,
								},
							},
						],
						limitOption: "LIMIT_OPTION_DEFAULT",
						op: "SETOP_NONE",
					},
				},
			},
		],
	});
});

test("parsePlpgsql", () => {
	const expected = pgQuery.parsePlpgsql(`
		CREATE OR REPLACE FUNCTION cs_fmt_browser_version(
			v_name varchar,
			v_version varchar
		)
		RETURNS varchar AS $$
		BEGIN
			IF v_version IS NULL THEN
				RETURN v_name;
			END IF;
			RETURN v_name || '/' || v_version;
		END;
		$$
		LANGUAGE plpgsql`);

	expect(expected).toStrictEqual({
		plpgsql_funcs: [
			{
				PLpgSQL_function: {
					datums: [
						{
							PLpgSQL_var: {
								refname: "v_name",
								datatype: {
									PLpgSQL_type: { typname: "UNKNOWN" },
								},
							},
						},
						{
							PLpgSQL_var: {
								refname: "v_version",
								datatype: {
									PLpgSQL_type: { typname: "UNKNOWN" },
								},
							},
						},
						{
							PLpgSQL_var: {
								refname: "found",
								datatype: {
									PLpgSQL_type: { typname: "UNKNOWN" },
								},
							},
						},
					],
					action: {
						PLpgSQL_stmt_block: {
							lineno: 2,
							body: [
								{
									PLpgSQL_stmt_if: {
										lineno: 3,
										cond: {
											PLpgSQL_expr: {
												parseMode: 2,
												query: "v_version IS NULL",
											},
										},
										then_body: [
											{
												PLpgSQL_stmt_return: {
													lineno: 4,
													expr: {
														PLpgSQL_expr: {
															parseMode: 2,
															query: "v_name",
														},
													},
												},
											},
										],
									},
								},
								{
									PLpgSQL_stmt_return: {
										lineno: 6,
										expr: {
											PLpgSQL_expr: {
												parseMode: 2,
												query: "v_name || '/' || v_version",
											},
										},
									},
								},
							],
						},
					},
				},
			},
		],
		error: null,
	});
});

test("fingerprint", () => {
	expect(pgQuery.fingerprint("select 1 from foo where a = b")).toStrictEqual({
		error: null,
		fingerprint_str: "27e78aa34bd5bf64",
		stderr_buffer: "",
	});
});

test("scan", () => {
	const { tokens, version, ...remaining } = pgQuery.scan("select 1");

	expect(
		Array.from({ length: tokens.size() }, (_, idx) => tokens.get(idx))
	).toStrictEqual([
		{
			text: "select",
			start: 0,
			end: 6,
			token_kind: "SELECT",
			keyword_kind: "RESERVED_KEYWORD",
		},
		{
			text: "1",
			start: 7,
			end: 8,
			token_kind: "ICONST",
			keyword_kind: "NO_KEYWORD",
		},
	]);

	expect(remaining).toStrictEqual({
		error: null,
		stderr_buffer: "",
	});
});
