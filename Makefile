LIB_PG_QUERY_TAG := 13-2.0.7

BUILD_DIR := tmp/$(LIB_PG_QUERY_TAG)
FLATTENED_LIB_DIR := $(BUILD_DIR)/flattened
OBJECT_DIR := $(BUILD_DIR)/object
LIB_DIR := $(BUILD_DIR)/libpg_query
LIB_ARCHIVE := $(BUILD_DIR)/libpg_query.tar.gz

WASM ?= 1

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
			"https://codeload.github.com/lfittl/libpg_query/tar.gz/$(LIB_PG_QUERY_TAG)"; \
	fi

	rm -rf "$(LIB_DIR)"
	mkdir "$(LIB_DIR)"

	tar -xf "$(LIB_ARCHIVE)" -C "$(LIB_DIR)" --strip-components 1

	rm -rf "$(FLATTENED_LIB_DIR)"
	mkdir -p "$(FLATTENED_LIB_DIR)"

	cp -a $(LIB_DIR)/src/* "$(FLATTENED_LIB_DIR)"
	mv $(FLATTENED_LIB_DIR)/postgres/* "$(FLATTENED_LIB_DIR)"
	rm -r "$(FLATTENED_LIB_DIR)/postgres"
	cp -a "$(LIB_DIR)/pg_query.h" "$(FLATTENED_LIB_DIR)/include"

	# Vendored dependencies
	if [ -d "$(LIB_DIR)/protobuf" ]; then \
		cp -a "$(LIB_DIR)/protobuf" "$(FLATTENED_LIB_DIR)/include/"; \
		cp -a $(LIB_DIR)/protobuf/* "$(FLATTENED_LIB_DIR)/"; \
	fi

	if [ -d "$(LIB_DIR)/vendor/protobuf-c" ]; then \
		cp -a "$(LIB_DIR)/vendor/protobuf-c" "$(FLATTENED_LIB_DIR)/include/"; \
		cp -a $(LIB_DIR)/vendor/protobuf-c/* "$(FLATTENED_LIB_DIR)/"; \
	fi

	if [ -d "$(LIB_DIR)/vendor/xxhash" ]; then \
		cp -a "$(LIB_DIR)/vendor/xxhash" "$(FLATTENED_LIB_DIR)/include/"; \
		cp -a $(LIB_DIR)/vendor/xxhash/* "$(FLATTENED_LIB_DIR)/"; \
	fi

	# Make every `.c` file in the top-level directory into its own translation unit
	mv $(FLATTENED_LIB_DIR)/*_conds.c $(FLATTENED_LIB_DIR)/*_defs.c \
		$(FLATTENED_LIB_DIR)/*_helper.c $(FLATTENED_LIB_DIR)/*_random.c \
		$(FLATTENED_LIB_DIR)/include

	echo "#undef HAVE_SIGSETJMP" >> "$(FLATTENED_LIB_DIR)/include/pg_config.h"
	echo "#undef HAVE_SPINLOCKS" >> "$(FLATTENED_LIB_DIR)/include/pg_config.h"
	echo "#undef PG_INT128_TYPE" >> "$(FLATTENED_LIB_DIR)/include/pg_config.h"

	$(MAKE) $(ARTIFACT)

SOURCES := $(wildcard $(FLATTENED_LIB_DIR)/*.c)
OBJECTS := $(patsubst $(FLATTENED_LIB_DIR)/%.c,$(OBJECT_DIR)/%.o, $(SOURCES))

$(OBJECT_DIR)/%.o: $(FLATTENED_LIB_DIR)/%.c
	@mkdir -p $(@D)
	emcc -I $(FLATTENED_LIB_DIR)/include -O3 -c $< -o $@


$(ARTIFACT): $(OBJECTS) entry.cpp module.js
	em++ \
		-I $(FLATTENED_LIB_DIR)/include \
		-s "ALLOW_MEMORY_GROWTH=1" \
		-s "ASSERTIONS=0" \
		-s EXPORTED_RUNTIME_METHODS="['ALLOC_STACK']" \
		-s "ENVIRONMENT=web" \
		-s "SINGLE_FILE=1" \
		-s "MODULARIZE=1" \
		-s 'EXPORT_NAME="pgQuery"' \
		-s "EXPORT_ES6=1" \
		-s WASM=$(WASM) \
		-s ERROR_ON_UNDEFINED_SYMBOLS=0 \
		-o $(ARTIFACT) --bind -O3 --no-entry --pre-js module.js \
		$(OBJECTS) entry.cpp

clean:
	-@ $(RM) -r $(BUILD_DIR)

test:
	NODE_OPTIONS=--experimental-vm-modules yarn test
