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

class Tb::Yielder
  def initialize(header_proc, base_yielder)
    @header_proc_called = false
    @header_proc = header_proc
    @base_yielder = base_yielder
  end
  attr_reader :header_proc_called

  def set_header(header)
    raise ArgumentError, "set_header called twice" if @header_proc_called
    @header_proc_called = true
    @header_proc.call(header) if @header_proc
  end

  def yield(*args)
    if !@header_proc_called
      set_header(nil)
    end
    @base_yielder.yield(*args)
  end
  alias << yield
end

class Tb::Enumerator < Enumerator
  include Tb::Enumerable

  def self.new(&enumerator_proc)
    super() {|y|
      header_proc = Thread.current[:tb_enumerator_header_proc]
      ty = Tb::Yielder.new(header_proc, y)
      enumerator_proc.call(ty)
      if !ty.header_proc_called
        header_proc.call(nil)
      end
    }
  end

  def each(&each_proc)
    header_and_each(nil, &each_proc)
  end

  def header_and_each(header_proc, &each_proc)
    old = Thread.current[:tb_enumerator_header_proc]
    begin
      Thread.current[:tb_enumerator_header_proc] = header_proc
      Enumerator.instance_method(:each).bind(self).call(&each_proc)
    ensure
      Thread.current[:tb_enumerator_header_proc] = old
    end
    nil
  end

end
