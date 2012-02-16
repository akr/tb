# lib/tb/ex_enumerable.rb - extensions for Enumerable
#
# Copyright (C) 2010-2012 Tanaka Akira  <akr@fsij.org>
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

module Enumerable
  # :call-seq:
  #   enum.tb_categorize(ksel1, ksel2, ..., vsel, [opts])
  #   enum.tb_categorize(ksel1, ksel2, ..., vsel, [opts]) {|ks, vs| ... }
  #
  # categorizes the elements in _enum_ and returns a hash.
  # This method assumes multiple elements for a category.
  #
  # +tb_categorize+ takes one or more key selectors,
  # one value selector and
  # an optional option hash.
  # It also takes an optional block.
  #
  # The selectors specify how to extract a value from an element in _enum_.
  #
  # The key selectors, _kselN_, are used to extract hash keys from an element.
  # If two or more key selectors are specified, the result hash will be nested.
  #
  # The value selector, _vsel_, is used for the values of innermost hashes.
  # By default, all values extracted by _vsel_ from the elements which
  # key selectors extracts same value are composed as an array.
  # The array is set to the values of the innermost hashes.
  # This behavior can be customized by the options: :seed, :op and :update.
  #
  #   a = [{:fruit => "banana", :color => "yellow", :taste => "sweet", :price => 100},
  #        {:fruit => "melon", :color => "green", :taste => "sweet", :price => 300},
  #        {:fruit => "grapefruit", :color => "yellow", :taste => "tart", :price => 200}]
  #   p a.tb_categorize(:color, :fruit)
  #   #=> {"yellow"=>["banana", "grapefruit"], "green"=>["melon"]}
  #   p a.tb_categorize(:taste, :fruit)
  #   #=> {"sweet"=>["banana", "melon"], "tart"=>["grapefruit"]}
  #   p a.tb_categorize(:taste, :color, :fruit)
  #   #=> {"sweet"=>{"yellow"=>["banana"], "green"=>["melon"]}, "tart"=>{"yellow"=>["grapefruit"]}}
  #   p a.tb_categorize(:taste, :color)
  #   #=> {"sweet"=>["yellow", "green"], "tart"=>["yellow"]}
  #
  # In the above example, :fruit, :color and :taste is specified as selectors.
  # There are several types of selectors as follows:
  #
  # - object with +call+ method (procedure, etc.): extracts a value from the element by calling the procedure with the element as an argument.
  # - array of selectors: make an array which contains the values extracted by the selectors.
  # - other object: extracts a value from the element using +[]+ method as +element[selector]+.
  #
  # So the selector :fruit extracts the value from the element
  # {:fruit => "banana", :color => "yellow", :taste => "sweet", :price => 100}
  # as {...}[:fruit].
  #
  #   p a.tb_categorize(lambda {|elt| elt[:fruit][4] }, :fruit)
  #   #=> {"n"=>["banana", "melon"], "e"=>["grapefruit"]}
  #
  # When the key selectors returns same key for two or or more elements,
  # corresponding values extracted by the value selector are combined.
  # By default, all values are collected as an array.
  # :seed, :op and :update option in the option hash customizes this behavior.
  # :seed option and :op option is similar to Enumerable#inject.
  # :seed option specifies an initial value.
  # (If :seed option is not given, the first value for each category is treated as an initial value.)
  # :op option specifies a procedure to combine a seed and an element into a next seed.
  # :update option is same as :op option except it takes three arguments instead of two:
  # keys, seed and element.
  # +to_proc+ method is used to convert :op and :update option to a procedure.
  # So a symbol can be used for them.
  #
  #   # count categorized elements.
  #   p a.tb_categorize(:color, lambda {|e| 1 }, :op=>:+)
  #   #=> {"yellow"=>2, "green"=>1}
  #
  #   p a.tb_categorize(:color, :fruit, :seed=>"", :op=>:+)
  #   #=> {"yellow"=>"bananagrapefruit", "green"=>"melon"}
  #
  # The default behavior, collecting all values as an array, is implemented as follows.
  #   :seed => nil
  #   :update => {|ks, s, v| !s ? [v] : (s << v) }
  #
  # :op and :update option are disjoint.
  # ArgumentError is raised if both are specified.
  #
  # The block for +tb_categorize+ method converts combined values to final innermost hash values.
  #
  #   p a.tb_categorize(:color, :fruit) {|ks, vs| vs.join(",") }
  #   #=> {"yellow"=>"banana,grapefruit", "green"=>"melon"}
  #
  #   # calculates the average price for fruits of each color.
  #   p a.tb_categorize(:color, :price) {|ks, vs| vs.inject(0.0, &:+) / vs.length }
  #   #=> {"yellow"=>150.0, "green"=>300.0}
  #
  def tb_categorize(*args, &reduce_proc)
    opts = args.last.kind_of?(Hash) ? args.pop : {}
    if args.length < 2
      raise ArgumentError, "needs 2 or more arguments without option hash (but #{args.length})"
    end
    value_selector = tb_cat_selector_proc(args.pop)
    key_selectors = args.map {|a| tb_cat_selector_proc(a) }
    has_seed = opts.has_key? :seed
    seed_value = opts[:seed]
    if opts.has_key?(:update) && opts.has_key?(:op)
      raise ArgumentError, "both :op and :update option specified"
    elsif opts.has_key? :update
      update_proc = opts[:update].to_proc
    elsif opts.has_key? :op
      op_proc = opts[:op].to_proc
      update_proc = lambda {|ks, s, v| op_proc.call(s, v) }
    else
      has_seed = true
      seed_value = nil
      update_proc = lambda {|ks, s, v| !s ? [v] : (s << v) }
    end
    result = {}
    each {|*elts|
      elt = elts.length <= 1 ? elts[0] : elts
      ks = key_selectors.map {|ksel| ksel.call(elt) }
      v = value_selector.call(elt)
      h = result
      0.upto(ks.length-2) {|i|
        k = ks[i]
        h[k] = {} if !h.has_key?(k)
        h = h[k]
      }
      lastk = ks.last
      if !h.has_key?(lastk)
        if has_seed
          h[lastk] = update_proc.call(ks, seed_value, v)
        else
          h[lastk] = v
        end
      else
        h[lastk] = update_proc.call(ks, h[lastk], v)
      end
    }
    if reduce_proc
      tb_cat_reduce(result, [], key_selectors.length-1, reduce_proc)
    end
    result
  end

  def tb_cat_selector_proc(selector)
    if selector.respond_to?(:call)
      selector
    elsif selector.respond_to? :to_ary
      selector_procs = selector.to_ary.map {|sel| tb_cat_selector_proc(sel) }
      lambda {|elt| selector_procs.map {|selproc| selproc.call(elt) } }
    else
      lambda {|elt| elt[selector] }
    end
  end
  private :tb_cat_selector_proc

  def tb_cat_reduce(hash, ks, nestlevel, reduce_proc)
    if nestlevel.zero?
      hash.each {|k, v|
        ks << k
        begin
          hash[k] = reduce_proc.call(ks.dup, v)
        ensure
          ks.pop
        end
      }
    else
      hash.each {|k, h|
        ks << k
        begin
          tb_cat_reduce(h, ks, nestlevel-1, reduce_proc)
        ensure
          ks.pop
        end
      }
    end
  end
  private :tb_cat_reduce

  # :call-seq:
  #   enum.tb_unique_categorize(ksel1, ksel2, ..., vsel, [opts]) -> hash
  #   enum.tb_unique_categorize(ksel1, ksel2, ..., vsel, [opts]) {|s, v| ... } -> hash
  #
  # categorizes the elements in _enum_ and returns a hash.
  # This method assumes one element for a category by default.
  #
  # +tb_unique_categorize+ takes one or more key selectors,
  # one value selector and
  # an optional option hash.
  # It also takes an optional block.
  #
  # The selectors specify how to extract a value from an element in _enum_.
  # See Enumerable#tb_categorize for details of selectors.
  #
  # The key selectors, _kselN_, are used to extract hash keys from an element.
  # If two or more key selectors are specified, the result hash will be nested.
  #
  # The value selector, _vsel_, is used for the values of innermost hashes.
  # By default, this method assumes the key selectors categorizes elements in enum uniquely.
  # If the key selectors generates same keys for two or more elements, ArgumentError is raised.
  # This behavior can be customized by :seed option and the block.
  #
  #   a = [{:fruit => "banana", :color => "yellow", :taste => "sweet", :price => 100},
  #        {:fruit => "melon", :color => "green", :taste => "sweet", :price => 300},
  #        {:fruit => "grapefruit", :color => "yellow", :taste => "tart", :price => 200}]
  #   p a.tb_unique_categorize(:fruit, :price)
  #   #=> {"banana"=>100, "melon"=>300, "grapefruit"=>200}
  #
  #   p a.tb_unique_categorize(:color, :price)
  #   # ArgumentError
  #
  # If the block is given, it is used for combining values in a category.
  # The arguments for the block is a seed and the value extracted by _vsel_.
  # The return value of the block is used as the next seed.
  # :seed option specifies the initial seed.
  # If :seed is not given, the first value for each category is used for the seed.
  #
  #   p a.tb_unique_categorize(:taste, :price) {|s, v| s + v }
  #   #=> {"sweet"=>400, "tart"=>200}
  #
  #   p a.tb_unique_categorize(:color, :price) {|s, v| s + v }
  #   #=> {"yellow"=>300, "green"=>300}
  #
  def tb_unique_categorize(*args, &update_proc)
    opts = args.last.kind_of?(Hash) ? args.pop.dup : {}
    if update_proc
      opts[:update] = lambda {|ks, s, v| update_proc.call(s, v) }
    else
      seed = Object.new
      opts[:seed] = seed
      opts[:update] = lambda {|ks, s, v|
        if s.equal? seed
          v
        else
          raise ArgumentError, "ambiguous key: #{ks.map {|k| k.inspect }.join(',')}"
        end
      }
    end
    tb_categorize(*(args + [opts]))
  end

  # :call-seq:
  #   enum.tb_category_count(ksel1, ksel2, ...)
  #
  # counts elements in _enum_ for each category defined by the key selectors.
  #
  #   a = [{:fruit => "banana", :color => "yellow", :taste => "sweet", :price => 100},
  #        {:fruit => "melon", :color => "green", :taste => "sweet", :price => 300},
  #        {:fruit => "grapefruit", :color => "yellow", :taste => "tart", :price => 200}]
  #
  #   p a.tb_category_count(:color)
  #   #=> {"yellow"=>2, "green"=>1}
  #
  #   p a.tb_category_count(:taste)
  #   #=> {"sweet"=>2, "tart"=>1}
  #
  #   p a.tb_category_count(:taste, :color)
  #   #=> {"sweet"=>{"yellow"=>1, "green"=>1}, "tart"=>{"yellow"=>1}}
  #
  # The selectors specify how to extract a value from an element in _enum_.
  # See Enumerable#tb_categorize for details of selectors.
  #
  def tb_category_count(*args)
    tb_categorize(*(args + [lambda {|e| 1 }, {:update => lambda {|ks, s, v| s + v }}]))
  end

  def dump_objsfile(title, tempfile)
    tempfile.flush
    path = tempfile
    a = []
    open(path) {|f|
      until f.eof?
        pair = Marshal.load(f)
        a << (pair ? pair.last : :sep)
      end
    }
    puts "#{title}: #{a.inspect}"
  end
  private :dump_objsfile

  # :call-seq:
  #   enum.extsort_by(options={}) {|value| cmpvalue }
  #
  # +extsort_by+ returns an enumerator which yields elements in the receiver in sorted order.
  # The block defines the order which cmpvalue is ascending.
  #
  # options:
  #   :map : a procedure to convert the element.  It is applied after cmpvalue is obtained.  (default: nil)
  #   :unique : a procedure to merge two values which has same cmpvalue. (default: nil)
  #   :memsize : limit in-memory sorting size in bytes (default: 10000000)
  #
  # If :unique option is given, it is used to merge
  # elements which have same cmpvalue.
  # The procedure should take two elements and return one.
  # The procedure should be associative.  (f(x,f(y,z)) = f(f(x,y),z))
  #
  def extsort_by(opts={}, &cmpvalue_from)
    mapfunc = opts[:map]
    opts = opts.dup
    opts[:map] = mapfunc ?
      lambda {|v| Marshal.dump(mapfunc.call(v)) } : 
      lambda {|v| Marshal.dump(v) }
    uniqfunc = opts[:unique]
    if uniqfunc
      opts[:unique] = lambda {|x, y| Marshal.dump(uniqfunc.call(Marshal.load(x), Marshal.load(y))) }
    end
    reducefunc = opts[:unique]
    mapfunc2 = opts[:map] || lambda {|v| v }
    self.lazy_map {|v|
      [cmpvalue_from.call(v), mapfunc2.call(v)]
    }.send(:extsort_internal0, reducefunc, opts).lazy_map {|k, d|
      Marshal.load(d)
    }
  end

  # :call-seq:
  #   enum.extsort_reduce(op, [opts]) {|element| [key, val| }
  #
  def extsort_reduce(op, opts={}, &key_val_proc)
    lazy_map(&key_val_proc).send(:extsort_internal0, op, opts)
  end

  def extsort_internal0(reducefunc, opts={})
    if reducefunc.is_a? Symbol
      reducefunc = reducefunc.to_proc
    end
    opts = opts.dup
    opts[:memsize] ||= 10000000
    Enumerator.new {|y|
      extsort_internal1(reducefunc, opts, y)
    }
  end
  private :extsort_internal0

  def extsort_internal1(reducefunc, opts, y)
    tmp1 = Tempfile.new("tbsortA")
    tmp2 = Tempfile.new("tbsortB")
    extsort_first_split(tmp1, tmp2, reducefunc, opts)
    if tmp1.size == 0 && tmp2.size == 0
      return Enumerator.new {|_| }
    end
    tmp3 = Tempfile.new("tbsortC")
    tmp4 = Tempfile.new("tbsortD")
    while tmp2.size != 0
      #dump_objsfile(:tmp1, tmp1)
      #dump_objsfile(:tmp2, tmp2)
      #dump_objsfile(:tmp3, tmp3)
      #dump_objsfile(:tmp4, tmp4)
      extsort_merge(tmp1, tmp2, tmp3, tmp4, reducefunc, opts)
      tmp1.rewind
      tmp1.truncate(0)
      tmp2.rewind
      tmp2.truncate(0)
      tmp1, tmp2, tmp3, tmp4 = tmp3, tmp4, tmp1, tmp2
    end
      #dump_objsfile(:tmp1, tmp1)
      #dump_objsfile(:tmp2, tmp2)
      #dump_objsfile(:tmp3, tmp3)
      #dump_objsfile(:tmp4, tmp4)
    extsort_yield(tmp1, y)
  ensure
    tmp1.close(true) if tmp1
    tmp2.close(true) if tmp2
    tmp3.close(true) if tmp3
    tmp4.close(true) if tmp4
  end
  private :extsort_internal1

  def extsort_first_split(tmp1, tmp2, reducefunc, opts)
    prevobj_cv = nil
    prevobj_dumped = nil
    tmp_current, tmp_another = tmp1, tmp2
    buf = {}
    buf_size = 0
    buf_mode = true
    self.each_with_index {|v, i|
      obj_cv, obj = v
      #p [obj, obj_cv]
      #p [prevobj_cv, buf_mode, obj, obj_cv]
      if buf_mode
        dumped = Marshal.dump([obj_cv, obj])
        ary = (buf[obj_cv] ||= [])
        ary << [obj_cv, i, dumped]
        buf_size += dumped.size
        if reducefunc && ary.length == 2
          obj1_cv, i1, dumped1 = ary[0]
          _, _, dumped2 = ary[1]
          _, obj1 = Marshal.load(dumped1)
          _, obj2 = Marshal.load(dumped2)
          obju = reducefunc.call(obj1, obj2)
          buf[obj1_cv] = [[obj1_cv, i1, Marshal.dump([obj1_cv, obju])]]
        end
        if opts[:memsize] < buf_size
          buf_keys = buf.keys.sort
          (0...(buf_keys.length-1)).each {|j|
            cv = buf_keys[j]
            buf[cv].each {|_, _, d|
              tmp_current.write d
            }
          }
          ary = buf[buf_keys.last]
          (0...(ary.length-1)).each {|j|
            _, _, d = ary[j]
            tmp_current.write d
          }
          prevobj_cv, _, prevobj_dumped = ary[-1]
          buf.clear
          buf_mode = false
        end
      elsif (cmp = (prevobj_cv <=> obj_cv)) == 0 && reducefunc
        _, obj1 = Marshal.load(prevobj_dumped)
        obj2 = obj
        obju = reducefunc.call(obj1, obj2)
        prevobj_dumped = Marshal.dump([prevobj_cv, obju])
      elsif cmp <= 0
        tmp_current.write prevobj_dumped
        prevobj_dumped = Marshal.dump([obj_cv, obj])
        prevobj_cv = obj_cv
      else
        tmp_current.write prevobj_dumped
        Marshal.dump(nil, tmp_current)
        dumped = Marshal.dump([obj_cv, obj])
        buf = { obj_cv => [[obj_cv, i, dumped]] }
        buf_size = dumped.size
        buf_mode = true
        tmp_current, tmp_another = tmp_another, tmp_current
        prevobj_cv = nil
        prevobj_dumped = nil
      end
    }
    if buf_mode
      buf_keys = buf.keys.sort
      buf_keys.each {|cv|
        buf[cv].each {|_, _, d|
          tmp_current.write d
        }
      }
    else
      tmp_current.write prevobj_dumped
    end
    if !buf_mode || !buf.empty?
      Marshal.dump(nil, tmp_current)
    end
  end
  private :extsort_first_split

  def extsort_merge(src1, src2, dst1, dst2, reducefunc, opts)
    src1.rewind
    src2.rewind
    obj1_cv, obj1 = obj1_pair = Marshal.load(src1)
    obj2_cv, obj2 = obj2_pair = Marshal.load(src2)
    prefer1 = true
    while true
      cmp = obj1_cv <=> obj2_cv
      if prefer1 ? cmp > 0 : cmp >= 0
        obj1_pair, obj1_cv, obj1, src1, obj2_pair, obj2_cv, obj2, src2 =
          obj2_pair, obj2_cv, obj2, src2, obj1_pair, obj1_cv, obj1, src1
        prefer1 = !prefer1
      end
      if reducefunc && cmp == 0
        Marshal.dump([obj1_cv, reducefunc.call(obj1, obj2)], dst1)
        obj1_cv, obj1 = obj1_pair = Marshal.load(src1)
        obj2_cv, obj2 = obj2_pair = Marshal.load(src2)
        if obj1_pair && !obj2_pair
          obj1_pair, obj1_cv, obj1, src1, obj2_pair, obj2_cv, obj2, src2 =
            obj2_pair, obj2_cv, obj2, src2, obj1_pair, obj1_cv, obj1, src1
          prefer1 = !prefer1
        end
      else
        Marshal.dump([obj1_cv, obj1], dst1)
        obj1_cv, obj1 = obj1_pair = Marshal.load(src1)
      end
      if !obj1_pair
        while obj2_pair
          Marshal.dump(obj2_pair, dst1)
          obj2_pair = Marshal.load(src2)
        end
        Marshal.dump(nil, dst1)
        dst1, dst2 = dst2, dst1
        break if src1.eof?
        break if src2.eof?
        obj1_cv, obj1 = obj1_pair = Marshal.load(src1)
        obj2_cv, obj2 = obj2_pair = Marshal.load(src2)
      end
    end
    if !src1.eof?
      restsrc = src1
    elsif !src2.eof?
      restsrc = src2
    else
      return
    end
    until restsrc.eof?
      restobj_pair = Marshal.load(restsrc)
      Marshal.dump(restobj_pair, dst1)
    end
  end
  private :extsort_merge

  def extsort_yield(tmp1, y)
    tmp1.rewind
    while true
      pair = Marshal.load(tmp1)
      break if !pair
      y.yield pair
    end
  end
  private :extsort_yield

  # splits self by _boundary_p_ which is called with adjacent two elements.
  #
  # _before_group_ is called before each group with the first element.
  # _after_group_ is called after each group with the last element.
  # _body_ is called for each element.
  #
  def each_group_element(boundary_p, before_group, body, after_group)
    prev = nil
    first = true
    self.each {|curr|
      if first
        before_group.call(curr)
        body.call(curr)
        prev = curr
        first = false
      elsif boundary_p.call(prev, curr)
        after_group.call(prev)
        before_group.call(curr)
        body.call(curr)
        prev = curr
      else
        body.call(curr)
        prev = curr
      end
    }
    if !first
      after_group.call(prev)
    end
  end

  # splits self by _representative_ which is called with a element.
  #
  # _before_group_ is called before each group with the first element.
  # _after_group_ is called after each group with the last element.
  # _body_ is called for each element.
  #
  def each_group_element_by(representative, before_group, body, after_group)
    detect_group_by(before_group, after_group, &representative).each(&body)
  end

  # creates an enumerator which yields same as self but
  # given block and procedures are called between each element for grouping.
  #
  # The block is called for each element to define groups.
  # A group is conecutive elements which the block returns same value.
  #
  # _before_group_ is called before each group with the first element.
  #
  # _after_group_ is called after each group with the last element.
  #
  # _before_group_ and _after_group_ are optional.
  #
  # The grouping mechanism is called as "control break" in some cluture such as COBOL.
  #
  # Consecutive even numbers and odd numbers can be grouped as follows.
  #
  #   [1,3,5,4,8].detect_group_by(
  #     lambda {|v| puts "start" },
  #     lambda {|v| puts "end" }) {|v| v.even? }.each {|x| p x }
  #   #=> start
  #   #   1
  #   #   3
  #   #   5
  #   #   end
  #   #   start
  #   #   4
  #   #   8
  #   #   end
  #
  # Note that +detect_group_by+ can be cascaeded but
  # It doesn't work as nested manner.
  #
  #   (0..9).detect_group_by( 
  #     lambda {|v| print "[" },
  #     lambda {|v| print "]" }) {|v|
  #     v.even?
  #   }.detect_group_by(
  #     lambda {|v| print "(" },
  #     lambda {|v| print ")" }) {|v|
  #     (v/2).even?
  #   }.each {|x| print x }
  #   #=> [(0][1][)(2][3][)(4][5][)(6][7][)(8][9])
  #
  # Consider +detect_nested_group_by+ for nested groups.
  #
  def detect_group_by(before_group=nil, after_group=nil, &representative_proc)
    detect_nested_group_by([[representative_proc, before_group, after_group]])
  end

  # creates an enumerator which yields same as self but
  # nested groups detected by _group_specs_
  #
  # _group_specs_ is an array of three procedures arrays as:
  #
  #   [[representative_proc1, before_proc1, after_proc1],
  #    [representative_proc2, before_proc2, after_proc2],
  #    ...]
  #
  # _representative_proc1_ splits elements as groups.
  # The group is defined as consecutive elements which _representative_proc1_ returns same value.
  # _before_proc1_ is called before the each groups.
  # _after_proc1_ is called after the each groups.
  #
  # Subsequent procedures, _representative_proc2_, _before_proc2_, _after_proc2_, ..., are
  # used to split elements in the above groups.
  #
  #   (0..9).detect_nested_group_by(
  #     [[lambda {|v| (v/2).even? },
  #       lambda {|v| print "(" },
  #       lambda {|v| print ")" }],
  #      [lambda {|v| v.even? },
  #       lambda {|v| print "[" },
  #       lambda {|v| print "]" }]]).each {|x| print x }
  #   #=> ([0][1])([2][3])([4][5])([6][7])([8][9])
  #
  def detect_nested_group_by(group_specs)
    Enumerator.new {|y|
      first = true
      prev_reps = nil
      prev = nil
      self.each {|*curr|
        reps = group_specs.map {|representative_proc, _, _|
          representative_proc.call(*curr)
        }
        if first
          first = false
          group_specs.each {|_, before_proc, _|
            before_proc.call(*curr) if before_proc
          }
        else
          different_index = (0...group_specs.length).find {|i| prev_reps[i] != reps[i] }
          if different_index
            (group_specs.length-1).downto(different_index) {|i|
              _, _, after_proc = group_specs[i]
              after_proc.call(*prev) if after_proc
            }
            different_index.upto(group_specs.length-1) {|i|
              _, before_proc, _ = group_specs[i]
              before_proc.call(*curr) if before_proc
            }
          end
        end
        y.yield(*curr)
        prev_reps = reps
        prev = curr
      }
      if !first
        (group_specs.length-1).downto(0) {|i|
          _, _, after_proc = group_specs[i]
          after_proc.call(*prev) if after_proc
        }
      end
    }
  end

  def lazy_map
    Enumerator.new {|y|
      self.each {|*vs|
        y.yield(yield(*vs))
      }
    }
  end
end
