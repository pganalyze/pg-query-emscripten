SOURCES := $(wildcard $(FLATTENED_LIB_DIR)/*.c)
OBJECTS := $(patsubst $(FLATTENED_LIB_DIR)/%.c,$(OBJECT_DIR)/%.o, $(SOURCES))

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

.PHONY: flatten

all: flatten

# Generates the source tree that `pg_query.js` operates on
flatten:
	./flatten.sh $(ARTIFACT)

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
