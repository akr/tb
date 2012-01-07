# lib/tb/fieldset.rb - Tb::FieldSet class
#
# Copyright (C) 2011-2012 Tanaka Akira  <akr@fsij.org>
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

class Tb::FieldSet
  def self.normalize(header)
    Tb::FieldSet.new(*header).header
  end

  def initialize(*fs)
    @header = []
    @field2index = {}
    fs.each {|f| add_field(f) }
  end
  attr_reader :header

  def add_field(hint)
    hint = '1' if hint.nil? || hint == ''
    while @field2index[hint]
      case hint
      when /\A[1-9][0-9]*\z/
        hint = (hint.to_i + 1).to_s
      when /\([1-9][0-9]*\)\z/
        hint = hint.sub(/\(([1-9][0-9]*)\)\z/) { "(#{$1.to_i + 1})" }
      else
        hint = "#{hint}(2)"
      end
    end
    @field2index[hint] = @header.length
    @header << hint
    hint
  end
  private :add_field

  def index_from_field_ex(f)
    i = @field2index[f]
    return i if !i.nil?
    if /\A[1-9][0-9]*\z/ !~ f
      raise ArgumentError, "unexpected field name: #{f.inspect}"
    end
    while true
      if add_field(nil) == f
        return @header.length-1
      end
    end
  end

  def index_from_field(f)
    i = @field2index[f]
    if i.nil?
      raise ArgumentError, "unexpected field name: #{f.inspect}"
    end
    i
  end

  def field_from_index_ex(i)
    raise ArgumentError, "negative index: #{i}" if i < 0
    until i < @header.length
      add_field(nil)
    end
    @header[i]
  end

  def field_from_index(i)
    raise ArgumentError, "negative index: #{i}" if i < 0
    f = @header[i]
    if f.nil?
      raise ArgumentError, "index too big: #{i}"
    end
    f
  end

  def length
    @header.length
  end
end
