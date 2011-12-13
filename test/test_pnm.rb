require 'tb'
require 'test/unit'

class TestTbPNM < Test::Unit::TestCase
  def test_parse_pbm_ascii
    pbm = "P1\n2 3\n101101\n"
    t = Tb.parse_pnm(pbm)
    assert_equal(
      [
        {"component"=>"pnm_type", "value"=>"P1"},
        {"component"=>"width", "value"=>2},
        {"component"=>"height", "value"=>3},
        {"component"=>"max", "value"=>1},
        {"x"=>0, "y"=>0, "component"=>"V", "value"=>0.0},
        {"x"=>1, "y"=>0, "component"=>"V", "value"=>1.0},
        {"x"=>0, "y"=>1, "component"=>"V", "value"=>0.0},
        {"x"=>1, "y"=>1, "component"=>"V", "value"=>0.0},
        {"x"=>0, "y"=>2, "component"=>"V", "value"=>1.0},
        {"x"=>1, "y"=>2, "component"=>"V", "value"=>0.0}
      ], t.map {|rec| rec.to_h })
    assert_equal("P1\n2 3\n10\n11\n01\n", t.generate_pnm)
  end

  def test_parse_pbm_binary
    pbm = "P4\n2 3\n\x80\xc0\x40"
    t = Tb.parse_pnm(pbm)
    assert_equal(
      [
        {"component"=>"pnm_type", "value"=>"P4"},
        {"component"=>"width", "value"=>2},
        {"component"=>"height", "value"=>3},
        {"component"=>"max", "value"=>1},
        {"x"=>0, "y"=>0, "component"=>"V", "value"=>0.0},
        {"x"=>1, "y"=>0, "component"=>"V", "value"=>1.0},
        {"x"=>0, "y"=>1, "component"=>"V", "value"=>0.0},
        {"x"=>1, "y"=>1, "component"=>"V", "value"=>0.0},
        {"x"=>0, "y"=>2, "component"=>"V", "value"=>1.0},
        {"x"=>1, "y"=>2, "component"=>"V", "value"=>0.0}
      ], t.map {|rec| rec.to_h })
    assert_equal(pbm, t.generate_pnm)
  end

  def test_parse_pgm_ascii
    pgm = "P2\n2 3\n255\n0 1\n100 101\n254 255\n"
    t = Tb.parse_pnm(pgm)
    assert_equal(
      [
        {"component"=>"pnm_type", "value"=>"P2"},
        {"component"=>"width", "value"=>2},
        {"component"=>"height", "value"=>3},
        {"component"=>"max", "value"=>255},
        {"x"=>0, "y"=>0, "component"=>"V", "value"=>0.0},
        {"x"=>1, "y"=>0, "component"=>"V", "value"=>1.0/255},
        {"x"=>0, "y"=>1, "component"=>"V", "value"=>100.0/255},
        {"x"=>1, "y"=>1, "component"=>"V", "value"=>101.0/255},
        {"x"=>0, "y"=>2, "component"=>"V", "value"=>254.0/255},
        {"x"=>1, "y"=>2, "component"=>"V", "value"=>255.0/255}
      ], t.map {|rec| rec.to_h })
    assert_equal(pgm, t.generate_pnm)
  end

  def test_parse_pgm_binary
    pgm = "P5\n2 3\n255\n\x00\x01\x64\x65\xfe\xff"
    t = Tb.parse_pnm(pgm)
    assert_equal(
      [
        {"component"=>"pnm_type", "value"=>"P5"},
        {"component"=>"width", "value"=>2},
        {"component"=>"height", "value"=>3},
        {"component"=>"max", "value"=>255},
        {"x"=>0, "y"=>0, "component"=>"V", "value"=>0.0},
        {"x"=>1, "y"=>0, "component"=>"V", "value"=>1.0/255},
        {"x"=>0, "y"=>1, "component"=>"V", "value"=>100.0/255},
        {"x"=>1, "y"=>1, "component"=>"V", "value"=>101.0/255},
        {"x"=>0, "y"=>2, "component"=>"V", "value"=>254.0/255},
        {"x"=>1, "y"=>2, "component"=>"V", "value"=>255.0/255}
      ], t.map {|rec| rec.to_h })
    assert_equal(pgm, t.generate_pnm)
  end

  def test_parse_ppm_ascii
    ppm = "P3\n2 3\n255\n0 1 2 3 4 5\n100 101 102 103 104 105\n250 251 252 253 254 255\n"
    t = Tb.parse_pnm(ppm)
    assert_equal(
      [
        {"component"=>"pnm_type", "value"=>"P3"},
        {"component"=>"width", "value"=>2},
        {"component"=>"height", "value"=>3},
        {"component"=>"max", "value"=>255},
        {"x"=>0, "y"=>0, "component"=>"R", "value"=>0.0},
        {"x"=>0, "y"=>0, "component"=>"G", "value"=>1.0/255},
        {"x"=>0, "y"=>0, "component"=>"B", "value"=>2.0/255},
        {"x"=>1, "y"=>0, "component"=>"R", "value"=>3.0/255},
        {"x"=>1, "y"=>0, "component"=>"G", "value"=>4.0/255},
        {"x"=>1, "y"=>0, "component"=>"B", "value"=>5.0/255},
        {"x"=>0, "y"=>1, "component"=>"R", "value"=>100.0/255},
        {"x"=>0, "y"=>1, "component"=>"G", "value"=>101.0/255},
        {"x"=>0, "y"=>1, "component"=>"B", "value"=>102.0/255},
        {"x"=>1, "y"=>1, "component"=>"R", "value"=>103.0/255},
        {"x"=>1, "y"=>1, "component"=>"G", "value"=>104.0/255},
        {"x"=>1, "y"=>1, "component"=>"B", "value"=>105.0/255},
        {"x"=>0, "y"=>2, "component"=>"R", "value"=>250.0/255},
        {"x"=>0, "y"=>2, "component"=>"G", "value"=>251.0/255},
        {"x"=>0, "y"=>2, "component"=>"B", "value"=>252.0/255},
        {"x"=>1, "y"=>2, "component"=>"R", "value"=>253.0/255},
        {"x"=>1, "y"=>2, "component"=>"G", "value"=>254.0/255},
        {"x"=>1, "y"=>2, "component"=>"B", "value"=>255.0/255}
      ], t.map {|rec| rec.to_h })
    assert_equal(ppm, t.generate_pnm)
  end

  def test_parse_ppm_binary
    ppm = "P6\n2 3\n255\n\x00\x01\x02\x03\x04\x05\x64\x65\x66\x67\x68\x69\xfa\xfb\xfc\xfd\xfe\xff"
    t = Tb.parse_pnm(ppm)
    assert_equal(
      [
        {"component"=>"pnm_type", "value"=>"P6"},
        {"component"=>"width", "value"=>2},
        {"component"=>"height", "value"=>3},
        {"component"=>"max", "value"=>255},
        {"x"=>0, "y"=>0, "component"=>"R", "value"=>0.0},
        {"x"=>0, "y"=>0, "component"=>"G", "value"=>1.0/255},
        {"x"=>0, "y"=>0, "component"=>"B", "value"=>2.0/255},
        {"x"=>1, "y"=>0, "component"=>"R", "value"=>3.0/255},
        {"x"=>1, "y"=>0, "component"=>"G", "value"=>4.0/255},
        {"x"=>1, "y"=>0, "component"=>"B", "value"=>5.0/255},
        {"x"=>0, "y"=>1, "component"=>"R", "value"=>100.0/255},
        {"x"=>0, "y"=>1, "component"=>"G", "value"=>101.0/255},
        {"x"=>0, "y"=>1, "component"=>"B", "value"=>102.0/255},
        {"x"=>1, "y"=>1, "component"=>"R", "value"=>103.0/255},
        {"x"=>1, "y"=>1, "component"=>"G", "value"=>104.0/255},
        {"x"=>1, "y"=>1, "component"=>"B", "value"=>105.0/255},
        {"x"=>0, "y"=>2, "component"=>"R", "value"=>250.0/255},
        {"x"=>0, "y"=>2, "component"=>"G", "value"=>251.0/255},
        {"x"=>0, "y"=>2, "component"=>"B", "value"=>252.0/255},
        {"x"=>1, "y"=>2, "component"=>"R", "value"=>253.0/255},
        {"x"=>1, "y"=>2, "component"=>"G", "value"=>254.0/255},
        {"x"=>1, "y"=>2, "component"=>"B", "value"=>255.0/255}
      ], t.map {|rec| rec.to_h })
    assert_equal(ppm, t.generate_pnm)
  end

  def test_parse_ppm_binary2
    ppm = "P6\n2 3\n65535\n\x00\x00\x00\x01\x00\x02\x00\x03\x00\x04\x00\x05\x00\x64\x00\x65\x00\x66\x00\x67\x00\x68\x00\x69\x00\xfa\x00\xfb\x00\xfc\x00\xfd\x00\xfe\x00\xff"
    t = Tb.parse_pnm(ppm)
    assert_equal(
      [
        {"component"=>"pnm_type", "value"=>"P6"},
        {"component"=>"width", "value"=>2},
        {"component"=>"height", "value"=>3},
        {"component"=>"max", "value"=>65535},
        {"x"=>0, "y"=>0, "component"=>"R", "value"=>0.0},
        {"x"=>0, "y"=>0, "component"=>"G", "value"=>1.0/65535},
        {"x"=>0, "y"=>0, "component"=>"B", "value"=>2.0/65535},
        {"x"=>1, "y"=>0, "component"=>"R", "value"=>3.0/65535},
        {"x"=>1, "y"=>0, "component"=>"G", "value"=>4.0/65535},
        {"x"=>1, "y"=>0, "component"=>"B", "value"=>5.0/65535},
        {"x"=>0, "y"=>1, "component"=>"R", "value"=>100.0/65535},
        {"x"=>0, "y"=>1, "component"=>"G", "value"=>101.0/65535},
        {"x"=>0, "y"=>1, "component"=>"B", "value"=>102.0/65535},
        {"x"=>1, "y"=>1, "component"=>"R", "value"=>103.0/65535},
        {"x"=>1, "y"=>1, "component"=>"G", "value"=>104.0/65535},
        {"x"=>1, "y"=>1, "component"=>"B", "value"=>105.0/65535},
        {"x"=>0, "y"=>2, "component"=>"R", "value"=>250.0/65535},
        {"x"=>0, "y"=>2, "component"=>"G", "value"=>251.0/65535},
        {"x"=>0, "y"=>2, "component"=>"B", "value"=>252.0/65535},
        {"x"=>1, "y"=>2, "component"=>"R", "value"=>253.0/65535},
        {"x"=>1, "y"=>2, "component"=>"G", "value"=>254.0/65535},
        {"x"=>1, "y"=>2, "component"=>"B", "value"=>255.0/65535}
      ], t.map {|rec| rec.to_h })
    assert_equal(ppm, t.generate_pnm)
  end

  def test_parse_pbm_comment
    pbm = "P1\n\#foo\n2 3\n101101\n"
    t = Tb.parse_pnm(pbm)
    assert_equal(
      [
        {"component"=>"pnm_type", "value"=>"P1"},
        {"component"=>"width", "value"=>2},
        {"component"=>"height", "value"=>3},
        {"component"=>"max", "value"=>1},
        {"component"=>"comment", "value"=>"foo"},
        {"x"=>0, "y"=>0, "component"=>"V", "value"=>0.0},
        {"x"=>1, "y"=>0, "component"=>"V", "value"=>1.0},
        {"x"=>0, "y"=>1, "component"=>"V", "value"=>0.0},
        {"x"=>1, "y"=>1, "component"=>"V", "value"=>0.0},
        {"x"=>0, "y"=>2, "component"=>"V", "value"=>1.0},
        {"x"=>1, "y"=>2, "component"=>"V", "value"=>0.0}
      ], t.map {|rec| rec.to_h })
    assert_equal("P1\n\#foo\n2 3\n10\n11\n01\n", t.generate_pnm)
  end

  def test_parse_pbm_ascii_wide
    pbm = "P1\n71 3\n" + "0" * (71 * 3)
    t = Tb.parse_pnm(pbm)
    assert_equal("P1\n71 3\n" + ("0"*70+"\n0\n")*3, t.generate_pnm)
  end

  def test_parse_pgm_ascii_wide
    pgm = "P2\n40 3\n255\n" + "0 " * (40*3)
    t = Tb.parse_pnm(pgm)
    assert_equal("P2\n40 3\n255\n" + ("0 "*34 + "0\n" + "0 "*4 + "0\n")*3, t.generate_pnm)
  end

  def test_parse_invalid
    invalid = "foo"
    assert_raise(ArgumentError) { Tb.parse_pnm(invalid) }
  end

  def test_parse_too_short
    too_short = "P1\n2 3\n10110\n"
    assert_raise(ArgumentError) { Tb.parse_pnm(too_short) }
  end

  def test_generate_invalid_fields
    t = Tb.new %w[foo], [1]
    assert_raise(ArgumentError) { t.generate_pnm }
  end

  def test_generate_inconsistent_color_component
    t = Tb.new %w[x y component value], [nil, nil, 'V', 1.0], [nil, nil, 'R', 1.0]
    assert_raise(ArgumentError) { t.generate_pnm }
  end

  def test_generate_complement
    t = Tb.new %w[x y component value]
    [
      {"x"=>0, "y"=>0, "component"=>"V", "value"=>0.0},
      {"x"=>1, "y"=>0, "component"=>"V", "value"=>1.0},
      {"x"=>0, "y"=>1, "component"=>"V", "value"=>0.0},
      {"x"=>1, "y"=>1, "component"=>"V", "value"=>0.0},
      {"x"=>0, "y"=>2, "component"=>"V", "value"=>1.0},
      {"x"=>1, "y"=>2, "component"=>"V", "value"=>0.0}
    ].each {|h| t.insert h }
    assert_equal("P4\n2 3\n\x80\xc0\x40", t.generate_pnm)
  end

  def test_generate_complement2
    t = Tb.new %w[x y component value]
    [
      {"x"=>0, "y"=>0, "component"=>"V", "value"=>1.0/65535},
      {"x"=>1, "y"=>0, "component"=>"V", "value"=>1.0},
      {"x"=>0, "y"=>1, "component"=>"V", "value"=>0.0},
      {"x"=>1, "y"=>1, "component"=>"V", "value"=>0.0},
      {"x"=>0, "y"=>2, "component"=>"V", "value"=>1.0},
      {"x"=>1, "y"=>2, "component"=>"V", "value"=>0.0}
    ].each {|h| t.insert h }
    assert_equal("P5\n2 3\n65535\n\x00\x01\xff\xff\x00\x00\x00\x00\xff\xff\x00\x00", t.generate_pnm)
  end

  def test_generate_complement1
    t = Tb.new %w[x y component value]
    [
      {"x"=>0, "y"=>0, "component"=>"V", "value"=>1.0/255},
      {"x"=>1, "y"=>0, "component"=>"V", "value"=>1.0},
      {"x"=>0, "y"=>1, "component"=>"V", "value"=>0.0},
      {"x"=>1, "y"=>1, "component"=>"V", "value"=>0.0},
      {"x"=>0, "y"=>2, "component"=>"V", "value"=>1.0},
      {"x"=>1, "y"=>2, "component"=>"V", "value"=>0.0}
    ].each {|h| t.insert h }
    assert_equal("P5\n2 3\n255\n\x01\xff\x00\x00\xff\x00", t.generate_pnm)
  end

  def test_generate_complement_ppm
    t = Tb.new %w[x y component value]
    [
      {"x"=>0, "y"=>0, "component"=>"R", "value"=>0.0},
      {"x"=>0, "y"=>0, "component"=>"G", "value"=>1.0},
      {"x"=>0, "y"=>0, "component"=>"B", "value"=>1.0},
    ].each {|h| t.insert h }
    assert_equal("P6\n1 1\n255\n\x00\xff\xff", t.generate_pnm)
  end

  def test_generate_overrange
    t = Tb.new %w[x y component value]
    [
      {"x"=>0, "y"=>0, "component"=>"V", "value"=>-0.5},
      {"x"=>0, "y"=>1, "component"=>"V", "value"=>1.5},
    ].each {|h| t.insert h }
    assert_equal("P5\n1 2\n255\n\x00\xff", t.generate_pnm)
  end

  def test_invalid_pnm_type
    t = Tb.new %w[x y component value], [nil, nil, 'pnm_type', "foo"]
    assert_raise(ArgumentError) { t.generate_pnm }
  end

  def test_invalid_comment
    t = Tb.new %w[x y component value], [nil, nil, 'comment', "\n"]
    assert_raise(ArgumentError) { t.generate_pnm }
  end

  def test_load_pnm
    Dir.mktmpdir {|d|
      File.open(fn="#{d}/foo.pbm", "w") {|f| f << "P4\n1 1\n\0" }
      t = Tb.load_pnm(fn)
      assert_equal({"component"=>"pnm_type", "value"=>"P4"}, t.get_record(0).to_h)
    }
  end

  def test_pnmreader_to_a
    pbm = "P1\n2 3\n101101\n"
    r = Tb::PNMReader.new(pbm)
    assert_equal(
      [["x", "y", "component", "value"],
       [nil, nil, "pnm_type", "P1"],
       [nil, nil, "width", 2],
       [nil, nil, "height", 3],
       [nil, nil, "max", 1],
       [0, 0, "V", 0.0],
       [1, 0, "V", 1.0],
       [0, 1, "V", 0.0],
       [1, 1, "V", 0.0],
       [0, 2, "V", 1.0],
       [1, 2, "V", 0.0]],
       r.to_a)
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

        assert_equal(["x", "y", "component", "value"], Tb::Reader.open("ba.pbm") {|r| r.header })
        assert_equal(["x", "y", "component", "value"], Tb::Reader.open("pnm:ba") {|r| r.header })
        assert_equal(["x", "y", "component", "value"], Tb::Reader.open("ga.pgm") {|r| r.header })
        assert_equal(["x", "y", "component", "value"], Tb::Reader.open("pnm:ga") {|r| r.header })
        assert_equal(["x", "y", "component", "value"], Tb::Reader.open("pa.ppm") {|r| r.header })
        assert_equal(["x", "y", "component", "value"], Tb::Reader.open("pnm:pa") {|r| r.header })
        assert_equal(["x", "y", "component", "value"], Tb::Reader.open("bb.pbm") {|r| r.header })
        assert_equal(["x", "y", "component", "value"], Tb::Reader.open("pnm:bb") {|r| r.header })
        assert_equal(["x", "y", "component", "value"], Tb::Reader.open("gb.pgm") {|r| r.header })
        assert_equal(["x", "y", "component", "value"], Tb::Reader.open("pnm:gb") {|r| r.header })
        assert_equal(["x", "y", "component", "value"], Tb::Reader.open("pb.ppm") {|r| r.header })
        assert_equal(["x", "y", "component", "value"], Tb::Reader.open("pnm:pb") {|r| r.header })

        assert_equal(["x", "y", "component", "value"], Tb::Reader.open("pbm:ba") {|r| r.header })
        assert_equal(["x", "y", "component", "value"], Tb::Reader.open("pgm:ga") {|r| r.header })
        assert_equal(["x", "y", "component", "value"], Tb::Reader.open("ppm:pa") {|r| r.header })
        assert_equal(["x", "y", "component", "value"], Tb::Reader.open("pbm:bb") {|r| r.header })
        assert_equal(["x", "y", "component", "value"], Tb::Reader.open("pgm:gb") {|r| r.header })
        assert_equal(["x", "y", "component", "value"], Tb::Reader.open("ppm:pb") {|r| r.header })

        assert_equal(["x", "y", "component", "value"], Tb::Reader.open("ba.pnm") {|r| r.header })
        assert_equal(["x", "y", "component", "value"], Tb::Reader.open("ga.pnm") {|r| r.header })
        assert_equal(["x", "y", "component", "value"], Tb::Reader.open("pa.pnm") {|r| r.header })
        assert_equal(["x", "y", "component", "value"], Tb::Reader.open("bb.pnm") {|r| r.header })
        assert_equal(["x", "y", "component", "value"], Tb::Reader.open("gb.pnm") {|r| r.header })
        assert_equal(["x", "y", "component", "value"], Tb::Reader.open("pb.pnm") {|r| r.header })
      }
    }
  end

end
