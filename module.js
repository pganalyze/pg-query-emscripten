var Module = {
  print: function(text) { console.log('stdout: ' + text) },
  printErr: function(text) { console.log('stderr: ' + text) },
  noInitialRun: true,

  parse: function parse(text) {
    var pointer = allocate(intArrayFromString(text), 'i8', ALLOC_NORMAL);
    var parsed  = Module.raw_parse(pointer);

    parsed['parse_tree'] = JSON.parse(parsed['parse_tree']);

    return parsed;
  },
};
