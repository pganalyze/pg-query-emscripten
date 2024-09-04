LIB_PG_QUERY_TAG := 16-5.1.0

BUILD_DIR := tmp/$(LIB_PG_QUERY_TAG)
FLATTENED_LIB_DIR := $(BUILD_DIR)/flattened
OBJECT_DIR := $(BUILD_DIR)/object
LIB_DIR := $(BUILD_DIR)/libpg_query
LIB_ARCHIVE := $(BUILD_DIR)/libpg_query.tar.gz

WASM ?= 0

ifeq ($(WASM),1)
ARTIFACT := pg_query_wasm.js
else
ifeq ($(WASM),0)
ARTIFACT := pg_query.js
else
$(error Invalid $$WASM value "$(WASM)" (can either by `0` or `1`))
endif
endif

.PHONY: flatten test
.NOTPARALLEL: flatten

all: flatten

# Generates the source tree that `pg_query.js` operates on
flatten:
	mkdir -p "$(BUILD_DIR)"

	if [ ! -e "$(LIB_ARCHIVE)" ]; then \
		curl -o "$(LIB_ARCHIVE)" \
			"https://codeload.github.com/pganalyze/libpg_query/tar.gz/$(LIB_PG_QUERY_TAG)"; \
	fi

	rm -rf "$(LIB_DIR)"
	mkdir "$(LIB_DIR)"

	tar -xf "$(LIB_ARCHIVE)" -C "$(LIB_DIR)" --strip-components 1

	rm -rf "$(FLATTENED_LIB_DIR)"
	mkdir -p "$(FLATTENED_LIB_DIR)"

	cp -a $(LIB_DIR)/src/* "$(FLATTENED_LIB_DIR)"
	mv $(FLATTENED_LIB_DIR)/postgres/include "$(FLATTENED_LIB_DIR)/include/postgres"
	mv $(FLATTENED_LIB_DIR)/postgres/* "$(FLATTENED_LIB_DIR)"
	rmdir "$(FLATTENED_LIB_DIR)/postgres"
	cp -a "$(LIB_DIR)/pg_query.h" "$(FLATTENED_LIB_DIR)/include"

	# Protobuf definitions
	# TODO: This generated .ts file seems to run the typescript compiler out of memory, possible due to recursive references? (see https://github.com/microsoft/TypeScript/issues/53087)
	#npm install ts-proto
	#protoc --proto_path=$(LIB_DIR)/protobuf --plugin=./node_modules/.bin/protoc-gen-ts_proto --ts_proto_out=. $(LIB_DIR)/protobuf/pg_query.proto
	mkdir -p $(FLATTENED_LIB_DIR)//include/protobuf
	cp -a $(LIB_DIR)/protobuf/*.h $(FLATTENED_LIB_DIR)/include/protobuf
	cp -a $(LIB_DIR)/protobuf/*.c $(FLATTENED_LIB_DIR)/
	# Protobuf library code
	mkdir -p $(FLATTENED_LIB_DIR)//include/protobuf-c
	cp -a $(LIB_DIR)/vendor/protobuf-c/*.h $(FLATTENED_LIB_DIR)/include
	cp -a $(LIB_DIR)/vendor/protobuf-c/*.h $(FLATTENED_LIB_DIR)/include/protobuf-c
	cp -a $(LIB_DIR)/vendor/protobuf-c/*.c $(FLATTENED_LIB_DIR)/
	# xxhash library code
	mkdir -p $(FLATTENED_LIB_DIR)//include/xxhash
	cp -a $(LIB_DIR)/vendor/xxhash/*.h $(FLATTENED_LIB_DIR)/include
	cp -a $(LIB_DIR)/vendor/xxhash/*.h $(FLATTENED_LIB_DIR)/include/xxhash
	cp -a $(LIB_DIR)/vendor/xxhash/*.c $(FLATTENED_LIB_DIR)/

	echo "#undef HAVE_SIGSETJMP" >> "$(FLATTENED_LIB_DIR)/include/pg_config.h"
	echo "#undef HAVE_SPINLOCKS" >> "$(FLATTENED_LIB_DIR)/include/pg_config.h"
	echo "#undef PG_INT128_TYPE" >> "$(FLATTENED_LIB_DIR)/include/pg_config.h"

	$(MAKE) $(ARTIFACT)

SOURCES := $(wildcard $(FLATTENED_LIB_DIR)/*.c)
OBJECTS := $(patsubst $(FLATTENED_LIB_DIR)/%.c,$(OBJECT_DIR)/%.o, $(SOURCES))

$(OBJECT_DIR)/%.o: $(FLATTENED_LIB_DIR)/%.c
	@mkdir -p $(@D)
	emcc \
		-I $(FLATTENED_LIB_DIR)/include \
		-I $(FLATTENED_LIB_DIR)/include/postgres \
		-O3 -c $< -o $@


$(ARTIFACT): $(OBJECTS) entry.cpp module.js
	em++ \
		-I $(FLATTENED_LIB_DIR)/include \
		-I $(FLATTENED_LIB_DIR)/include/postgres \
		-s ALLOW_MEMORY_GROWTH=1 \
		-s ASSERTIONS=0 \
		-s EXPORTED_RUNTIME_METHODS="['ALLOC_STACK','allocate']" \
		-s EXPORTED_FUNCTIONS="['_free']" \
		-s DEFAULT_LIBRARY_FUNCS_TO_INCLUDE=allocate \
		-s ENVIRONMENT=web \
		-s SINGLE_FILE=1 \
		-s MODULARIZE=1 \
		-s EXPORT_NAME="pgQuery" \
		-s WASM=$(WASM) \
		-s USE_ES6_IMPORT_META=0 \
		-s EXPORT_ES6=1 \
		-s ERROR_ON_UNDEFINED_SYMBOLS=0 \
		-o $(ARTIFACT) --bind -O3 --no-entry --pre-js module.js \
		$(OBJECTS) entry.cpp

clean:
	-@ $(RM) -r $(BUILD_DIR)

test:
	NODE_OPTIONS=--experimental-vm-modules yarn test
