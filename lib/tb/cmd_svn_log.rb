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

require 'rexml/document'

Tb::Cmd.subcommands << 'svn-log'

Tb::Cmd.default_option[:opt_svn_log_svn_command] = nil
Tb::Cmd.default_option[:opt_svn_log_xml] = nil

def (Tb::Cmd).op_svn_log
  op = OptionParser.new
  op.banner = "Usage: tb svn-log [OPTS] -- [SVN-LOG-ARGS]\n" +
    "Show the SVN log as a table."
  define_common_option(op, "hNo", "--no-pager")
  op.def_option('--svn-command COMMAND', 'specify the svn command (default: svn)') {|command| Tb::Cmd.opt_svn_log_svn_command = command }
  op.def_option('--svn-log-xml FILE', 'specify the result svn log --xml') {|filename| Tb::Cmd.opt_svn_log_xml = filename }
  op
end

Tb::Cmd.def_vhelp('svn-log', <<'End')
Example:

  % tb svn-log
  % tb svn-log -- -v
  % tb svn-log -- -v http://svn.ruby-lang.org/repos/ruby/trunk
End

class Tb::Cmd::SVNLOGListener
  def initialize(y)
    @y = y
    @header = nil
    @elt_stack = []
    @att_stack = []
    @log = nil
  end

  def tag_start(name, attrs)
    @elt_stack.push name
    @att_stack.push attrs
    case @elt_stack
    when %w[log logentry]
      @log = { 'rev' => attrs['revision'] }
    when %w[log logentry paths]
      @log['paths'] = []
    when %w[log logentry paths path]
      @log['paths'] << { 'kind' => attrs['kind'], 'action' => attrs['action'] }
    end
  end

  def text(text)
    case @elt_stack
    when %w[log logentry author]
      @log['author'] = text
    when %w[log logentry date]
      @log['date'] = text
    when %w[log logentry paths path]
      @log['paths'].last['path'] = text
    when %w[log logentry msg]
      @log['msg'] = text
    end
  end

  def tag_end(name)
    case @elt_stack
    when %w[log logentry]
      if !@header
        if @log['paths']
          @header = %w[rev author date msg kind action path]
        else
          @header = %w[rev author date msg]
        end
        @y.set_header @header
      end
      if @log['paths']
        @log['paths'].each {|h|
          assoc = @log.to_a.reject {|f, v| !%w[rev author date msg].include?(f) }
          assoc += h.to_a.reject {|f, v| !%w[kind action path].include?(f) }
          @y.yield Tb::Pairs.new(assoc)
        }
      else
        assoc = @log.to_a.reject {|f, v| !%w[rev author date msg].include?(f) }
        @y.yield Tb::Pairs.new(assoc)
      end
      @log = nil
    end
    @elt_stack.pop
    @att_stack.pop
  end

  def instruction(name, instruction)
  end

  def comment(comment)
  end

  def doctype(name, pub_sys, long_name, uri)
  end

  def doctype_end
  end

  def attlistdecl(element_name, attributes, raw_content)
  end

  def elementdecl(content)
  end

  def entitydecl(content)
  end

  def notationdecl(content)
  end

  def entity(content)
  end

  def cdata(content)
    # I guess svn doesn't use CDATA...
  end

  def xmldecl(version, encoding, standalone)
  end
end

def (Tb::Cmd).svn_log_with_svn_log(argv)
  if Tb::Cmd.opt_svn_log_xml
    File.open(Tb::Cmd.opt_svn_log_xml) {|f|
      yield f
    }
  else
    svn = Tb::Cmd.opt_svn_log_svn_command || 'svn'
    IO.popen([svn, 'log', '--xml', *argv]) {|f|
      yield f
    }
  end
end

def (Tb::Cmd).main_svn_log(argv)
  op_svn_log.parse!(argv)
  exit_if_help('svn-log')
  er = Tb::Enumerator.new {|y|
    svn_log_with_svn_log(argv) {|f|
      listener = Tb::Cmd::SVNLOGListener.new(y)
      REXML::Parsers::StreamParser.new(f, listener).parse
    }
  }
  with_output {|out|
    er.write_to_csv(out, !Tb::Cmd.opt_N)
  }
end

