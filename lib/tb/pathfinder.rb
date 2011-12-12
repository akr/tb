# lib/tb/pathfinder.rb - pattern matcher for two-dimensional array.
#
# Copyright (C) 2011 Tanaka Akira  <akr@fsij.org>
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
#  1. Redistributions of source code must retain the above copyright notice, this
#     list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#  3. The name of the author may not be used to endorse or promote products
#     derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
# EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
# OF SUCH DAMAGE.

module Tb::Pathfinder
  module_function

  def strary_to_aa(strary)
    aa = []
    strary.each_with_index {|str, y|
      aa[y] = []
      str.each_char.with_index {|ch, x|
        aa[y][x] = ch
      }
    }
    aa
  end

  def match(pat, aa, start=nil)
    each_match(pat, aa, start) {|spos, epos, cap|
      return spos, epos, cap
    }
  end

  def each_match(pat, aa, spos=nil)
    if spos
      run {
        try(pat, aa, Tb::Pathfinder::EmptyState.merge(:pos => spos)) {|st2|
          yield spos, st2.fetch(:pos), st2.reject {|k,v| k == :pos }
          nil
        }
      }
    else
      aa.each_with_index {|a, y|
        a.each_index {|x|
          spos = [x,y]
          run {
            try(pat, aa, Tb::Pathfinder::EmptyState.merge(:pos => spos)) {|st2|
              yield spos, st2.fetch(:pos), st2.reject {|k,v| k == :pos }
              nil
            }
          }
        }
      }
    end
    nil
  end

  def run(&b)
    stack = [b]
    while !stack.empty?
      last = stack.pop
      v = last.call
      case v
      when nil
      when Array
        v.each {|e|
          raise TypeError, "result array contains non-proc: #{last.inspect}" unless Proc === e
        }
        stack.concat v.reverse
      when Proc
        stack << v
      else
        raise TypeError, "unexpected: #{v.inspect}"
      end
    end
  end

  def try(pat, aa, st, &b)
    case pat
    when nil; lambda { yield st }
    when String; try_lit(pat, aa, st, &b)
    when Regexp; try_regexp(pat, aa, st, &b)
    when :n, :north; try_rmove(:north, aa, st, &b)
    when :s, :south; try_rmove(:south, aa, st, &b)
    when :e, :east; try_rmove(:east, aa, st, &b)
    when :w, :west; try_rmove(:west, aa, st, &b)
    when :debug_print_state; p st; yield st
    when Array
      case pat[0]
      when :rmove; _, dir = pat; try_rmove(dir, aa, st, &b)
      when :lit; _, val = pat; try_lit(val, aa, st, &b)
      when :regexp; _, re = pat; try_regexp(re, aa, st, &b)
      when :cat; _, *ps = pat; try_cat(ps, aa, st, &b)
      when :alt; _, *ps = pat; try_alt(ps, aa, st, &b)
      when :rep; _, *ps = pat; try_rep_generic(nil, 0, nil, true, ps, aa, st, &b)
      when :rep1; _, *ps = pat; try_rep_generic(nil, 1, nil, true, ps, aa, st, &b)
      when :rep_nongreedy; _, *ps = pat; try_rep_generic(nil, 0, nil, false, ps, aa, st, &b)
      when :rep1_nongreedy; _, *ps = pat; try_rep_generic(nil, 1, nil, false, ps, aa, st, &b)
      when :opt; _, *ps = pat; try_rep_generic(nil, 0, 1, true, ps, aa, st, &b)
      when :opt_nongreedy; _, *ps = pat; try_rep_generic(nil, 0, 1, false, ps, aa, st, &b)
      when :repn; _, num, *ps = pat; try_rep_generic(nil, num, num, true, ps, aa, st, &b)
      when :repeat; _, var, min, max, greedy, *ps = pat; try_rep_generic(var, min, max, greedy, ps, aa, st, &b)
      when :bfs; _, keys, *ps = pat; try_bfs(keys, ps, aa, st, &b)
      when :grid; _, *arys = pat; try_grid(arys, aa, st, &b)
      when :capval; _, n = pat; try_capval(n, aa, st, &b)
      when :refval; _, n = pat; try_refval(n, aa, st, &b)
      when :tmp_pos; _, dx, dy, *ps = pat; try_tmp_pos(dx, dy, ps, aa, st, &b)
      when :save_pos; _, n = pat; try_save_pos(n, aa, st, &b)
      when :push_pos; _, n = pat; try_push_pos(n, aa, st, &b)
      when :pop_pos; _, n = pat; try_pop_pos(n, aa, st, &b)
      when :update; _, pr = pat; try_update(pr, aa, st, &b)
      when :assert; _, pr = pat; try_assert(pr, aa, st, &b)
      else raise ArgumentError, "unexpected: #{pat.inspect}"
      end
    else
      raise ArgumentError, "unexpected pattern: #{pat.inspect}"
    end
  end

  def try_rmove(dir, aa, st)
    x, y = st.fetch(:pos)
    case dir
    when :east then x += 1
    when :west then x -= 1
    when :north then y -= 1
    when :south then y += 1
    end
    if 0 <= y && y < aa.length &&
       0 <= x && x < aa[y].length
      lambda { yield st.merge(:pos => [x,y]) }
    else
      nil
    end
  end

  def try_lit(val, aa, st)
    x, y = st.fetch(:pos)
    if 0 <= y && y < aa.length &&
       0 <= x && x < aa[y].length &&
       aa[y][x] == val
      lambda { yield st }
    else
      nil
    end
  end

  def try_regexp(re, aa, st)
    x, y = st.fetch(:pos)
    if 0 <= y && y < aa.length &&
       0 <= x && x < aa[y].length &&
       re =~ aa[y][x]
      lambda { yield st }
    else
      nil
    end
  end

  # p1 p2 ...
  def try_cat(ps, aa, st, &block)
    if ps.empty?
      lambda { yield st }
    else
      pat, *rest = ps
      try(pat, aa, st) {|st2|
        try_cat(rest, aa, st2, &block)
      }
    end
  end

  # p1 | p2 | ...
  def try_alt(ps, aa, st, &block)
    ps.map {|pat|
      lambda { try(pat, aa, st, &block) }
    }
  end

  # (p1 p2 ...)*
  # (p1 p2 ...){min,}
  # (p1 p2 ...){min,max}
  # (p1 p2 ...)*?
  # (p1 p2 ...){min,}?
  # (p1 p2 ...){min,max}?
  def try_rep_generic(var, min, max, greedy, ps, aa, st, visit_keys=[:pos], visited={}, &block)
    min = st[min].to_int if Symbol === min
    max = st[max].to_int if Symbol === max
    visited2 = visited.dup
    visited2[st.values_at(*visit_keys)] = true
    result = []
    if min <= 0 && !greedy
      result << lambda { 
        st = st.merge(var => visited.size) if var
        yield st
      }
    end
    if max.nil? || 0 < max
      min2 = min <= 0 ? 0 : min-1
      max2 = max ? max-1 : nil
      result << lambda {
        try_cat(ps, aa, st) {|st2|
          if !visited2[st2.values_at(*visit_keys)]
            try_rep_generic(var, min2, max2, greedy, ps, aa, st2, visit_keys, visited2, &block)
          else
            nil
          end
        }
      }
    end
    if min <= 0 && greedy
      result << lambda {
        st = st.merge(var => visited.size) if var
        yield st
      }
    end
    result
  end

  def try_bfs(keys, ps, aa, st, &b)
    queue = [st]
    visited = {st.values_at(*keys) => true}
    try_bfs_loop(queue, visited, keys, ps, aa, &b)
  end

  def try_bfs_loop(queue, visited, keys, ps, aa, &b)
    if queue.empty?
      nil
    else
      st = queue.shift
      result = []
      result << lambda {
        yield st
      } 
      result << lambda {
        try_cat(ps, aa, st) {|st2|
          k = st2.values_at(*keys)
          if !visited[k]
            visited[k] = true
            queue << st2
          end
          nil
        }
      }
      result << lambda {
        try_bfs_loop(queue, visited, keys, ps, aa, &b)
      } 
      result
    end
  end

  def try_grid(arys, aa, st)
    start = nil
    goal = nil
    newarys = []
    arys.each_with_index {|ary, y|
      newarys << []
      ary.each_with_index {|pat, x|
        if pat == :start
          raise ArgumentError, "multiple starts: #{arys.inspect}" if start
          start = [x,y]
          newarys.last << nil
        elsif Array === pat && pat[0] == :start
          raise ArgumentError, "multiple starts: #{arys.inspect}" if start
          start = [x,y]
          newarys.last << [:cat, *pat[1..-1]]
        elsif pat == :goal
          raise ArgumentError, "multiple goals: #{arys.inspect}" if goal
          goal = [x,y]
          newarys.last << nil
        elsif Array === pat && pat[0] == :goal
          raise ArgumentError, "multiple goals: #{arys.inspect}" if goal
          goal = [x,y]
          newarys.last << [:cat, *pat[1..-1]]
        elsif pat == :origin
          raise ArgumentError, "multiple starts: #{arys.inspect}" if start
          raise ArgumentError, "multiple goals: #{arys.inspect}" if goal
          start = goal = [x,y]
          newarys.last << nil
        elsif Array === pat && pat[0] == :origin
          raise ArgumentError, "multiple starts: #{arys.inspect}" if start
          raise ArgumentError, "multiple goals: #{arys.inspect}" if goal
          start = goal = [x,y]
          newarys.last << [:cat, *pat[1..-1]]
        else
          newarys.last << pat
        end
      }
    }
    raise ArgumentError, "no start" if !start
    raise ArgumentError, "no goal" if !goal
    pos = st.fetch(:pos)
    try_grid_rect(newarys, aa, st.merge(:pos => [pos[0]-start[0], pos[1]-start[1]])) {|st2|
      lambda { yield st2.merge(:pos => [pos[0]-start[0]+goal[0], pos[1]-start[1]+goal[1]]) }
    }
  end

  def try_grid_rect(arys, aa, st)
    if arys.empty?
      lambda { yield st }
    else
      ary, *rest = arys
      x, y = st.fetch(:pos)
      pos1 = [x, y+1]
      try_grid_row(ary, aa, st) {|st2|
        try_grid_rect(rest, aa, st2.merge(:pos => pos1)) {|st3|
          lambda { yield st3.merge(:pos => st.fetch(:pos)) }
        }
      }
    end
  end

  def try_grid_row(ary, aa, st)
    if ary.empty?
      lambda { yield st }
    else
      pat, *rest = ary
      x, y = st.fetch(:pos)
      pos1 = [x+1, y]
      try(pat, aa, st) {|st2|
        try_grid_row(rest, aa, st2.merge(:pos => pos1)) {|st3|
          lambda { yield st3.merge(:pos => st.fetch(:pos)) }
        }
      }
    end
  end

  def try_capval(n, aa, st)
    x, y = st.fetch(:pos)
    if 0 <= y && y < aa.length &&
       0 <= x && x < aa[y].length &&
      val = aa[y][x]
    else
      val = nil
    end
    st2 = st.merge(n => val)
    lambda { yield st2 }
  end

  def try_refval(n, aa, st)
    x, y = st.fetch(:pos)
    if 0 <= y && y < aa.length &&
       0 <= x && x < aa[y].length
      val = aa[y][x]
    else
      val = nil
    end
    if val == st[n]
      lambda { yield st }
    else
      nil
    end
  end

  def try_tmp_pos(dx, dy, ps, aa, st, &b)
    x, y = st.fetch(:pos)
    try_cat(ps, aa, st.merge(:pos => [x+dx, y+dy])) {|st2|
      lambda { yield st2.merge(:pos => st.fetch(:pos)) }
    }
  end

  def try_save_pos(n, aa, st, &b)
    st2 = st.merge(n => st.fetch(:pos))
    lambda { yield st2 }
  end

  def try_push_pos(n, aa, st, &b)
    ary = (st[n] || []) + [st.fetch(:pos)]
    st2 = st.merge(n => ary)
    lambda { yield st2 }
  end

  def try_pop_pos(n, aa, st, &b)
    ary = st[n]
    raise TypeError, "array expected: #{ary.inspect} (#{n.inspect})" unless Array === ary
    raise TypeError, "empty array (#{n.inspect})" if ary.empty?
    pos2 = ary.last
    raise TypeError, "array expected: #{pos2.inspect} (#{n.inspect})" unless Array === pos2
    raise TypeError, "two-element array expected: #{pos2.inspect} (#{n.inspect})" if pos2.length != 2
    raise TypeError, "integer elements expected: #{pos2.inspect} (#{n.inspect})" unless pos2.all? {|v| Integer === v }
    st2 = st.merge(:pos => pos2, n => ary[0...-1])
    lambda { yield st2 }
  end

  def try_update(pr, aa, st)
    st2 = pr.call(st)
    lambda { yield st2 }
  end

  def try_assert(pr, aa, st)
    if pr.call(st)
      lambda { yield st }
    else
      nil
    end
  end
end

module Tb::Pathfinder::EmptyState
  module_function

  def empty?
    true
  end

  def each
  end

  def to_h
    {}
  end

  def fetch(k, *rest)
    if block_given?
      yield k
    elsif !rest.empty?
      return rest[0]
    else
      exc = defined?(KeyError) ? KeyError : IndexError # 1.9 v.s. 1.8
      raise exc, "key not found: #{k}"
    end
  end

  def [](k)
    nil
  end

  def values_at(*ks)
    ks.map {|k| nil }
  end

  def keys
    []
  end

  def merge(h)
    pairs = self
    h.reverse_each {|k, v|
      pairs = Tb::Pathfinder::State.new(k, v, pairs)
    }
    pairs
  end

  def reject
    self
  end

  def inspect
    "\#<Tb::Pathfinder::EmptyState>"
  end
end

class Tb::Pathfinder::State
  def self.make(hash)
    Tb::Pathfinder::EmptyState.merge(hash)
  end

  def initialize(key, val, tail=nil)
    @key = key
    @val = val
    @tail = tail
  end
  attr_reader :key, :val, :tail

  def empty?
    false
  end

  def each
    pairs = self
    while !pairs.empty?
      yield [pairs.key, pairs.val]
      pairs = pairs.tail
    end
    nil
  end

  def to_h
    res = {}
    each {|k, v|
      if !res.include? k
        res[k] = v
      end
    }
    res
  end

  def ==(other)
    other.kind_of?(Tb::Pathfinder::State) &&
    self.to_h == other.to_h
  end

  def fetch(k, *rest)
    pairs = self
    while !pairs.empty?
      return pairs.val if k == pairs.key
      pairs = pairs.tail
    end
    if block_given?
      yield k
    elsif !rest.empty?
      return rest[0]
    else
      exc = defined?(KeyError) ? KeyError : IndexError # 1.9 v.s. 1.8
      raise exc, "key not found: #{k}"
    end
  end

  def [](k)
    fetch(k, nil)
  end

  def values_at(*ks)
    ks.map {|k| self[k] }
  end

  def keys
    result = []
    pairs = self
    while !pairs.empty?
      result << pairs.key
      pairs = pairs.tail
    end
    result
  end

  def merge(h)
    return self if h.empty?
    n = 0
    pairs = self
    ary = []
    result = self
    needs_copy = 0
    while !pairs.empty?
      if h.include? pairs.key
        needs_copy = ary.length
        result = pairs.tail
        n += 1
        break if n == h.size
      else
        ary << pairs
      end
      pairs = pairs.tail
    end
    (needs_copy-1).downto(0) {|i|
      pairs = ary[i]
      result = Tb::Pathfinder::State.new(pairs.key, pairs.val, result)
    }
    h.reverse_each {|k, v|
      result = Tb::Pathfinder::State.new(k, v, result)
    }
    result
  end

  def reject
    ary = []
    pairs = self
    while !pairs.empty?
      unless yield pairs.key, pairs.val
        ary << pairs
      end
      pairs = pairs.tail
    end
    result = Tb::Pathfinder::EmptyState
    ary.reverse_each {|pairs2|
      result = Tb::Pathfinder::State.new(pairs2.key, pairs2.val, result)
    }
    result
  end

  def inspect
    pairs = self
    str = ''
    while !pairs.empty?
      str << pairs.key.inspect << "=>" << pairs.val.inspect << ", "
      pairs = pairs.tail
    end
    str.sub!(/, \z/, '')
    "\#<#{self.class}: #{str}>"
  end

end

