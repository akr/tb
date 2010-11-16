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
  #   table.categorize(ksel1, ksel2, ..., vsel, [opts])
  #   table.categorize(ksel1, ksel2, ..., vsel, [opts]) {|ks, vs| ... }
  #
  # creates a hash from the table.
  #
  # +categorize+ takes one or more key selectors,
  # one value selector,
  # optional option hash.
  # It also takes an optional block.
  #
  # The selectors specify how to extract a value from a record in the table.
  # The key selectors are used to extract hash keys from a record.
  # If two or more key selectors are specified, the result hash will be nested.
  # The value selector is used to extract a hash value from a record.
  #
  #   t = Table.new(%w[fruit color taste],
  #                 %w[banana yellow sweet],
  #                 %w[melon green sweet],
  #                 %w[grapefruit yellow tart])
  #   p t.categorize("color", "fruit")
  #   #=> {"yellow"=>["banana", "grapefruit"], "green"=>["melon"]}
  #   p t.categorize("taste", "fruit")
  #   #=> {"sweet"=>["banana", "melon"], "tart"=>["grapefruit"]}
  #   p t.categorize("taste", "color", "fruit")
  #   #=> {"sweet"=>{"yellow"=>["banana"], "green"=>["melon"]}, "tart"=>{"yellow"=>["grapefruit"]}}
  #   p t.categorize("taste", "color")         
  #   #=> {"sweet"=>["yellow", "green"], "tart"=>["yellow"]}
  #
  # In the above example, "fruit", "color" and "taste" is specified as selectors.
  # A field name of the table is a valid selector.
  # There are more types of selectors as follows:
  #
  # - field name: extracts the field value of the record.
  # - procedure: extracts a value from the record by calling the procedure with the record as an argument.
  # - true: always generates true.
  # - :_index : the index of the record. (This can be differ from record id.)
  # - :_element : the record itself.
  # - array of selectors: make an array which contains the values extracted by the selectors.
  #
  #   p t.categorize(lambda {|rec| rec["fruit"][4] }, "fruit")
  #   #=> {"n"=>["banana", "melon"], "e"=>["grapefruit"]}
  #
  #   p t.categorize("color", true)                           
  #   #=> {"yellow"=>[true, true], "green"=>[true]}
  #
  #   p t.categorize("color", :_index)
  #   #=> {"yellow"=>[0, 2], "green"=>[1]}
  #
  #   p t.categorize("color", :_element) 
  #   #=> {"yellow"=>[#<Table::Record: "_recordid"=>0, "fruit"=>"banana", "color"=>"yellow", "taste"=>"sweet">,
  #   #               #<Table::Record: "_recordid"=>2, "fruit"=>"grapefruit", "color"=>"yellow", "taste"=>"tart">],
  #   #    "green"=>[#<Table::Record: "_recordid"=>1, "fruit"=>"melon", "color"=>"green", "taste"=>"sweet">]}
  #
  #   p t.categorize("color", ["fruit", "taste", :_index])
  #   #=> {"yellow"=>[["banana", "sweet", 0], ["grapefruit", "tart", 2]],
  #        "green"=>[["melon", "sweet", 1]]}
  #
  #   p t.categorize(true, "fruit")                       
  #   #=> {true=>["banana", "melon", "grapefruit"]}
  #
  # When the key selectors returns same key for two or or more records,
  # corresponding values extracted by the value selector is combined.
  # By default, all values are collected as an array.
  # :seed, :op and :update option in the option hash customizes this behavior.
  # :seed option and :op option is similar to Enumerable#inject.
  # :seed option specifies an initial value.
  # :op option specifies a procedure which takes two arguments, accumlated value and next record, and it returns the next accumlated value.
  # :update option is same as :op option except it takes three arguments:
  # keys, accumlated value and next record.
  # +to_proc+ method is used to convert :op and :update option to a procedure.
  # So a symbol can be used for them.
  #
  #   # count categorized records.
  #   p t.categorize("color", true, :seed=>0, :op=>lambda {|s,v| s+1 })
  #   #=> {"yellow"=>2, "green"=>1}
  #
  #   p t.categorize("color", "fruit", :seed=>"", :op=>:+)
  #   {"yellow"=>"bananagrapefruit", "green"=>"melon"}
  #
  # The default behavior, collecting all values as an array, is implemented as follows.
  #   :seed => nil
  #   :update => {|ks, s, v| !s ? [v] : (s << v) }
  #
  # :op and :update option is disjoint.
  # ArgumentError is raised if both are specified.
  #
  # The block for +categorize+ method converts combined values to final hash values.
  #
  #   p t.categorize("color", "fruit") {|ks, vs| vs.join(",") }
  #   #=> {"yellow"=>"banana,grapefruit", "green"=>"melon"}
  #
  #   # calculates the average price for fruits of each color.
  #   t = Table.new(%w[fruit color taste price],
  #                 ["banana", "yellow", "sweet", 100],
  #                 ["melon", "green", "sweet", 300],
  #                 ["grapefruit", "yellow", "tart", 200])
  #   p t.categorize("color", "price") {|ks, vs| vs.inject(0.0, &:+) / vs.length } 
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
    each {|elt|
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
    elsif Symbol === selector && /\A_/ =~ selector.to_s
      raise ArgumentError, "unexpected reserved selector: #{selector.inspect}"
    elsif selector.respond_to? :to_proc
      selector.to_proc
    elsif selector.respond_to? :to_ary
      selector_procs = selector.to_ary.map {|sel| cat_selector_proc(sel, index_cell) }
      lambda {|elt| selector_procs.map {|selproc| selproc.call(elt) } }
    else
      f = check_field(selector)
      lambda {|elt| elt[f] }
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
  #   table.unique_categorize(ksel1, ksel2, ..., vsel, [opts]) -> hash
  #   table.unique_categorize(ksel1, ksel2, ..., vsel, [opts]) {|s, v| ... } -> hash
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
  #   table.category_count(ksel1, ksel2, ...)
  def category_count(*args)
    unique_categorize(*(args + [true])) {|seed, value| !seed ? 1 : seed+1 }
  end

end
