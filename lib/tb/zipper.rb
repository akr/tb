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

class Tb::Zipper
  def initialize(ops)
    @ops = ops
  end

  def start(ary)
    if ary.length != @ops.length
      raise ArgumentError, "expect an array which lengths are #{@ops.length}"
    end
    @ops.map.with_index {|op, i|
      op.start(ary[i])
    }
  end

  def call(ary1, ary2)
    if ary1.length != @ops.length || ary2.length != @ops.length
      raise ArgumentError, "expect an array of arrays which lengths are #{@ops.length}"
    end
    @ops.zip(ary1, ary2).map {|op, v1, v2|
      op.call(v1, v2)
    }
  end

  def aggregate(ary)
    if ary.length != @ops.length
      raise ArgumentError, "expect an array which lengths are #{@ops.length}"
    end
    @ops.map.with_index {|op, i|
      op.aggregate(ary[i])
    }
  end
end
