$VERBOSE = true

$:.unshift "lib"

r, w = IO.pipe
w.close
$stdin.reopen(r)
r.close

Dir.glob('test/test_*.rb') {|filename|
  load filename
}
