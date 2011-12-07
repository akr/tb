begin
  require 'io/console'
rescue LoadError
end

class Tb::Pager
  def self.open
    pager = self.new
    begin
      yield pager
    ensure
      pager.close
    end
  end

  def initialize
    if STDOUT.tty?
      @io = nil
      @buf = ''
    else
      @io = STDOUT
      @buf = nil
    end
  end

  def <<(obj)
    write obj.to_s
  end

  def print(*args)
    s = ''
    args.map {|a| s << a.to_s }
    write s
  end

  def printf(format, *args)
    write sprintf(format, *args)
  end

  def putc(ch)
    if Integer === ch
      write [ch].pack("C")
    else
      write ch.to_s
    end
  end

  def puts(*objs)
    if objs.empty?
      write "\n"
    else
      objs.each {|o|
        o = o.to_s
        write o
        write "\n" if /\n\z/ !~ o
      }
    end
  end

  def write_nonblock(str)
    write str.to_s
  end

  def expand_tab(str, tabstop=8)
    col = 0
    str.gsub(/(\t+)|[^\t]+/) {
      if $1
        ' ' * (($1.length * tabstop) - (col + 1) % tabstop)
      else
        $&
      end
    }
  end

  DEFAULT_LINES = 24
  DEFAULT_COLUMNS = 80

  def winsize
    if STDOUT.respond_to? :winsize
      lines, columns = STDOUT.winsize
      return [lines, columns] if lines != 0 && columns != 0
    end
    [DEFAULT_LINES, DEFAULT_COLUMNS]
  end

  def single_screen?(str)
    lines, columns = winsize
    n = 0
    str.each_line {|line|
      line = expand_tab(line).chomp
      cols = line.length # xxx: 1 column/character assumed.
      cols = 1 if cols == 0
      m = (cols + columns - 1) / columns # termcap am capability is assumed.
      n += m
    }
    n <= lines-1
  end

  def write(str)
    str = str.to_s
    if !@io
      @buf << str
      if !single_screen?(@buf)
        @io = IO.popen(ENV['PAGER'] || 'more', 'w')
        @io << @buf
        @buf = nil
      end
    else
      @io << str
    end
  end

  def flush
    @io.flush if @io
  end

  def close
    if !@io
      STDOUT.print @buf
    else
      @io.close
    end
  end
end
