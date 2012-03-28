require 'test/unit'
require 'tb/cmdtop'
require 'tmpdir'

class TestTbCmdUnmelt < Test::Unit::TestCase
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
      a,b,variable,value
      0,1,x,3
      0,1,y,7
      4,5,x,b
      4,5,y,f
    End
    Tb::Cmd.main_unmelt(['-o', o="o.csv", i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b,x,y
      0,1,3,7
      4,5,b,f
    End
  end

  def test_json
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b,variable,value
      0,1,x,3
      0,1,y,7
      4,5,x,b
      4,5,y,f
    End
    Tb::Cmd.main_unmelt(['-o', o="o.json", i])
    assert_equal(<<-"End".gsub(/\s+/, ''), File.read(o).gsub(/\s+/, ''))
      [
        {"a":"0", "b":"1", "x":"3", "y":"7"},
        {"a":"4", "b":"5", "x":"b", "y":"f"}
      ]
    End
  end

  def test_keys
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b,variable,value
      0,1,x,3
      0,1,y,7
      4,5,x,b
      4,5,y,f
    End
    Tb::Cmd.main_unmelt(['-o', o="o.csv", '--keys=a', i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,x,y
      0,3,7
      4,b,f
    End
  end

  def test_recnum_noneffective
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      recnum,a,b,variable,value
      1,0,1,x,3
      1,0,1,y,7
      2,4,5,x,b
      2,4,5,y,f
    End
    Tb::Cmd.main_unmelt(['-o', o="o.csv", '--keys=a,b', '--recnum', i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b,x,y
      0,1,3,7
      4,5,b,f
    End
  end

  def test_recnum_effective
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      recnum,a,b,variable,value
      1,0,1,x,3
      2,0,1,y,f
    End
    Tb::Cmd.main_unmelt(['-o', o="o.csv", '--keys=a,b', '--recnum', i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b,x,y
      0,1,3
      0,1,,f
    End
  end

  def test_recnum_value
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      r,a,b,variable,value
      1,0,1,x,3
      2,0,1,y,f
    End
    Tb::Cmd.main_unmelt(['-o', o="o.csv", '--keys=a,b', '--recnum=r', i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b,x,y
      0,1,3
      0,1,,f
    End
  end

  def test_variable_field
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b,foo,value
      0,1,x,3
      0,1,y,7
      4,5,x,b
      4,5,y,f
    End
    Tb::Cmd.main_unmelt(['-o', o="o.csv", '--variable-field=foo', i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b,x,y
      0,1,3,7
      4,5,b,f
    End
  end

  def test_value_field
    File.open(i="i.csv", "w") {|f| f << <<-"End".gsub(/^[ \t]+/, '') }
      a,b,variable,bar
      0,1,x,3
      0,1,y,7
      4,5,x,b
      4,5,y,f
    End
    Tb::Cmd.main_unmelt(['-o', o="o.csv", '--value-field=bar', i])
    assert_equal(<<-"End".gsub(/^[ \t]+/, ''), File.read(o))
      a,b,x,y
      0,1,3,7
      4,5,b,f
    End
  end

end
