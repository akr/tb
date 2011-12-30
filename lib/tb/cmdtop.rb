# Copyright (C) 2011 Tanaka Akira  <akr@fsij.org>
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

require 'tb'
require 'optparse'
require 'pathname'
require 'etc'
require 'time'
require 'enumerator'
require 'tb/pager'
require 'tb/cmdutil'
require 'tb/cmd_help'
require 'tb/cmd_to_csv'
require 'tb/cmd_to_tsv'
require 'tb/cmd_to_pnm'
require 'tb/cmd_to_json'
require 'tb/cmd_to_yaml'
require 'tb/cmd_to_pp'
require 'tb/cmd_grep'
require 'tb/cmd_gsub'
require 'tb/cmd_sort'
require 'tb/cmd_cut'
require 'tb/cmd_rename'
require 'tb/cmd_newfield'
require 'tb/cmd_cat'
require 'tb/cmd_join'
require 'tb/cmd_consecutive'
require 'tb/cmd_group'
require 'tb/cmd_cross'
require 'tb/cmd_unnest'
require 'tb/cmd_nest'
require 'tb/cmd_shape'
require 'tb/cmd_mheader'
require 'tb/cmd_crop'
require 'tb/cmd_ls'
require 'tb/cmd_svn_log'
require 'tb/cmd_git_log'
require 'tb/cmdmain'

Tb::Cmd.init_option
