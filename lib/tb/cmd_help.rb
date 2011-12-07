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

def (Tb::Cmd).usage
  with_output {|f|
    f.print <<'End'
Usage:
End
    Tb::Cmd.subcommands.each {|subcommand|
      f.puts "  " + self.send("op_#{subcommand}").banner.sub(/\AUsage: /, '')
    }
  }
end

def (Tb::Cmd).op_help
  op = OptionParser.new
  op.banner = 'Usage: tb help [OPTS] [SUBCOMMAND]'
  define_default_option(op, "hvo", "--no-pager")
  op
end

def (Tb::Cmd).show_help(subcommand)
  if Tb::Cmd.subcommands.include?(subcommand)
    with_output {|f|
      f.puts self.send("op_#{subcommand}")
      if 2 <= Tb::Cmd.opt_help && Tb::Cmd.verbose_help[subcommand]
        f.puts
        f.puts Tb::Cmd.verbose_help[subcommand]
      end
    }
    true
  elsif subcommand == nil
    usage
    true
  else
    err "unexpected subcommand: #{subcommand.inspect}"
  end
end

def (Tb::Cmd).main_help(argv)
  Tb::Cmd.opt_help += 1
  op_help.parse!(argv)
  if argv.empty? && 2 <= Tb::Cmd.opt_help then
    argv.unshift 'help'
  end
  subcommand = argv.shift
  show_help(subcommand)
end
