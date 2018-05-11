LIB_PG_QUERY_TAG = 10-1.0.1

root_dir := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
TMPDIR = $(root_dir)/tmp
LIBDIR = $(TMPDIR)/libpg_query
LIBDIRGZ = $(TMPDIR)/libpg_query-$(LIB_PG_QUERY_TAG).tar.gz

default:
	@echo "Run 'make update_source' if you want to regenerate the JS library"

.PHONY: flatten_source fix_pg_config update_source

$(LIBDIR): $(LIBDIRGZ)
	mkdir -p $(LIBDIR)
	cd $(TMPDIR); tar -xzf $(LIBDIRGZ) -C $(LIBDIR) --strip-components=1

$(LIBDIRGZ):
	mkdir -p $(TMPDIR)
	curl -o $(LIBDIRGZ) https://codeload.github.com/lfittl/libpg_query/tar.gz/$(LIB_PG_QUERY_TAG)

flatten_source: $(LIBDIR)
	mkdir -p parser
	rm -f parser/*.{c,h}
	rm -fr parser/include
	# Reduce everything down to one directory
	cp -a $(LIBDIR)/src/* parser/
	mv parser/postgres/* parser/
	rmdir parser/postgres
	cp -a $(LIBDIR)/pg_query.h parser/include
	# Make sure every .c file in the top-level directory is its own translation unit
	mv parser/*{_conds,_defs,_helper,_random}.c parser/include

fix_pg_config:
	echo "#undef HAVE_SIGSETJMP" >> parser/include/pg_config.h
	echo "#undef HAVE_SPINLOCKS" >> parser/include/pg_config.h
	echo "#undef PG_INT128_TYPE" >> parser/include/pg_config.h

update_source: flatten_source fix_pg_config
	emcc -O3 -o pg_query.o -Iparser/include parser/*.c
	em++ -s EXPORTED_FUNCTIONS="['_normalize', '_parse', '_parse_plpgsql', '_fingerprint']" -Iparser/include -O3 --bind --pre-js module.js --memory-init-file 0 -o tmp/pg_query_raw.js pg_query.o entry.cpp
	rm -f pg_query.o
	echo "var PgQuery = (function () {" > pg_query.js
	cat tmp/pg_query_raw.js >> pg_query.js
	echo "return { normalize: Module.normalize, parse: Module.parse, parse_plpgsql: Module.parse_plpgsql, fingerprint: Module.fingerprint };" >> pg_query.js
	echo "})();" >> pg_query.js
	echo "if (typeof module !== 'undefined') module.exports = PgQuery;" >> pg_query.js
	echo "if (typeof define === 'function') define(PgQuery);" >> pg_query.js

clean:
	-@ $(RM) -r $(TMPDIR)
