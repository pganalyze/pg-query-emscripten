var Module = {
  print: function(text) { console.log('stdout: ' + text) },
  printErr: function(text) { console.log('stderr: ' + text) },
  noInitialRun: true,
  parse: function parse(text) { return JSON.parse(Module.ccall('parse', 'string', ['string'], [text])) },
};
