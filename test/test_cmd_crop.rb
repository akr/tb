require 'test/unit'
require 'tb/cmdtop'
require 'tmpdir'

class TestTbCmdCrop < Test::Unit::TestCase
  def setup
    Tb::Cmd.reset_option
    @curdir = Dir.pwd
    @tmpdir = Dir.mktmpdir
    Dir.chdir @tmpdir
  end
  def teardown
    Tb::Cmd.reset_option
    Dir.chdir @curdir
    FileUtils.rmtree @tmpdir
  end

  def test_basic
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      ,,
      ,a,b,,
      ,0,1,,,
      ,4,,,
      ,,,

    End
    assert_equal(true, Tb::Cmd.main_crop(['-o', o="o.csv", i]))
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b
      0,1
      4
    End
  end

  def test_a1_range
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b,c,d
      0,1,2,3
      4,5,6,7
      8,9,a,b
      c,d,e,f
    End
    Tb::Cmd.main_crop(['-o', o="o.csv", '-r', 'B1:C2', i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      b,c
      1,2
    End
  end

  def test_r1c1_range
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b,c,d
      0,1,2,3
      4,5,6,7
      8,9,a,b
      c,d,e,f
    End
    Tb::Cmd.main_crop(['-o', o="o.csv", '-r', 'R2C1:R3C2', i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      0,1
      4,5
    End
  end

  def test_invalid_range
    assert_raise(ArgumentError,) { Tb::Cmd.main_crop(['-r', 'foo']) }
  end

  def test_decode_a1_addressing_col
    assert_equal(1, Tb::Cmd.decode_a1_addressing_col("A"))
    assert_equal(26, Tb::Cmd.decode_a1_addressing_col("Z"))
    ("A".."Z").each_with_index {|ch, i|
      assert_equal(i+1, Tb::Cmd.decode_a1_addressing_col(ch))
    }
    assert_equal(27, Tb::Cmd.decode_a1_addressing_col("AA"))
    assert_equal(256, Tb::Cmd.decode_a1_addressing_col("IV"))
    assert_equal(16384, Tb::Cmd.decode_a1_addressing_col("XFD"))
  end

end
