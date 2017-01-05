var Module = {
  print: function(text) { console.log('stdout: ' + text) },
  printErr: function(text) { console.log('stderr: ' + text) },
  noInitialRun: true,

  normalize: function normalize(text) {
    var pointer = allocate(intArrayFromString(text), 'i8', ALLOC_NORMAL);
    var parsed  = Module.raw_normalize(pointer);

    if (parsed.error.message == "") {
      parsed.error = null
    }

    return parsed;
  },

  parse: function parse(text) {
    var pointer = allocate(intArrayFromString(text), 'i8', ALLOC_NORMAL);
    var parsed  = Module.raw_parse(pointer);

    parsed.parse_tree = JSON.parse(parsed['parse_tree']);

    if (parsed.error.message == "") {
      parsed.error = null
    }

    return parsed;
  },

  parse_plpgsql: function parse_plpgsql(text) {
    var pointer = allocate(intArrayFromString(text), 'i8', ALLOC_NORMAL);
    var parsed  = Module.raw_parse_plpgsql(pointer);

    parsed.plpgsql_funcs = JSON.parse(parsed['plpgsql_funcs']);

    if (parsed.error.message == "") {
      parsed.error = null
    }

    return parsed;
  },

  fingerprint: function fingerprint(text) {
    var pointer = allocate(intArrayFromString(text), 'i8', ALLOC_NORMAL);
    var parsed  = Module.raw_fingerprint(pointer);

    if (parsed.error.message == "") {
      parsed.error = null
    } else {
      parsed.hexdigest = null
    }

    return parsed;
  },
};
