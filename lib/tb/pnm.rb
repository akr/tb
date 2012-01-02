# lib/tb/pnm.rb - tools for (very small) PNM images.
#
# Copyright (C) 2010-2011 Tanaka Akira  <akr@fsij.org>
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

class Tb
  # :call-seq:
  #   Tb.load_pnm(pnm_filename) -> tb
  #
  def Tb.load_pnm(pnm_filename)
    pnm_content = File.open(pnm_filename, "rb") {|f| f.read }
    Tb.parse_pnm(pnm_content)
  end

  # :call-seq:
  #   Tb.parse_pnm(pnm_content) -> tb
  #
  def Tb.parse_pnm(pnm_content)
    reader = PNMReader.new(pnm_content)
    header = reader.shift
    t = Tb.new(header)
    reader.each {|ary|
      t.insert_values header, ary
    }
    t
  end

  # :call-seq:
  #   Tb.pnm_stream_input(pnm_io) {|ary| ... }
  #
  def Tb.pnm_stream_input(pnm_io)
    pnm_io.binmode
    content = pnm_io.read
    PNMReader.new(content)
  end

  # practical only for (very) small images.
  class PNMReader
    WSP = /(?:[ \t\r\n]|\#[^\r\n]*[\r\n])+/

    def initialize(pnm_content)
      pnm_content.force_encoding("ASCII-8BIT") if pnm_content.respond_to? :force_encoding
      if /\A(P[63])(#{WSP})(\d+)(#{WSP})(\d+)(#{WSP})(\d+)[ \t\r\n]/on =~ pnm_content
        magic, wsp1, w, wsp2, h, wsp3, max, raster = $1, $2, $3.to_i, $4, $5.to_i, $6, $7.to_i, $'
        pixel_component = %w[R G B]
      elsif /\A(P[52])(#{WSP})(\d+)(#{WSP})(\d+)(#{WSP})(\d+)[ \t\r\n]/on =~ pnm_content
        magic, wsp1, w, wsp2, h, wsp3, max, raster = $1, $2, $3.to_i, $4, $5.to_i, $6, $7.to_i, $'
        pixel_component = %w[V]
      elsif /\A(P[41])(#{WSP})(\d+)(#{WSP})(\d+)[ \t\r\n]/on =~ pnm_content
        magic, wsp1, w, wsp2, h, raster = $1, $2, $3.to_i, $4, $5.to_i, $'
        wsp3 = nil
        max = 1
        pixel_component = %w[V]
      else
        raise ArgumentError, "not PNM format"
      end
      raise ArgumentError, "unsupported max value: #{max}" if 65535 < max

      @ary = [
        ['type', 'x', 'y', 'component', 'value'],
        ['meta', nil, nil, 'pnm_type', magic],
        ['meta', nil, nil, 'width', w],
        ['meta', nil, nil, 'height', h],
        ['meta', nil, nil, 'max', max]
      ]

      [wsp1, wsp2, wsp3].each {|wsp|
        next if !wsp
        wsp.scan(/\#([^\r\n]*)[\r\n]/) { @ary << ['meta', nil, nil, 'comment', $1] }
      }

      if /P[65]/ =~ magic # raw (binary) PPM/PGM
        if max < 0x100
          each_pixel_component = method(:raw_ppm_pgm_1byte_each_pixel_component)
        else
          each_pixel_component = method(:raw_ppm_pgm_2byte_each_pixel_component)
        end
      elsif /P4/ =~ magic # raw (binary) PBM
        each_pixel_component = make_raw_pbm_each_pixel_component(w)
      elsif /P[32]/ =~ magic # plain (ascii) PPM/PGM
        each_pixel_component = method(:plain_ppm_pgm_each_pixel_component)
      elsif /P1/ =~ magic # plain (ascii) PBM
        each_pixel_component = method(:plain_pbm_each_pixel_component)
      end
      n = w * h * pixel_component.length
      i = 0
      each_pixel_component.call(raster) {|value|
        break if i == n
        y, x = (i / pixel_component.length).divmod(w)
        c = pixel_component[i % pixel_component.length]
        @ary << ['pixel', x, y, c, value.to_f / max]
        i += 1
      }
      if i != n
        raise ArgumentError, "PNM raster data too short."
      end
    end

    def raw_ppm_pgm_1byte_each_pixel_component(raster, &b)
      raster.each_byte(&b)
    end

    def raw_ppm_pgm_2byte_each_pixel_component(raster)
      raster.enum_for(:each_byte).each_slice(2) {|byte1, byte2|
        word = byte1 * 0x100 + byte2
        yield word
      }
    end

    def plain_ppm_pgm_each_pixel_component(raster)
      raster.scan(/\d+/) { yield $&.to_i }
    end

    def plain_pbm_each_pixel_component(raster)
      raster.scan(/[01]/) { yield 1 - $&.to_i }
    end

    def make_raw_pbm_each_pixel_component(width)
      iter = Object.new
      iter.instance_variable_set(:@width, width)
      def iter.call(raster)
        numbytes = (@width + 7) / 8
        y = 0
        while true
          return if raster.size <= y * numbytes
          line = raster[y * numbytes, numbytes]
          x = 0
          while x < @width
            i, j = x.divmod(8)
            return if line.size <= i
            byte = line[x/8].ord
            yield 1 - ((byte >> (7-j)) & 1)
            x += 1
          end
          y += 1
        end
      end
      iter
    end

    def shift
      @ary.shift
    end

    def each
      while ary = self.shift
        yield ary
      end
      nil
    end

    def to_a
      result= []
      each {|ary| result << ary }
      result
    end

    def close
    end
  end

  # :call-seq:
  #   generate_pnm(out='')
  #
  def generate_pnm(out='')
    undefined_field = ['x', 'y', 'component', 'value'] - self.list_fields
    if !undefined_field.empty?
      raise ArgumentError, "field not defined: #{undefined_field.inspect[1...-1]}"
    end
    pnm_type = nil
    width = height = nil
    comments = []
    max_value = nil
    max_x = max_y = 0
    values = { 0.0 => true, 1.0 => true }
    components = {}
    self.each {|rec|
      case rec['component']
      when 'pnm_type'
        pnm_type = rec['value']
      when 'width'
        width = rec['value'].to_i
      when 'height'
        height = rec['value'].to_i
      when 'max'
        max_value = rec['value'].to_i
      when 'comment'
        comments << rec['value']
      when 'R', 'G', 'B', 'V'
        components[rec['component']] = true
        x = rec['x'].to_i
        y = rec['y'].to_i
        max_x = x if max_x < x
        max_y = y if max_y < y
        values[rec['value'].to_f] = true
      end

    }
    if !(components.keys - %w[V]).empty? &&
       !(components.keys - %w[R G B]).empty?
      raise ArgumentError, "inconsistent color component: #{components.keys.sort.inspect[1...-1]}"
    end
    case pnm_type
    when 'P1', 'P4' then raise ArgumentError, "unexpected compoenent for PBM: #{components.keys.sort.inspect[1...-1]}" if !(components.keys - %w[V]).empty?
    when 'P2', 'P5' then raise ArgumentError, "unexpected compoenent for PGM: #{components.keys.sort.inspect[1...-1]}" if !(components.keys - %w[V]).empty?
    when 'P3', 'P6' then raise ArgumentError, "unexpected compoenent for PPM: #{components.keys.sort.inspect[1...-1]}" if !(components.keys - %w[R G B]).empty?
    end
    comments.each {|c|
      if /[\r\n]/ =~ c
        raise ArgumentError, "comment cannot contain a newline: #{c.inspect}"
      end
    }
    if !width
      width = max_x + 1
    end
    if !height
      height = max_y + 1
    end
    if !max_value
      min_interval = 1.0
      values.keys.sort.each_cons(2) {|v1, v2|
        d = v2-v1
        min_interval = d if d < min_interval
      }
      if min_interval < 0.0039 # 1/255 = 0.00392156862745098...
        max_value = 0xffff
      elsif min_interval < 1.0 || !(components.keys & %w[R G B]).empty?
        max_value = 0xff
      else
        max_value = 1
      end
    end
    if pnm_type
      if !pnm_type.kind_of?(String) || /\AP[123456]\z/ !~ pnm_type
        raise ArgumentError, "unexpected PNM type: #{pnm_type.inspect}"
      end
    else
      if (components.keys - ['V']).empty?
        if max_value == 1
          pnm_type = 'P4' # PBM
        else
          pnm_type = 'P5' # PGM
        end
      else
        pnm_type = 'P6' # PPM
      end
    end
    header = "#{pnm_type}\n"
    comments.each {|c| header << '#' << c << "\n" }
    header << "#{width} #{height}\n"
    header << "#{max_value}\n" if /P[2536]/ =~ pnm_type
    if /P[14]/ =~ pnm_type # PBM
      max_value = 1
    end
    bytes_per_component = bytes_per_line = component_fmt = component_template = nil
    case pnm_type
    when 'P1' then bytes_per_component = 1; raster = '1' * (width * height)
    when 'P4' then bytes_per_line = (width + 7) / 8; raster = ["1"*width].pack("B*") * height
    when 'P2' then bytes_per_component = max_value.to_s.length+1; component_fmt = "%#{bytes_per_component}d"; raster = (component_fmt % 0) * (width * height)
    when 'P5' then bytes_per_component, component_template = max_value < 0x100 ? [1, 'C'] : [2, 'n']; raster = "\0" * (bytes_per_component * width * height)
    when 'P3' then bytes_per_component = max_value.to_s.length+1; component_fmt = "%#{bytes_per_component}d"; raster = (component_fmt % 0) * (3 * width * height)
    when 'P6' then bytes_per_component, component_template = max_value < 0x100 ? [1, 'C'] : [2, 'n']; raster = "\0" * (bytes_per_component * 3 * width * height)
    else
      raise
    end
    raster.force_encoding("ASCII-8BIT") if raster.respond_to? :force_encoding
    self.each {|rec|
      c = rec['component']
      next if /\A[RGBV]\z/ !~ c
      x = rec['x'].to_i
      y = rec['y'].to_i
      next if x < 0 || width <= x
      next if y < 0 || height <= y
      v = rec['value'].to_f
      if v < 0
        v = 0
      elsif 1 < v
        v = 1
      end
      case pnm_type
      when 'P1'
        v = v < 0.5 ? '1' : '0'
        raster[y * width + x] = v
      when 'P4'
        xhi, xlo = x.divmod(8)
        i = y * bytes_per_line + xhi
        byte = raster[i].ord
        if v < 0.5
          byte |= 0x80 >> xlo
        else
          byte &= 0xff7f >> xlo
        end
        raster[i] = [byte].pack("C")
      when 'P2'
        v = (v * max_value).round
        raster[(y * width + x) * bytes_per_component, bytes_per_component] = component_fmt % v
      when 'P5'
        v = (v * max_value).round
        raster[(y * width + x) * bytes_per_component, bytes_per_component] = [v].pack(component_template)
      when 'P3'
        v = (v * max_value).round
        i = (y * width + x) * 3
        if c == 'G' then i += 1
        elsif c == 'B' then i += 2
        end
        raster[i * bytes_per_component, bytes_per_component] = component_fmt % v
      when 'P6'
        v = (v * max_value).round
        i = (y * width + x) * 3
        if c == 'G' then i += 1
        elsif c == 'B' then i += 2
        end
        raster[i * bytes_per_component, bytes_per_component] = [v].pack(component_template)
      else
        raise
      end
    }
    if pnm_type == 'P1'
      raster.gsub!(/[01]{#{width}}/, "\\&\n")
      if 70 < width
        raster.gsub!(/[01]{70}/, "\\&\n")
      end
      raster << "\n" if /\n\z/ !~ raster
    elsif /P[23]/ =~ pnm_type
      components_per_line = /P2/ =~ pnm_type ? width : 3 * width
      raster.gsub!(/  +/, ' ')
      raster.gsub!(/( \d+){#{components_per_line}}/, "\\&\n")
      raster.gsub!(/(\A|\n) +/, '\1')
      raster.gsub!(/.{71,}\n/) {
        $&.gsub(/(.{1,69})[ \n]/, "\\1\n")
      }
      raster << "\n" if /\n\z/ !~ raster
    end
    out << (header+raster)
  end
end
