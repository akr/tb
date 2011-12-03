require "coverage.so"

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

at_exit {
  r = Coverage.result
  r.keys.sort.each {|f|
    next if %r{lib/tb[/.]} !~ f
    ns = r[f]
    max = ns.compact.max
    w = max.to_s.length
    fmt1 = "%s %#{w}d:%s"
    fmt2 = "%s #{" " * w}:%s"
    File.foreach(f).with_index {|line, i|
      line = expand_tab(line)
      if ns[i]
        puts fmt1 % [f, ns[i], line]
      else
        puts fmt2 % [f, line]
      end
    }
  }
}
Coverage.start

load 'test-all.rb'
