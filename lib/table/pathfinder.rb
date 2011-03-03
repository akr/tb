# lib/table/pathfinder.rb - pattern matcher for two-dimensional array.
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

module Table::Pathfinder
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
    match_all(pat, aa, start) {|spos, epos, cap|
      return spos, epos, cap
    }
  end

  def match_all(pat, aa, spos=nil)
    if spos
      run {
        try(pat, aa, spos, {}.freeze) {|epos, cap2|
          yield spos, epos, cap2
          nil
        }
      }
    else
      aa.each_with_index {|a, y|
        a.each_index {|x|
          spos = [x,y]
          run {
            try(pat, aa, spos, {}.freeze) {|epos, cap2|
              yield spos, epos, cap2
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

  def try(pat, aa, pos, cap, &b)
    case pat
    when nil; lambda { yield pos, cap }
    when String; try_lit(pat, aa, pos, cap, &b)
    when Regexp; try_regexp(pat, aa, pos, cap, &b)
    when :right; try_rmove(pat, aa, pos, cap, &b)
    when :left; try_rmove(pat, aa, pos, cap, &b)
    when :up; try_rmove(pat, aa, pos, cap, &b)
    when :down; try_rmove(pat, aa, pos, cap, &b)
    when Array
      case pat[0]
      when :rmove; _, dir = pat; try_rmove(dir, aa, pos, cap, &b)
      when :lit; _, val = pat; try_lit(val, aa, pos, cap, &b)
      when :regexp; _, re = pat; try_regexp(re, aa, pos, cap, &b)
      when :cat; _, *ps = pat; try_cat(ps, aa, pos, cap, &b)
      when :alt; _, *ps = pat; try_alt(ps, aa, pos, cap, &b)
      when :rep; _, *ps = pat; try_rep_generic(0, nil, ps, true, aa, pos, cap, &b)
      when :rep1; _, *ps = pat; try_rep_generic(1, nil, ps, true, aa, pos, cap, &b)
      when :rep_nongreedy; _, *ps = pat; try_rep_generic(0, nil, ps, false, aa, pos, cap, &b)
      when :rep1_nongreedy; _, *ps = pat; try_rep_generic(1, nil, ps, false, aa, pos, cap, &b)
      when :opt; _, *ps = pat; try_rep_generic(0, 1, ps, true, aa, pos, cap, &b)
      when :opt_nongreedy; _, *ps = pat; try_rep_generic(0, 1, ps, false, aa, pos, cap, &b)
      when :grid; _, *arys = pat; try_grid(arys, aa, pos, cap, &b)
      when :capval; _, n = pat; try_capval(n, aa, pos, cap, &b)
      when :refval; _, n = pat; try_refval(n, aa, pos, cap, &b)
      when :tmp_pos; _, dx, dy, *ps = pat; try_tmp_pos(dx, dy, ps, aa, pos, cap, &b)
      when :push_pos; _, n = pat; try_push_pos(n, aa, pos, cap, &b)
      when :pop_pos; _, n = pat; try_pop_pos(n, aa, pos, cap, &b)
      else raise "unexpected: #{pat.inspect}"
      end
    else
      raise TypeError, "unexpected pattern: #{pat.inspect}"
    end
  end

  def try_rmove(dir, aa, pos, cap)
    x, y = pos
    case dir
    when :right then x += 1
    when :left then x -= 1
    when :up then y -= 1
    when :down then y += 1
    end
    lambda { yield [x,y], cap }
  end

  def try_lit(val, aa, pos, cap)
    x, y = pos
    if 0 <= y && y < aa.length &&
       0 <= x && x < aa[y].length &&
       aa[y][x] == val
      lambda { yield pos, cap }
    else
      nil
    end
  end

  def try_regexp(re, aa, pos, cap)
    x, y = pos
    if 0 <= y && y < aa.length &&
       0 <= x && x < aa[y].length &&
       re =~ aa[y][x]
      lambda { yield pos, cap }
    else
      nil
    end
  end

  # p1 p2 ...
  def try_cat(ps, aa, pos, cap, &block)
    if ps.empty?
      lambda { yield pos, cap }
    else
      pat, *rest = ps
      try(pat, aa, pos, cap) {|pos2, cap2|
        try_cat(rest, aa, pos2, cap2, &block)
      }
    end
  end

  # p1 | p2 | ...
  def try_alt(ps, aa, pos, cap, &block)
    ps.map {|pat|
      lambda { try(pat, aa, pos, cap, &block) }
    }
  end

  # (p1 p2 ...)*
  # (p1 p2 ...){min,}
  # (p1 p2 ...){min,max}
  # (p1 p2 ...)*?
  # (p1 p2 ...){min,}?
  # (p1 p2 ...){min,max}?
  def try_rep_generic(min, max, ps, greedy, aa, pos, cap, visited={}, &block)
    visited2 = visited.dup
    visited2[pos] = true
    result = []
    if min <= 0 && !greedy
      result << lambda { yield pos, cap }
    end
    if max.nil? || 0 < max
      min2 = min <= 0 ? 0 : min-1
      max2 = max ? max-1 : nil
      result << lambda {
        try_cat(ps, aa, pos, cap) {|pos2, cap2|
          if !visited2[pos2]
            try_rep_generic(min2, max2, ps, greedy, aa, pos2, cap2, visited2, &block)
          else
            nil
          end
        }
      }
    end
    if min <= 0 && greedy
      result << lambda { yield pos, cap }
    end
    result
  end

  def try_grid(arys, aa, pos, cap)
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
    try_grid_rect(newarys, aa, [pos[0]-start[0], pos[1]-start[1]], cap) {|pos2, cap2|
      lambda { yield [pos[0]-start[0]+goal[0], pos[1]-start[1]+goal[1]], cap2 }
    }
  end

  def try_grid_rect(arys, aa, pos, cap)
    if arys.empty?
      lambda { yield pos, cap }
    else
      ary, *rest = arys
      x, y = pos
      pos1 = [x, y+1]
      try_grid_row(ary, aa, pos, cap) {|pos2, cap2|
        try_grid_rect(rest, aa, pos1, cap2) {|pos3, cap3|
          lambda { yield pos, cap3 }
        }
      }
    end
  end

  def try_grid_row(ary, aa, pos, cap)
    if ary.empty?
      lambda { yield pos, cap }
    else
      pat, *rest = ary
      x, y = pos
      pos1 = [x+1, y]
      try(pat, aa, pos, cap) {|pos2, cap2|
        try_grid_row(rest, aa, pos1, cap2) {|pos3, cap3|
          lambda { yield pos, cap3 }
        }
      }
    end
  end

  def try_capval(n, aa, pos, cap)
    x, y = pos
    if 0 <= y && y < aa.length &&
       0 <= x && x < aa[y].length &&
      cap2 = cap.dup
      val = aa[y][x]
    else
      val = nil
    end
    cap2[n] = val
    lambda { yield pos, cap2 }
  end

  def try_refval(n, aa, pos, cap)
    x, y = pos
    if 0 <= y && y < aa.length &&
       0 <= x && x < aa[y].length &&
      cap2 = cap.dup
      val = aa[y][x]
    else
      val = nil
    end
    if val == cap[n]
      lambda { yield pos, cap2 }
    else
      nil
    end
  end

  def try_tmp_pos(dx, dy, ps, aa, pos, cap, &b)
    x, y = pos
    try_cat(ps, aa, [x+dx, y+dy], cap) {|pos2, cap2|
      lambda { yield pos, cap2 }
    }
  end

  def try_push_pos(n, aa, pos, cap, &b)
    cap2 = cap.dup
    cap2[n] ||= []
    cap2[n] += [pos]
    lambda { yield pos, cap2 }
  end

  def try_pop_pos(n, aa, pos, cap, &b)
    ary = cap[n]
    raise TypeError, "array expected: #{ary.inspect} (#{n.inspect})" unless Array === ary
    raise TypeError, "empty array (#{n.inspect})" if ary.empty?
    pos2 = ary.last
    raise TypeError, "array expected: #{pos2.inspect} (#{n.inspect})" unless Array === pos2
    raise TypeError, "two-element array expected: #{pos2.inspect} (#{n.inspect})" if pos2.length != 2
    raise TypeError, "integer elements expected: #{pos2.inspect} (#{n.inspect})" unless pos2.all? {|v| Integer === v }
    cap2 = cap.dup
    cap2[n] = ary[0...-1]
    lambda { yield pos2, cap2 }
  end
end
