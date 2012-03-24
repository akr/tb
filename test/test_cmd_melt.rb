require 'test/unit'
require 'tb/cmdtop'
require 'tmpdir'

class TestTbCmdMelt < Test::Unit::TestCase
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
      a,b,c,d
      0,1,2,3
      4,5,6,7
      8,9,a,b
      c,d,e,f
    End
    Tb::Cmd.main_melt(['-o', o="o.csv", 'a,b', i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b,variable,value
      0,1,c,2
      0,1,d,3
      4,5,c,6
      4,5,d,7
      8,9,c,a
      8,9,d,b
      c,d,c,e
      c,d,d,f
    End
  end

  def test_recnum
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b,c,d
      0,1,2,3
      4,5,6,7
      8,9,a,b
      c,d,e,f
    End
    Tb::Cmd.main_melt(['-o', o="o.csv", 'a,b', '--recnum', i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      recnum,a,b,variable,value
      1,0,1,c,2
      1,0,1,d,3
      2,4,5,c,6
      2,4,5,d,7
      3,8,9,c,a
      3,8,9,d,b
      4,c,d,c,e
      4,c,d,d,f
    End
  end

  def test_variable_field
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b,c,d
      0,1,2,3
      4,5,6,7
      8,9,a,b
      c,d,e,f
    End
    Tb::Cmd.main_melt(['-o', o="o.csv", 'a,b', '--variable-field=foo', i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b,foo,value
      0,1,c,2
      0,1,d,3
      4,5,c,6
      4,5,d,7
      8,9,c,a
      8,9,d,b
      c,d,c,e
      c,d,d,f
    End
  end

  def test_value_field
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b,c,d
      0,1,2,3
      4,5,6,7
      8,9,a,b
      c,d,e,f
    End
    Tb::Cmd.main_melt(['-o', o="o.csv", 'a,b', '--value-field=bar', i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b,variable,bar
      0,1,c,2
      0,1,d,3
      4,5,c,6
      4,5,d,7
      8,9,c,a
      8,9,d,b
      c,d,c,e
      c,d,d,f
    End
  end

  def test_melt_regexp
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b,c,d
      0,1,2,3
      4,5,6,7
      8,9,a,b
      c,d,e,f
    End
    Tb::Cmd.main_melt(['-o', o="o.csv", 'a', '--melt-regexp=[bd]', i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,variable,value
      0,b,1
      0,d,3
      4,b,5
      4,d,7
      8,b,9
      8,d,b
      c,b,d
      c,d,f
    End
  end

  def test_melt_list
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b,c,d
      0,1,2,3
      4,5,6,7
      8,9,a,b
      c,d,e,f
    End
    Tb::Cmd.main_melt(['-o', o="o.csv", 'a', '--melt-fields=b,d', i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,variable,value
      0,b,1
      0,d,3
      4,b,5
      4,d,7
      8,b,9
      8,d,b
      c,b,d
      c,d,f
    End
  end

end
