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
  fs = r.keys.sort.reject {|f|
    %r{lib/tb[/.]} !~ f
  }
  if !fs.empty?
    pat = nil
    fs[0].chars.to_a.reverse_each {|ch|
      if !pat
        pat = "#{Regexp.escape(ch)}?"
      else
        pat = "(?:#{Regexp.escape(ch)}#{pat})?"
      end
    }
    pat = Regexp.compile(pat)
    prefix_len = fs[0].length
    fs.each {|f|
      l = pat.match(f).end(0)
      prefix_len = l if l < prefix_len
    }
    prefix = fs[0][0, prefix_len]
    prefix.sub!(%r{[^/]+\z}, '')
    fs.each {|f|
      next if %r{lib/tb[/.]} !~ f
      f0 = f[prefix.length..-1]
      ns = r[f]
      max = ns.compact.max
      w = max.to_s.length
      fmt1 = "%s %#{w}d:%s"
      fmt2 = "%s #{" " * w}:%s"
      File.foreach(f).with_index {|line, i|
        line = expand_tab(line)
        if ns[i]
          puts fmt1 % [f0, ns[i], line]
        else
          puts fmt2 % [f0, line]
        end
      }
    }
  end
}
Coverage.start

load 'test-all.rb'
