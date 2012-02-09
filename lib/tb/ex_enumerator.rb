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

module Tb::ExEnumerator
  # :call-seq:
  #
  #   Tb::ExEnumerator.merge_sorted(enumerator1, ...) {|key, enumerator1_or_nil, ...| ... }
  #
  # iterates over enumerators specified by arguments.
  #
  # The enumerators should yield an array which first element is a comparable key.
  # The enumerators should be sorted by the key in ascending order.
  #
  # Tb::Enumerator.merge_sorted iterates keys in all of the enumerators.
  # It yields an array which contains a key and enumerators which has the key.
  # The array contains nil if corresponding enumerator don't have the key. 
  #
  # The block may or may not use +next+ method to advance enumerators.
  # Anyway Tb::Enumerator.merge_sorted advance enumerators until peeked key is
  # greater than the yielded key.
  #
  # If a enumerator has multiple elements with same key,
  # the block can read them using +next+ method.
  # +peek+ method should also be used to determine the key of the next element has
  # the current key or not.
  # Be careful to not consume extra elements with different key.
  #
  def (Tb::ExEnumerator).merge_sorted(*enumerators) # :yields: [key, enumerator1_or_nil, ...]
    while true
      has_min = false
      min = nil
      min_enumerators = []
      enumerators.each {|kpe|
        begin
          key, = kpe.peek
        rescue StopIteration
          min_enumerators << nil
          next
        end
        if !has_min
          has_min = true
          min = key
          min_enumerators << kpe
        else
          cmp = key <=> min
          if cmp < 0
            min_enumerators.fill(nil)
            min_enumerators << kpe
            min = key
          elsif cmp == 0
            min_enumerators << kpe
          else
            min_enumerators << nil
          end
        end
      }
      if !has_min
        return
      end
      yield [min, *min_enumerators]
      min_enumerators.each {|kpe|
        next if !kpe
        while true
          begin
            key, = kpe.peek
          rescue StopIteration
            break
          end
          if (min <=> key) < 0
            break
          end
          kpe.next
        end
      }
    end
  end
end
