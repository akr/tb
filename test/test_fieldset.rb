require 'test/unit'

class TestTbFieldSet < Test::Unit::TestCase
  def test_new
    assert_equal([], Tb::FieldSet.new.header)
    assert_equal(['a'], Tb::FieldSet.new('a').header)
    assert_equal(['a', 'b'], Tb::FieldSet.new('a', 'b').header)
  end

  def test_index_from_field
    assert_equal(0, Tb::FieldSet.new('a').index_from_field('a'))
    assert_equal(0, Tb::FieldSet.new('a', 'b').index_from_field('a'))
    assert_equal(1, Tb::FieldSet.new('a', 'b').index_from_field('b'))
    assert_raise(ArgumentError) { Tb::FieldSet.new('a', 'b').index_from_field('c') }
  end

  def test_field_from_index_ex
    fs = Tb::FieldSet.new('a', 'b')
    assert_equal('a', fs.field_from_index_ex(0))
    assert_equal('b', fs.field_from_index_ex(1))
    assert_equal('', fs.field_from_index_ex(2)) # xxx
    assert_equal('(2)', fs.field_from_index_ex(3)) # xxx
  end

  def test_field_from_index
    fs = Tb::FieldSet.new('a', 'b')
    assert_equal('a', fs.field_from_index(0))
    assert_equal('b', fs.field_from_index(1))
    assert_raise(ArgumentError) { fs.field_from_index(2) }
  end

  def test_length
    fs = Tb::FieldSet.new('a', 'b')
    assert_equal(2, fs.length)
  end

end
