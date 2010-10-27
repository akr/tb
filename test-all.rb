$VERBOSE = true

$:.unshift "lib"

Dir.glob('test/test_*.rb') {|filename|
  load filename
}
