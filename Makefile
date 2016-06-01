LIB_PG_QUERY_TAG = 9.5-1.3.0

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
	rm -f parser/*.{c,h}
	rm -fr parser/include
	# Reduce everything down to one directory
	cp -a $(LIBDIR)/src/* parser/
	mv parser/postgres/* parser/
	rmdir parser/postgres
	cp -a $(LIBDIR)/pg_query.h parser/include
	# Make sure every .c file in the top-level directory is its own translation unit
	mv parser/*{_conds,_defs,_helper,scan}.c parser/include

fix_pg_config:
	echo "#undef HAVE_SIGSETJMP" >> parser/include/pg_config.h
	echo "#undef HAVE_SPINLOCKS" >> parser/include/pg_config.h
	echo "#undef PG_INT128_TYPE" >> parser/include/pg_config.h

update_source: flatten_source fix_pg_config
	emcc -s EXPORTED_FUNCTIONS="['_parse']" -Iparser/include -O2 --pre-js module.js --memory-init-file 0 -o pg_query.js entry.c parser/*.c

clean:
	-@ $(RM) -r $(TMPDIR)
