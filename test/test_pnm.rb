# coding: ASCII-8BIT

require 'tb'
require 'tmpdir'
require 'test/unit'

class TestTbPNM < Test::Unit::TestCase
  def parse_pnm(pnm)
    Tb::PNMReader.new(StringIO.new(pnm)).to_a
  end

  def generate_pnm(ary)
    writer = Tb::PNMWriter.new(out = '')
    ary.each {|h| writer.put_hash h }
    writer.finish
    out
  end

  def test_parse_pbm_ascii
    pbm = "P1\n2 3\n101101\n"
    t = parse_pnm(pbm)
    assert_equal(
      [
        {"type"=>"meta", "component"=>"pnm_type", "value"=>"P1"},
        {"type"=>"meta", "component"=>"width", "value"=>2},
        {"type"=>"meta", "component"=>"height", "value"=>3},
        {"type"=>"meta", "component"=>"max", "value"=>1},
        {"type"=>"pixel", "x"=>0, "y"=>0, "component"=>"V", "value"=>0.0},
        {"type"=>"pixel", "x"=>1, "y"=>0, "component"=>"V", "value"=>1.0},
        {"type"=>"pixel", "x"=>0, "y"=>1, "component"=>"V", "value"=>0.0},
        {"type"=>"pixel", "x"=>1, "y"=>1, "component"=>"V", "value"=>0.0},
        {"type"=>"pixel", "x"=>0, "y"=>2, "component"=>"V", "value"=>1.0},
        {"type"=>"pixel", "x"=>1, "y"=>2, "component"=>"V", "value"=>0.0}
      ], t)
    assert_equal("P1\n2 3\n10\n11\n01\n", generate_pnm(t))
  end

  def test_parse_pbm_binary
    pbm = "P4\n2 3\n\x80\xc0\x40"
    t = parse_pnm(pbm)
    assert_equal(
      [
        {"type"=>"meta", "component"=>"pnm_type", "value"=>"P4"},
        {"type"=>"meta", "component"=>"width", "value"=>2},
        {"type"=>"meta", "component"=>"height", "value"=>3},
        {"type"=>"meta", "component"=>"max", "value"=>1},
        {"type"=>"pixel", "x"=>0, "y"=>0, "component"=>"V", "value"=>0.0},
        {"type"=>"pixel", "x"=>1, "y"=>0, "component"=>"V", "value"=>1.0},
        {"type"=>"pixel", "x"=>0, "y"=>1, "component"=>"V", "value"=>0.0},
        {"type"=>"pixel", "x"=>1, "y"=>1, "component"=>"V", "value"=>0.0},
        {"type"=>"pixel", "x"=>0, "y"=>2, "component"=>"V", "value"=>1.0},
        {"type"=>"pixel", "x"=>1, "y"=>2, "component"=>"V", "value"=>0.0}
      ], t)
    assert_equal(pbm, generate_pnm(t))
  end

  def test_parse_pgm_ascii
    pgm = "P2\n2 3\n255\n0 1\n100 101\n254 255\n"
    t = parse_pnm(pgm)
    assert_equal(
      [
        {"type"=>"meta", "component"=>"pnm_type", "value"=>"P2"},
        {"type"=>"meta", "component"=>"width", "value"=>2},
        {"type"=>"meta", "component"=>"height", "value"=>3},
        {"type"=>"meta", "component"=>"max", "value"=>255},
        {"type"=>"pixel", "x"=>0, "y"=>0, "component"=>"V", "value"=>0.0},
        {"type"=>"pixel", "x"=>1, "y"=>0, "component"=>"V", "value"=>1.0/255},
        {"type"=>"pixel", "x"=>0, "y"=>1, "component"=>"V", "value"=>100.0/255},
        {"type"=>"pixel", "x"=>1, "y"=>1, "component"=>"V", "value"=>101.0/255},
        {"type"=>"pixel", "x"=>0, "y"=>2, "component"=>"V", "value"=>254.0/255},
        {"type"=>"pixel", "x"=>1, "y"=>2, "component"=>"V", "value"=>255.0/255}
      ], t)
    assert_equal(pgm, generate_pnm(t))
  end

  def test_parse_pgm_binary
    pgm = "P5\n2 3\n255\n\x00\x01\x64\x65\xfe\xff"
    t = parse_pnm(pgm)
    assert_equal(
      [
        {"type"=>"meta", "component"=>"pnm_type", "value"=>"P5"},
        {"type"=>"meta", "component"=>"width", "value"=>2},
        {"type"=>"meta", "component"=>"height", "value"=>3},
        {"type"=>"meta", "component"=>"max", "value"=>255},
        {"type"=>"pixel", "x"=>0, "y"=>0, "component"=>"V", "value"=>0.0},
        {"type"=>"pixel", "x"=>1, "y"=>0, "component"=>"V", "value"=>1.0/255},
        {"type"=>"pixel", "x"=>0, "y"=>1, "component"=>"V", "value"=>100.0/255},
        {"type"=>"pixel", "x"=>1, "y"=>1, "component"=>"V", "value"=>101.0/255},
        {"type"=>"pixel", "x"=>0, "y"=>2, "component"=>"V", "value"=>254.0/255},
        {"type"=>"pixel", "x"=>1, "y"=>2, "component"=>"V", "value"=>255.0/255}
      ], t)
    assert_equal(pgm, generate_pnm(t))
  end

  def test_parse_ppm_ascii
    ppm = "P3\n2 3\n255\n0 1 2 3 4 5\n100 101 102 103 104 105\n250 251 252 253 254 255\n"
    t = parse_pnm(ppm)
    assert_equal(
      [
        {"type"=>"meta", "component"=>"pnm_type", "value"=>"P3"},
        {"type"=>"meta", "component"=>"width", "value"=>2},
        {"type"=>"meta", "component"=>"height", "value"=>3},
        {"type"=>"meta", "component"=>"max", "value"=>255},
        {"type"=>"pixel", "x"=>0, "y"=>0, "component"=>"R", "value"=>0.0},
        {"type"=>"pixel", "x"=>0, "y"=>0, "component"=>"G", "value"=>1.0/255},
        {"type"=>"pixel", "x"=>0, "y"=>0, "component"=>"B", "value"=>2.0/255},
        {"type"=>"pixel", "x"=>1, "y"=>0, "component"=>"R", "value"=>3.0/255},
        {"type"=>"pixel", "x"=>1, "y"=>0, "component"=>"G", "value"=>4.0/255},
        {"type"=>"pixel", "x"=>1, "y"=>0, "component"=>"B", "value"=>5.0/255},
        {"type"=>"pixel", "x"=>0, "y"=>1, "component"=>"R", "value"=>100.0/255},
        {"type"=>"pixel", "x"=>0, "y"=>1, "component"=>"G", "value"=>101.0/255},
        {"type"=>"pixel", "x"=>0, "y"=>1, "component"=>"B", "value"=>102.0/255},
        {"type"=>"pixel", "x"=>1, "y"=>1, "component"=>"R", "value"=>103.0/255},
        {"type"=>"pixel", "x"=>1, "y"=>1, "component"=>"G", "value"=>104.0/255},
        {"type"=>"pixel", "x"=>1, "y"=>1, "component"=>"B", "value"=>105.0/255},
        {"type"=>"pixel", "x"=>0, "y"=>2, "component"=>"R", "value"=>250.0/255},
        {"type"=>"pixel", "x"=>0, "y"=>2, "component"=>"G", "value"=>251.0/255},
        {"type"=>"pixel", "x"=>0, "y"=>2, "component"=>"B", "value"=>252.0/255},
        {"type"=>"pixel", "x"=>1, "y"=>2, "component"=>"R", "value"=>253.0/255},
        {"type"=>"pixel", "x"=>1, "y"=>2, "component"=>"G", "value"=>254.0/255},
        {"type"=>"pixel", "x"=>1, "y"=>2, "component"=>"B", "value"=>255.0/255}
      ], t)
    assert_equal(ppm, generate_pnm(t))
  end

  def test_parse_ppm_binary
    ppm = "P6\n2 3\n255\n\x00\x01\x02\x03\x04\x05\x64\x65\x66\x67\x68\x69\xfa\xfb\xfc\xfd\xfe\xff"
    t = parse_pnm(ppm)
    assert_equal(
      [
        {"type"=>"meta", "component"=>"pnm_type", "value"=>"P6"},
        {"type"=>"meta", "component"=>"width", "value"=>2},
        {"type"=>"meta", "component"=>"height", "value"=>3},
        {"type"=>"meta", "component"=>"max", "value"=>255},
        {"type"=>"pixel", "x"=>0, "y"=>0, "component"=>"R", "value"=>0.0},
        {"type"=>"pixel", "x"=>0, "y"=>0, "component"=>"G", "value"=>1.0/255},
        {"type"=>"pixel", "x"=>0, "y"=>0, "component"=>"B", "value"=>2.0/255},
        {"type"=>"pixel", "x"=>1, "y"=>0, "component"=>"R", "value"=>3.0/255},
        {"type"=>"pixel", "x"=>1, "y"=>0, "component"=>"G", "value"=>4.0/255},
        {"type"=>"pixel", "x"=>1, "y"=>0, "component"=>"B", "value"=>5.0/255},
        {"type"=>"pixel", "x"=>0, "y"=>1, "component"=>"R", "value"=>100.0/255},
        {"type"=>"pixel", "x"=>0, "y"=>1, "component"=>"G", "value"=>101.0/255},
        {"type"=>"pixel", "x"=>0, "y"=>1, "component"=>"B", "value"=>102.0/255},
        {"type"=>"pixel", "x"=>1, "y"=>1, "component"=>"R", "value"=>103.0/255},
        {"type"=>"pixel", "x"=>1, "y"=>1, "component"=>"G", "value"=>104.0/255},
        {"type"=>"pixel", "x"=>1, "y"=>1, "component"=>"B", "value"=>105.0/255},
        {"type"=>"pixel", "x"=>0, "y"=>2, "component"=>"R", "value"=>250.0/255},
        {"type"=>"pixel", "x"=>0, "y"=>2, "component"=>"G", "value"=>251.0/255},
        {"type"=>"pixel", "x"=>0, "y"=>2, "component"=>"B", "value"=>252.0/255},
        {"type"=>"pixel", "x"=>1, "y"=>2, "component"=>"R", "value"=>253.0/255},
        {"type"=>"pixel", "x"=>1, "y"=>2, "component"=>"G", "value"=>254.0/255},
        {"type"=>"pixel", "x"=>1, "y"=>2, "component"=>"B", "value"=>255.0/255}
      ], t)
    assert_equal(ppm, generate_pnm(t))
  end

  def test_parse_ppm_binary2
    ppm = "P6\n2 3\n65535\n\x00\x00\x00\x01\x00\x02\x00\x03\x00\x04\x00\x05\x00\x64\x00\x65\x00\x66\x00\x67\x00\x68\x00\x69\x00\xfa\x00\xfb\x00\xfc\x00\xfd\x00\xfe\x00\xff"
    t = parse_pnm(ppm)
    assert_equal(
      [
        {"type"=>"meta", "component"=>"pnm_type", "value"=>"P6"},
        {"type"=>"meta", "component"=>"width", "value"=>2},
        {"type"=>"meta", "component"=>"height", "value"=>3},
        {"type"=>"meta", "component"=>"max", "value"=>65535},
        {"type"=>"pixel", "x"=>0, "y"=>0, "component"=>"R", "value"=>0.0},
        {"type"=>"pixel", "x"=>0, "y"=>0, "component"=>"G", "value"=>1.0/65535},
        {"type"=>"pixel", "x"=>0, "y"=>0, "component"=>"B", "value"=>2.0/65535},
        {"type"=>"pixel", "x"=>1, "y"=>0, "component"=>"R", "value"=>3.0/65535},
        {"type"=>"pixel", "x"=>1, "y"=>0, "component"=>"G", "value"=>4.0/65535},
        {"type"=>"pixel", "x"=>1, "y"=>0, "component"=>"B", "value"=>5.0/65535},
        {"type"=>"pixel", "x"=>0, "y"=>1, "component"=>"R", "value"=>100.0/65535},
        {"type"=>"pixel", "x"=>0, "y"=>1, "component"=>"G", "value"=>101.0/65535},
        {"type"=>"pixel", "x"=>0, "y"=>1, "component"=>"B", "value"=>102.0/65535},
        {"type"=>"pixel", "x"=>1, "y"=>1, "component"=>"R", "value"=>103.0/65535},
        {"type"=>"pixel", "x"=>1, "y"=>1, "component"=>"G", "value"=>104.0/65535},
        {"type"=>"pixel", "x"=>1, "y"=>1, "component"=>"B", "value"=>105.0/65535},
        {"type"=>"pixel", "x"=>0, "y"=>2, "component"=>"R", "value"=>250.0/65535},
        {"type"=>"pixel", "x"=>0, "y"=>2, "component"=>"G", "value"=>251.0/65535},
        {"type"=>"pixel", "x"=>0, "y"=>2, "component"=>"B", "value"=>252.0/65535},
        {"type"=>"pixel", "x"=>1, "y"=>2, "component"=>"R", "value"=>253.0/65535},
        {"type"=>"pixel", "x"=>1, "y"=>2, "component"=>"G", "value"=>254.0/65535},
        {"type"=>"pixel", "x"=>1, "y"=>2, "component"=>"B", "value"=>255.0/65535}
      ], t)
    assert_equal(ppm, generate_pnm(t))
  end

  def test_parse_pbm_comment
    pbm = "P1\n\#foo\n2 3\n101101\n"
    t = parse_pnm(pbm)
    assert_equal(
      [
        {"type"=>"meta", "component"=>"pnm_type", "value"=>"P1"},
        {"type"=>"meta", "component"=>"width", "value"=>2},
        {"type"=>"meta", "component"=>"height", "value"=>3},
        {"type"=>"meta", "component"=>"max", "value"=>1},
        {"type"=>"meta", "component"=>"comment", "value"=>"foo"},
        {"type"=>"pixel", "x"=>0, "y"=>0, "component"=>"V", "value"=>0.0},
        {"type"=>"pixel", "x"=>1, "y"=>0, "component"=>"V", "value"=>1.0},
        {"type"=>"pixel", "x"=>0, "y"=>1, "component"=>"V", "value"=>0.0},
        {"type"=>"pixel", "x"=>1, "y"=>1, "component"=>"V", "value"=>0.0},
        {"type"=>"pixel", "x"=>0, "y"=>2, "component"=>"V", "value"=>1.0},
        {"type"=>"pixel", "x"=>1, "y"=>2, "component"=>"V", "value"=>0.0}
      ], t)
    assert_equal("P1\n\#foo\n2 3\n10\n11\n01\n", generate_pnm(t))
  end

  def test_parse_pbm_ascii_wide
    pbm = "P1\n71 3\n" + "0" * (71 * 3)
    t = parse_pnm(pbm)
    assert_equal("P1\n71 3\n" + ("0"*70+"\n0\n")*3, generate_pnm(t))
  end

  def test_parse_pgm_ascii_wide
    pgm = "P2\n40 3\n255\n" + "0 " * (40*3)
    t = parse_pnm(pgm)
    assert_equal("P2\n40 3\n255\n" + ("0 "*34 + "0\n" + "0 "*4 + "0\n")*3, generate_pnm(t))
  end

  def test_parse_invalid
    invalid = "foo"
    assert_raise(ArgumentError) { parse_pnm(invalid) }
  end

  def test_parse_too_short
    too_short = "P1\n2 3\n10110\n"
    assert_raise(ArgumentError) { parse_pnm(too_short) }
  end

  def test_generate_invalid_fields
    t = [{ "foo" => 1 }]
    assert_raise(ArgumentError) { generate_pnm(t) }
  end

  def test_generate_inconsistent_color_component
    t = [{'component' => 'V', 'value' => 1.0}, {'component' => 'R'}]
    assert_raise(ArgumentError) { generate_pnm(t) }
  end

  def test_generate_complement
    t = [
      {"x"=>0, "y"=>0, "component"=>"V", "value"=>0.0},
      {"x"=>1, "y"=>0, "component"=>"V", "value"=>1.0},
      {"x"=>0, "y"=>1, "component"=>"V", "value"=>0.0},
      {"x"=>1, "y"=>1, "component"=>"V", "value"=>0.0},
      {"x"=>0, "y"=>2, "component"=>"V", "value"=>1.0},
      {"x"=>1, "y"=>2, "component"=>"V", "value"=>0.0}
    ]
    assert_equal("P4\n2 3\n\x80\xc0\x40", generate_pnm(t))
  end

  def test_generate_complement2
    t = [
      {"x"=>0, "y"=>0, "component"=>"V", "value"=>1.0/65535},
      {"x"=>1, "y"=>0, "component"=>"V", "value"=>1.0},
      {"x"=>0, "y"=>1, "component"=>"V", "value"=>0.0},
      {"x"=>1, "y"=>1, "component"=>"V", "value"=>0.0},
      {"x"=>0, "y"=>2, "component"=>"V", "value"=>1.0},
      {"x"=>1, "y"=>2, "component"=>"V", "value"=>0.0}
    ]
    assert_equal("P5\n2 3\n65535\n\x00\x01\xff\xff\x00\x00\x00\x00\xff\xff\x00\x00", generate_pnm(t))
  end

  def test_generate_complement1
    t = [
      {"x"=>0, "y"=>0, "component"=>"V", "value"=>1.0/255},
      {"x"=>1, "y"=>0, "component"=>"V", "value"=>1.0},
      {"x"=>0, "y"=>1, "component"=>"V", "value"=>0.0},
      {"x"=>1, "y"=>1, "component"=>"V", "value"=>0.0},
      {"x"=>0, "y"=>2, "component"=>"V", "value"=>1.0},
      {"x"=>1, "y"=>2, "component"=>"V", "value"=>0.0}
    ]
    assert_equal("P5\n2 3\n255\n\x01\xff\x00\x00\xff\x00", generate_pnm(t))
  end

  def test_generate_complement_ppm
    t = [
      {"x"=>0, "y"=>0, "component"=>"R", "value"=>0.0},
      {"x"=>0, "y"=>0, "component"=>"G", "value"=>1.0},
      {"x"=>0, "y"=>0, "component"=>"B", "value"=>1.0},
    ]
    assert_equal("P6\n1 1\n255\n\x00\xff\xff", generate_pnm(t))
  end

  def test_generate_overrange
    t = [
      {"x"=>0, "y"=>0, "component"=>"V", "value"=>-0.5},
      {"x"=>0, "y"=>1, "component"=>"V", "value"=>1.5},
    ]
    assert_equal("P5\n1 2\n255\n\x00\xff", generate_pnm(t))
  end

  def test_invalid_pnm_type
    t = [{'component' => 'pnm_type', 'value' => "foo"}]
    assert_raise(ArgumentError) { generate_pnm(t) }
  end

  def test_invalid_comment
    t = [{'component' => 'comment', 'value' => "\n"}]
    assert_raise(ArgumentError) { generate_pnm(t) }
  end

  def test_pnmreader_to_a
    pbm = "P1\n2 3\n101101\n"
    r = Tb::PNMReader.new(StringIO.new(pbm))
    header = r.get_named_header
    assert_equal(["type", "x", "y", "component", "value"], header)
    assert_equal(
      [["meta", nil, nil, "pnm_type", "P1"],
       ["meta", nil, nil, "width", 2],
       ["meta", nil, nil, "height", 3],
       ["meta", nil, nil, "max", 1],
       ["pixel", 0, 0, "V", 0.0],
       ["pixel", 1, 0, "V", 1.0],
       ["pixel", 0, 1, "V", 0.0],
       ["pixel", 1, 1, "V", 0.0],
       ["pixel", 0, 2, "V", 1.0],
       ["pixel", 1, 2, "V", 0.0]],
       r.to_a.map {|h| h.values_at(*header) })
  end

  def test_reader_open
    Dir.mktmpdir {|d|
      Dir.chdir(d) {
        File.open("ba.pbm", "w") {|f| f << "P1\n1 1\n0" }
        File.open("ba", "w") {|f| f << "P1\n1 1\n0" }
        File.open("ga.pgm", "w") {|f| f << "P2\n1 1\n255\n0" }
        File.open("ga", "w") {|f| f << "P2\n1 1\n255\n0" }
        File.open("pa.ppm", "w") {|f| f << "P3\n1 1\n255\n0 0 0" }
        File.open("pa", "w") {|f| f << "P3\n1 1\n255\n0 0 0" }
        File.open("bb.pbm", "w") {|f| f << "P4\n1 1\n\0" }
        File.open("bb", "w") {|f| f << "P4\n1 1\n\0" }
        File.open("gb.pgm", "w") {|f| f << "P5\n1 1\n255\n\0" }
        File.open("gb", "w") {|f| f << "P5\n1 1\n255\n\0" }
        File.open("pb.ppm", "w") {|f| f << "P6\n1 1\n255\n\0\0\0" }
        File.open("pb", "w") {|f| f << "P6\n1 1\n255\n\0\0\0" }

        File.open("ba.pnm", "w") {|f| f << "P1\n1 1\n0" }
        File.open("ga.pnm", "w") {|f| f << "P2\n1 1\n255\n0" }
        File.open("pa.pnm", "w") {|f| f << "P3\n1 1\n255\n0 0 0" }
        File.open("bb.pnm", "w") {|f| f << "P4\n1 1\n\0" }
        File.open("gb.pnm", "w") {|f| f << "P5\n1 1\n255\n\0" }
        File.open("pb.pnm", "w") {|f| f << "P6\n1 1\n255\n\0\0\0" }

        assert_equal(["type", "x", "y", "component", "value"], Tb.open_reader2("ba.pbm") {|r| header = nil; r.with_header {|h| header = h}.each {}; header })
        assert_equal(["type", "x", "y", "component", "value"], Tb.open_reader2("pnm:ba") {|r| header = nil; r.with_header {|h| header = h}.each {}; header })
        assert_equal(["type", "x", "y", "component", "value"], Tb.open_reader2("ga.pgm") {|r| header = nil; r.with_header {|h| header = h}.each {}; header })
        assert_equal(["type", "x", "y", "component", "value"], Tb.open_reader2("pnm:ga") {|r| header = nil; r.with_header {|h| header = h}.each {}; header })
        assert_equal(["type", "x", "y", "component", "value"], Tb.open_reader2("pa.ppm") {|r| header = nil; r.with_header {|h| header = h}.each {}; header })
        assert_equal(["type", "x", "y", "component", "value"], Tb.open_reader2("pnm:pa") {|r| header = nil; r.with_header {|h| header = h}.each {}; header })
        assert_equal(["type", "x", "y", "component", "value"], Tb.open_reader2("bb.pbm") {|r| header = nil; r.with_header {|h| header = h}.each {}; header })
        assert_equal(["type", "x", "y", "component", "value"], Tb.open_reader2("pnm:bb") {|r| header = nil; r.with_header {|h| header = h}.each {}; header })
        assert_equal(["type", "x", "y", "component", "value"], Tb.open_reader2("gb.pgm") {|r| header = nil; r.with_header {|h| header = h}.each {}; header })
        assert_equal(["type", "x", "y", "component", "value"], Tb.open_reader2("pnm:gb") {|r| header = nil; r.with_header {|h| header = h}.each {}; header })
        assert_equal(["type", "x", "y", "component", "value"], Tb.open_reader2("pb.ppm") {|r| header = nil; r.with_header {|h| header = h}.each {}; header })
        assert_equal(["type", "x", "y", "component", "value"], Tb.open_reader2("pnm:pb") {|r| header = nil; r.with_header {|h| header = h}.each {}; header })

        assert_equal(["type", "x", "y", "component", "value"], Tb.open_reader2("pbm:ba") {|r| header = nil; r.with_header {|h| header = h}.each {}; header })
        assert_equal(["type", "x", "y", "component", "value"], Tb.open_reader2("pgm:ga") {|r| header = nil; r.with_header {|h| header = h}.each {}; header })
        assert_equal(["type", "x", "y", "component", "value"], Tb.open_reader2("ppm:pa") {|r| header = nil; r.with_header {|h| header = h}.each {}; header })
        assert_equal(["type", "x", "y", "component", "value"], Tb.open_reader2("pbm:bb") {|r| header = nil; r.with_header {|h| header = h}.each {}; header })
        assert_equal(["type", "x", "y", "component", "value"], Tb.open_reader2("pgm:gb") {|r| header = nil; r.with_header {|h| header = h}.each {}; header })
        assert_equal(["type", "x", "y", "component", "value"], Tb.open_reader2("ppm:pb") {|r| header = nil; r.with_header {|h| header = h}.each {}; header })

        assert_equal(["type", "x", "y", "component", "value"], Tb.open_reader2("ba.pnm") {|r| header = nil; r.with_header {|h| header = h}.each {}; header })
        assert_equal(["type", "x", "y", "component", "value"], Tb.open_reader2("ga.pnm") {|r| header = nil; r.with_header {|h| header = h}.each {}; header })
        assert_equal(["type", "x", "y", "component", "value"], Tb.open_reader2("pa.pnm") {|r| header = nil; r.with_header {|h| header = h}.each {}; header })
        assert_equal(["type", "x", "y", "component", "value"], Tb.open_reader2("bb.pnm") {|r| header = nil; r.with_header {|h| header = h}.each {}; header })
        assert_equal(["type", "x", "y", "component", "value"], Tb.open_reader2("gb.pnm") {|r| header = nil; r.with_header {|h| header = h}.each {}; header })
        assert_equal(["type", "x", "y", "component", "value"], Tb.open_reader2("pb.pnm") {|r| header = nil; r.with_header {|h| header = h}.each {}; header })
      }
    }
  end

end
