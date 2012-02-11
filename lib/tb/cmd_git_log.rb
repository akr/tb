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

Tb::Cmd.subcommands << 'git-log'

Tb::Cmd.default_option[:opt_git_log_git_command] = nil
Tb::Cmd.default_option[:opt_git_log_debug_input] = nil
Tb::Cmd.default_option[:opt_git_log_debug_output] = nil

def (Tb::Cmd).op_git_log
  op = OptionParser.new
  op.banner = "Usage: tb git-log [OPTS] [GIT-DIR ...]\n" +
    "Show the GIT log as a table."
  define_common_option(op, "hNod", "--no-pager", '--debug')
  op.def_option('--git-command COMMAND', 'specify the git command (default: git)') {|command| Tb::Cmd.opt_git_log_git_command = command }
  op.def_option('--debug-git-log-output FILE', 'store the raw output of git-log (for debug)') {|filename| Tb::Cmd.opt_git_log_debug_output = filename }
  op.def_option('--debug-git-log-input FILE', 'use the file as output of git-log (for debug)') {|filename| Tb::Cmd.opt_git_log_debug_input = filename }
  op
end

Tb::Cmd::GIT_LOG_FORMAT_SPEC = [
  %w[commit %H],
  %w[tree %T],
  %w[parents %P],
  %w[author-name %an],
  %w[author-email %ae],
  %w[author-date %ai],
  %w[committer-name %cn],
  %w[committer-email %ce],
  %w[committer-date %ci],
  %w[ref-names %d],
  %w[encoding %e],
  %w[subject %s],
  %w[body %b],
  %w[raw-body %B],
  %w[notes %N],
  %w[reflog-selector %gD],
  %w[reflog-subject %gs],
]

Tb::Cmd::GIT_LOG_PRETTY_FORMAT = 'format:%x01commit-separator%x01%n' +
  Tb::Cmd::GIT_LOG_FORMAT_SPEC.map {|k, v| "#{k}:%w(0,0,1)#{v}%w(0,0,0)%n" }.join('') +
  "end-commit%n"

Tb::Cmd::GIT_LOG_HEADER = Tb::Cmd::GIT_LOG_FORMAT_SPEC.map {|k, v| k } + ['files']

def (Tb::Cmd).git_log_with_git_log(dir)
  if Tb::Cmd.opt_git_log_debug_input
    File.open(Tb::Cmd.opt_git_log_debug_input) {|f|
      yield f
    }
  else
    git = Tb::Cmd.opt_git_log_git_command || 'git'
    # depends Ruby 1.9.
    command = [
      git,
      'log',
      "--pretty=#{Tb::Cmd::GIT_LOG_PRETTY_FORMAT}",
      '--decorate=full',
        '--raw',
        '--abbrev=40',
        '.',
        {:chdir=>dir}
    ]
    $stderr.puts "git command line: #{command.inspect}" if 1 <= Tb::Cmd.opt_debug
    if Tb::Cmd.opt_git_log_debug_output
      command.last[:out] = Tb::Cmd.opt_git_log_debug_output
      system(*command)
      File.open(Tb::Cmd.opt_git_log_debug_output) {|f|
        yield f
      }
    else
      IO.popen(command) {|f|
        yield f
      }
    end
  end
end

def (Tb::Cmd).git_log_unescape_filename(filename)
  if /\A"/ =~ filename
    $'.chomp('"').gsub(/\\((\d\d\d)|[abtnvfr"\\])/) {
      str = $1
      if $2
        [str.to_i(8)].pack("C")
      else
        case str
        when 'a' then "\a"
        when 'b' then "\b"
        when 't' then "\t"
        when 'n' then "\n"
        when 'v' then "\v"
        when 'f' then "\f"
        when 'r' then "\r"
        when '"' then '"'
        when '\\' then "\\"
        else
          warn "unexpected escape: #{str.inspect}"
        end
      end
    }
  else
    filename
  end
end

def (Tb::Cmd).git_log_parse_commit(commit_info, files)
  commit_info = commit_info.split(/\n(?=[a-z])/)
  Tb.csv_stream_output(files_csv="") {|gen|
    gen << %w[mode1 mode2 hash1 hash2 status filename]
    files.split(/\n/).each {|file_line|
      if /\A:(\d+) (\d+) ([0-9a-f]+) ([0-9a-f]+) (\S+)\t(.+)\z/ !~ file_line
        warn "unexpected git-log output: #{file_line.inspect}"
        next
      end
      mode1, mode2, hash1, hash2, status, filename = $1, $2, $3, $4, $5, $6
      filename = git_log_unescape_filename(filename)
      gen << [mode1, mode2, hash1, hash2, status, filename]
    }
  }
  h = {}
  commit_info.each {|s|
    if /:/ !~ s
      warn "unexpected git-log output: #{s.inspect}"
      next
    end
    k = $`
    v = $'.gsub(/\n /, "\n") # remove indent generated by %w(0,0,1)
    case k
    when /\A(?:author-date|committer-date)/
      v = v.sub(/\A(\d+-\d\d-\d\d) (\d\d:\d\d:\d\d) ([-+]\d\d\d\d)\z/, '\1T\2\3')
    when /\Aparents\z/
      v = ['parent', *v.split(/ /)].map {|c| c + "\n" }.join("")
    when /\Aref-names\z/
      v = v.strip.gsub(/\A\(|\)\z/, '')
      v = ['ref-name', *v.split(/, /)].map {|c| c + "\n" }.join("")
    end
    h[k] = v
  }
  h['files'] = files_csv
  h
end

def (Tb::Cmd).git_log_each_commit(f)
  while chunk = f.gets("\x01commit-separator\x01\n")
    chunk.chomp!("\x01commit-separator\x01\n")
    next if chunk.empty? # beginning of the output
    if /\nend-commit\n/ !~ chunk
      warn "unexpected git-log output: #{chunk.inspect}"
      next
    end
    commit_info, files = $`, $'
    files.sub!(/\A\n/, '')
    h = git_log_parse_commit(commit_info, files)
    yield h
  end

end

def (Tb::Cmd).main_git_log(argv)
  op_git_log.parse!(argv)
  exit_if_help('git-log')
  argv = ['.'] if argv.empty?
  er = Tb::Enumerator.new {|y|
    y.set_header Tb::Cmd::GIT_LOG_HEADER
    argv.each {|dir|
      git_log_with_git_log(dir) {|f|
        f.set_encoding("ASCII-8BIT") if f.respond_to? :set_encoding
        git_log_each_commit(f) {|h|
          y.yield h
        }
      }
    }
  }
  output_tbenum(er)
end

