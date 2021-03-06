# lib/tb.rb - entry file for table library
#
# Copyright (C) 2010-2014 Tanaka Akira  <akr@fsij.org>
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

require 'tempfile'

module Tb
end

require 'pp'
require 'tb/enumerable'
require 'tb/enumerator'
require 'tb/func'
require 'tb/zipper'

require 'tb/headerreader'
require 'tb/headerwriter'

require 'tb/numericreader'
require 'tb/numericwriter'

require 'tb/hashreader'
require 'tb/hashwriter'

require 'tb/csv'
require 'tb/tsv'
require 'tb/ltsv'
require 'tb/pnm'
require 'tb/json'
require 'tb/ndjson'

require 'tb/ropen'
require 'tb/catreader'
require 'tb/search'
require 'tb/ex_enumerable'
require 'tb/ex_enumerator'
require 'tb/fileenumerator'
require 'tb/revcmp'
require 'tb/customcmp'
require 'tb/customeq'
