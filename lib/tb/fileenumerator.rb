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

module Enumerable
  # creates a Tb::FileEnumerator object.
  #
  def to_fileenumerator
    Tb::FileEnumerator.new_tempfile {|gen|
      self.each {|*objs|
        gen.call(*objs)
      }
    }
  end
end

# Tb::FileEnumerator is an enumerator backed by a temporally file.
#
# An instance of Tb::FileEnumerator can be used just once,
# except if Tb::FileEnumerator#use is explicitly used.
#
# After the use, the temporally file is removed.
# If the object is not used, the temporally file is removed by GC
# as usual Tempfile object.
#
class Tb::FileEnumerator
  include Enumerable

  class Builder
    def initialize(klass)
      @klass = klass
      @tempfile = Tempfile.new("tb")
      @tempfile.binmode
    end

    def gen(*objs)
      Marshal.dump(objs, @tempfile)
    end

    def new
      @tempfile.close
      @klass.new(
        lambda { open(@tempfile.path, "rb") },
        lambda { @tempfile.close(true) })
    end
  end

  def self.builder
    Builder.new(Tb::FileEnumerator)
  end

  def self.new_tempfile
    gen, new = self.gen_new
    yield gen
    new.call
  end

  def self.gen_new
    builder = self.builder
    return builder.method(:gen), builder.method(:new)
  end

  def initialize(open_func, close_func)
    @use_count = 0
    @open_func = open_func
    @close_func = close_func
  end

  # delay removing the tempfile until the given block is finished.
  def use
    if !@open_func
      raise ArgumentError, "FileEnumerator reused."
    end
    @use_count += 1
    yield
    @use_count -= 1
    if @use_count == 0
      @close_func.call
      @open_func = @close_func = nil
    end
  end

  def each
    self.use {
      begin
        io = @open_func.call
        while true
          objs = Marshal.load(io)
          yield(*objs)
        end
      rescue EOFError
      ensure
        io.close 
      end
    }
  end
end

module Tb::Enum
  # creates a Tb::FileHeaderEnumerator object.
  #
  def to_fileenumerator
    hbuilder = Tb::FileHeaderEnumerator.builder
    header_proc = lambda {|header|
      if header
        hbuilder.header.concat(header - hbuilder.header)
      end
    }
    self.header_and_each(header_proc) {|pairs|
      hbuilder.gen(pairs)
    }
    hbuilder.new
  end
end

class Tb::FileHeaderEnumerator < Tb::FileEnumerator
  include Tb::Enum

  class HBuilder
    def initialize(klass)
      @klass = klass
      @tempfile = Tempfile.new("tb")
      @tempfile.binmode
      @header = []
    end
    attr_reader :header

    def gen(*objs)
      @header |= objs[0].keys
      Marshal.dump(objs, @tempfile)
    end

    def new
      @tempfile.close
      @klass.new(
        @header,
        lambda { open(@tempfile.path, "rb") },
        lambda { @tempfile.close(true) })
    end
  end

  def self.builder
    HBuilder.new(Tb::FileHeaderEnumerator)
  end

  def self.gen_new
    hgen = self.builder
    return hgen.method(:gen), hgen.method(:new)
  end

  def initialize(header, open_func, close_func)
    super open_func, close_func
    @header = header
  end

  def header_and_each(header_proc)
    self.use {
      header_proc.call(@header) if header_proc
      begin
        io = @open_func.call
        while true
          objs = Marshal.load(io)
          yield(*objs)
        end
      rescue EOFError
      ensure
        io.close 
      end
    }
  end

  def each(&block)
    header_and_each(nil, &block)
  end
end
