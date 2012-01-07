# Copyright (C) 2012 Tanaka Akira  <akr@fsij.org>
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 
#  1. Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above
#     copyright notice, this list of conditions and the following
#     disclaimer in the documentation and/or other materials provided
#     with the distribution.
#  3. The name of the author may not be used to endorse or promote
#     products derived from this software without specific prior
#     written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS
# OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
# GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
# EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require 'weakref'

class Tb::Pairs
  def self.get_key2index(keys)
    wm = (Thread.current[:tb_pairs_frozen_info] ||= {})
    w = wm[keys]
    if w
      begin
        return w.__getobj__
      rescue WeakRef::RefError
      end
    end
    keys = keys.dup.freeze
    k2i = {}
    keys.each_with_index {|k, i|
      k2i[k] = i
    }
    k2i.freeze
    info = [keys, k2i]
    w = WeakRef.new(info)
    wm[keys.dup] = w
    info
  end

  include Enumerable

  def initialize(pairs)
    keys = []
    vals = []
    pairs.each {|k, v|
      keys << k
      vals << v
    }
    keys, k2i = Tb::Pairs.get_key2index(keys)
    @keys = keys
    @k2i = k2i
    @vals = vals
  end

  def pretty_print(q) # :nodoc:
    q.object_group(self) {
      fs = @keys
      unless fs.empty?
        q.text ':'
        q.breakable
      end
      q.seplist(fs, nil, :each) {|f|
        v = self[f]
        q.group {
          q.pp f
          q.text '=>'
          q.group(1) {
            q.breakable ''
            q.pp v
          }
        }
      }
    }
  end
  alias inspect pretty_print_inspect # :nodoc:

  def [](key)
    i = @k2i.fetch(key) {
      return nil
    }
    @vals[i]
  end

  def each
    @keys.each_index {|i|
      yield [@keys[i], @vals[i]]
    }
  end

  def each_key(&b)
    @keys.each(&b)
  end

  def each_value(&b)
    @vals.each(&b)
  end

  def to_h
    h = {}
    @keys.each_with_index {|k, i|
      v = @vals[i]
      h[k] = v
    }
    h
  end

  def empty?
    @keys.empty?
  end

  if defined?(::KeyError)
    KeyError = ::KeyError
  else
    KeyError = IndexError
  end

  def fetch(key, *rest)
    if 1 < rest.length
      raise ArgumentError, "wrong number of arguments (#{1+rest.length} for 1..2)"
    elsif block_given?
      i = @k2i.fetch(key) {
        return yield(key)
      }
      @vals[i]
    elsif !rest.empty?
      i = @k2i.fetch(key) {
        return rest[0]
      }
      @vals[i]
    else
      i = @k2i.fetch(key)
      @vals[i]
    end
  end

  def has_key?(key)
    @k2i.has_key?(key)
  end
  alias include? has_key?
  alias key? has_key?
  alias member? has_key?

  def has_value?(value)
    i = index(value)
    if i
      true
    else
      false
    end
  end
  alias value? has_value?

  def index(value)
    @vals.each_with_index {|v, i|
      if v == value
        return @keys[i]
      end
    }
    nil
  end
  alias key index

  def invert
    Tb::Pairs.new(self.map {|k, v| [v, k] })
  end

  def keys
    @keys.dup
  end

  def length
    @keys.length
  end
  alias size length

  def merge(other)
    pairs = []
    self.each {|k, v|
      if other.has_key? k
        if block_given?
          v = yield(k, v, other[k])
        else
          v = other[k]
        end
      end
      pairs << [k, v]
    }
    other.each {|k, v|
      next if self.has_key? k
      pairs << [k, v]
    }
    Tb::Pairs.new(pairs)
  end

  def reject
    pairs = []
    self.each {|kv|
      unless yield kv
        pairs << kv
      end
    }
    Tb::Pairs.new(pairs)
  end

  def values
    @vals.dup
  end

  def values_at(*keys)
    keys.map {|k|
      self[k]
    }
  end
end
