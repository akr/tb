# lib/table/enumerable.rb - extensions for Enumerable
#
# Copyright (C) 2010 Tanaka Akira  <akr@fsij.org>
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
  #   enum.categorize(ksel1, ksel2, ..., vsel, [opts])
  #   enum.categorize(ksel1, ksel2, ..., vsel, [opts]) {|ks, vs| ... }
  #
  # categorizes the elements in _enum_ and returns a hash.
  # This method assumes multiple elements for a category.
  #
  # +categorize+ takes one or more key selectors,
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
  #   p a.categorize(:color, :fruit)
  #   #=> {"yellow"=>["banana", "grapefruit"], "green"=>["melon"]}
  #   p a.categorize(:taste, :fruit)
  #   #=> {"sweet"=>["banana", "melon"], "tart"=>["grapefruit"]}
  #   p a.categorize(:taste, :color, :fruit)
  #   #=> {"sweet"=>{"yellow"=>["banana"], "green"=>["melon"]}, "tart"=>{"yellow"=>["grapefruit"]}}
  #   p a.categorize(:taste, :color)
  #   #=> {"sweet"=>["yellow", "green"], "tart"=>["yellow"]}
  #
  # In the above example, :fruit, :color and :taste is specified as selectors.
  # There are several types of selectors as follows:
  #
  # - object with +call+ method (procedure, etc.): extracts a value from the element by calling the procedure with the element as an argument.
  # - true: always generates true.
  # - :_index : the index of the element.
  # - :_element : the element itself.
  # - array of selectors: make an array which contains the values extracted by the selectors.
  # - other object: extracts a value from the element using +[]+ method as +element[selector]+.
  #
  # So the selector :fruit extracts the value from the element
  # {:fruit => "banana", :color => "yellow", :taste => "sweet", :price => 100}
  # as {...}[:fruit].
  #
  #   p a.categorize(lambda {|elt| elt[:fruit][4] }, :fruit)
  #   #=> {"n"=>["banana", "melon"], "e"=>["grapefruit"]}
  #
  #   p a.categorize(:color, true)
  #   #=> {"yellow"=>[true, true], "green"=>[true]}
  #
  #   p a.categorize(:color, :_index)
  #   #=> {"yellow"=>[0, 2], "green"=>[1]}
  #
  #   p a.categorize(:color, :_element)
  #   #=> {"yellow"=>[{:fruit=>"banana", :color=>"yellow", :taste=>"sweet", :price=>100},
  #   #               {:fruit=>"grapefruit", :color=>"yellow", :taste=>"tart", :price=>200}],
  #   #    "green"=>[{:fruit=>"melon", :color=>"green", :taste=>"sweet", :price=>300}]}
  #
  #   p a.categorize(:color, :_element)
  #   #=> {"yellow"=>[{:fruit=>"banana", :color=>"yellow", :taste=>"sweet", :price=>100},
  #   #               {:fruit=>"grapefruit", :color=>"yellow", :taste=>"tart", :price=>200}],
  #   #    "green"=>[{:fruit=>"melon", :color=>"green", :taste=>"sweet", :price=>300}]}
  #
  #   p a.categorize(:color, [:fruit, :taste, :_index])
  #   #=> {"yellow"=>[["banana", "sweet", 0], ["grapefruit", "tart", 2]],
  #   #    "green"=>[["melon", "sweet", 1]]}
  #
  #   p a.categorize(true, :fruit)
  #   #=> {true=>["banana", "melon", "grapefruit"]}
  #
  # When the key selectors returns same key for two or or more elements,
  # corresponding values extracted by the value selector are combined.
  # By default, all values are collected as an array.
  # :seed, :op and :update option in the option hash customizes this behavior.
  # :seed option and :op option is similar to Enumerable#inject.
  # :seed option specifies an initial value.
  # :op option specifies a procedure to combine a seed and an element into a next seed.
  # :update option is same as :op option except it takes three arguments instead of two:
  # keys, seed and element.
  # +to_proc+ method is used to convert :op and :update option to a procedure.
  # So a symbol can be used for them.
  #
  #   # count categorized elements.
  #   p a.categorize(:color, true, :seed=>0, :op=>lambda {|s, v| s+1 })
  #   #=> {"yellow"=>2, "green"=>1}
  #
  #   p a.categorize(:color, :fruit, :seed=>"", :op=>:+)
  #   #=> {"yellow"=>"bananagrapefruit", "green"=>"melon"}
  #
  # The default behavior, collecting all values as an array, is implemented as follows.
  #   :seed => nil
  #   :update => {|ks, s, v| !s ? [v] : (s << v) }
  #
  # :op and :update option are disjoint.
  # ArgumentError is raised if both are specified.
  #
  # The block for +categorize+ method converts combined values to final hash values.
  #
  #   p a.categorize(:color, :fruit) {|ks, vs| vs.join(",") }
  #   #=> {"yellow"=>"banana,grapefruit", "green"=>"melon"}
  #
  #   # calculates the average price for fruits of each color.
  #   p a.categorize(:color, :price) {|ks, vs| vs.inject(0.0, &:+) / vs.length }
  #   #=> {"yellow"=>150.0, "green"=>300.0}
  #
  def categorize(*args, &reduce_proc)
    opts = args.last.kind_of?(Hash) ? args.pop : {}
    if args.length < 2
      raise ArgumentError, "needs 2 or more arguments without option (but #{args.length})"
    end
    index_cell = [0]
    value_selector = cat_selector_proc(args.pop, index_cell)
    key_selectors = args.map {|a| cat_selector_proc(a, index_cell) }
    seed_value = opts[:seed]
    if opts.include?(:update) && opts.include?(:op)
      raise ArgumentError, "both :op and :update option specified"
    elsif opts.include? :update
      update_proc = opts[:update].to_proc
    elsif opts.include? :op
      op_proc = opts[:op].to_proc
      update_proc = lambda {|ks, s, v| op_proc.call(s, v) }
    else
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
        h[k] = {} if !h.include?(k)
        h = h[k]
      }
      lastk = ks.last
      if !h.include?(lastk)
        h[lastk] = update_proc.call(ks, seed_value, v)
      else
        h[lastk] = update_proc.call(ks, h[lastk], v)
      end
      index_cell[0] += 1
    }
    if reduce_proc
      cat_reduce(result, [], key_selectors.length-1, reduce_proc)
    end
    result
  end

  def cat_selector_proc(selector, index_cell)
    if selector == true
      lambda {|elt| true }
    elsif selector == :_element
      lambda {|elt| elt }
    elsif selector == :_index
      lambda {|elt| index_cell[0] }
    elsif selector.respond_to?(:call)
      selector
    elsif selector.respond_to? :to_ary
      selector_procs = selector.to_ary.map {|sel| cat_selector_proc(sel, index_cell) }
      lambda {|elt| selector_procs.map {|selproc| selproc.call(elt) } }
    else
      lambda {|elt| elt[selector] }
    end
  end
  private :cat_selector_proc

  def cat_reduce(hash, ks, nestlevel, reduce_proc)
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
          cat_reduce(h, ks, nestlevel-1, reduce_proc)
        ensure
          ks.pop
        end
      }
    end
  end
  private :cat_reduce

  # :call-seq:
  #   enum.unique_categorize(ksel1, ksel2, ..., vsel, [opts]) -> hash
  #   enum.unique_categorize(ksel1, ksel2, ..., vsel, [opts]) {|s, v| ... } -> hash
  #
  # categorizes the elements in _enum_ and returns a hash.
  # This method assumes one element for a category by default.
  #
  # +unique_categorize+ takes one or more key selectors,
  # one value selector and
  # an optional option hash.
  # It also takes an optional block.
  #
  # The selectors specify how to extract a value from an element in _enum_.
  # See Enumerable#categorize for details of selectors.
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
  #   p a.unique_categorize(:fruit, :price)
  #   #=> {"banana"=>100, "melon"=>300, "grapefruit"=>200}
  #
  #   p a.unique_categorize(:color, :price)
  #   # ArgumentError
  #
  # If the block is given, it is called for each value in _enum_.
  # The arguments for the block is a seed and the value extracted by _vsel_.
  # The initial seed is nil unless :seed option is specified.
  # The return value of the block is used as the next seed.
  #
  #   p a.unique_categorize(:taste, :price) {|s, v| !s ? v : s + v }
  #   #=> {"sweet"=>400, "tart"=>200}
  #
  #   p a.unique_categorize(:color, :price, :seed=>0) {|s, v| s + v }
  #   #=> {"yellow"=>300, "green"=>300}
  #
  def unique_categorize(*args, &update_proc)
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
    categorize(*(args + [opts]))
  end

  # :call-seq:
  #   enum.category_count(ksel1, ksel2, ...)
  #
  # counts elements in _enum_ for each category defined by the key selectors.
  #
  #   a = [{:fruit => "banana", :color => "yellow", :taste => "sweet", :price => 100},
  #        {:fruit => "melon", :color => "green", :taste => "sweet", :price => 300},
  #        {:fruit => "grapefruit", :color => "yellow", :taste => "tart", :price => 200}]
  #
  #   p a.category_count(:color)
  #   #=> {"yellow"=>2, "green"=>1}
  #
  #   p a.category_count(:taste)
  #   #=> {"sweet"=>2, "tart"=>1}
  #
  #   p a.category_count(:taste, :color)
  #   #=> {"sweet"=>{"yellow"=>1, "green"=>1}, "tart"=>{"yellow"=>1}}
  #
  # The selectors specify how to extract a value from an element in _enum_.
  # See Enumerable#categorize for details of selectors.
  #
  def category_count(*args)
    unique_categorize(*(args + [true])) {|s, v| !s ? 1 : s+1 }
  end

end
