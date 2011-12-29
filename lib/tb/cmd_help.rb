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

Tb::Cmd.subcommands << 'help'

def (Tb::Cmd).usage_list_subcommands
  with_output {|f|
    f.print <<'End'
Usage:
End
    Tb::Cmd.subcommands.each {|subcommand|
      f.puts "  " + self.subcommand_send("op", subcommand).banner.sub(/\AUsage: /, '')
    }
  }
end

def (Tb::Cmd).op_help
  op = OptionParser.new
  op.banner = 'Usage: tb help [OPTS] [SUBCOMMAND]'
  define_common_option(op, "hvo", "--no-pager")
  op
end

Tb::Cmd.def_vhelp('help', <<'End')
Example:

  tb -h                 : list subcommands
  tb help               : list subcommands

  tb cat -h             : succinct help of "cat" subcommand
  tb help cat           : succinct help of "cat" subcommand
  tb cat -hh            : verbose help of "cat" subcommand
  tb help -h cat        : verbose help of "cat" subcommand

  tb help -h            : succinct help of "help" subcommand
  tb help help          : succinct help of "help" subcommand
  tb help -hh           : verbose help of "help" subcommand
  tb help -h help       : verbose help of "help" subcommand
End

def (Tb::Cmd).exit_if_help(subcommand)
  if 0 < Tb::Cmd.opt_help
    show_help(subcommand)
    exit
  end
end

def (Tb::Cmd).show_help(subcommand)
  if Tb::Cmd.subcommands.include?(subcommand)
    with_output {|f|
      f.puts self.subcommand_send("op", subcommand)
      if 2 <= Tb::Cmd.opt_help && Tb::Cmd.verbose_help[subcommand]
        f.puts
        f.puts Tb::Cmd.verbose_help[subcommand]
      end
    }
    true
  else
    err "unexpected subcommand: #{subcommand.inspect}"
  end
end

def (Tb::Cmd).main_help(argv)
  op_help.parse!(argv)
  if argv.empty?
    if Tb::Cmd.opt_help == 0
      usage_list_subcommands
      return true
    else
      argv.unshift 'help'
      Tb::Cmd.opt_help -= 1
    end
  end
  Tb::Cmd.opt_help += 1
  subcommand = argv.shift
  exit_if_help(subcommand)
end
