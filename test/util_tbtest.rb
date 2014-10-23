require 'stringio'

def capture_stderr
  begin
    save_stderr = $stderr
    $stderr = StringIO.new(stderr='')
    yield
  ensure
    $stderr = save_stderr
  end
  stderr
end
