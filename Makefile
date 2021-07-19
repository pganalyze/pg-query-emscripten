SOURCES := $(wildcard $(FLATTENED_LIB_DIR)/*.c)
OBJECTS := $(patsubst $(FLATTENED_LIB_DIR)/%.c,$(OBJECT_DIR)/%.o, $(SOURCES))

.PHONY: flatten

all: flatten

# Generates the source tree that `pg_query.js` operates on
flatten:
	./flatten.sh

$(OBJECT_DIR)/%.o: $(FLATTENED_LIB_DIR)/%.c
	@mkdir -p $(@D)
	emcc -I $(FLATTENED_LIB_DIR)/include -O3 -c $< -o $@


pg_query.js: $(OBJECTS) entry.cpp module.js
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
		-s ERROR_ON_UNDEFINED_SYMBOLS=0 \
		-o pg_query.js --bind -O3 --no-entry --pre-js module.js \
		$(OBJECTS) entry.cpp

clean:
	-@ $(RM) -r $(BUILD_DIR)
