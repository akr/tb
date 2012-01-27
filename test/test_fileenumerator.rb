require 'tb'
require 'test/unit'

class TestTbFileEnumerator < Test::Unit::TestCase
  def test_basic
    en = Tb::FileEnumerator.new_tempfile {|gen|
      gen.call 1
      gen.call 2
      gen.call 3
    }
    ary = []
    en.each {|v|
      ary << v
    }
    assert_equal([1, 2, 3], ary)
  end

  def test_removed_after_simple_use
    en = Tb::FileEnumerator.new_tempfile {|gen|
    }
    assert_nothing_raised { en.each {|v| } }
    assert_raise(ArgumentError) { en.each {|v| } }
  end

  def test_removed_after_wrapped_use
    en = Tb::FileEnumerator.new_tempfile {|gen|
    }
    en.use {
      assert_nothing_raised { en.each {|v| } }
      assert_nothing_raised { en.each {|v| } }
    }
    assert_raise(ArgumentError) { en.each {|v| } }
  end

  def test_to_fileenumerator
    obj = [1,2,3]
    en = obj.to_fileenumerator
    assert_kind_of(Tb::FileEnumerator, en)
    assert_not_kind_of(Tb::FileHeaderEnumerator, en)
    ary = []
    en.each {|v|
      ary << v
    }
    assert_equal([1, 2, 3], ary)
  end

  def test_to_fileheaderenumerator
    er = Tb::Enumerator.new {|y|
      y.set_header %w[a b]
      y.yield({"a"=>1, "b"=>2})
      y.yield({"a"=>3})
    }
    en = er.to_fileenumerator
    assert_kind_of(Tb::FileEnumerator, en)
    assert_kind_of(Tb::FileHeaderEnumerator, en)
    ary = []
    en.each {|v|
      ary << v
    }
    assert_equal([{"a"=>1, "b"=>2}, {"a"=>3}], ary)
  end

  def test_reader_basic
    ary = [1,2,3]
    fe = ary.to_fileenumerator
    iter = fe.each
    assert_respond_to(iter, :next)
    assert_respond_to(iter, :peek)
    assert_equal(1, iter.peek)
    assert_equal(1, iter.peek)
    assert_equal(1, iter.next)
    assert_equal(2, iter.peek)
    assert_equal(2, iter.next)
    assert_equal(3, iter.next)
    assert_raise(StopIteration) { iter.peek }
    assert_raise(StopIteration) { iter.next }
  end

  def test_reader_values
    o = Object.new
    def o.each
      yield
      yield 1
      yield 1, 2
    end
    o.extend Enumerable
    fe = o.to_fileenumerator
    iter = fe.each
    assert_respond_to(iter, :next_values)
    assert_respond_to(iter, :peek_values)
    assert_equal([], iter.peek_values)
    assert_equal([], iter.peek_values)
    assert_equal([], iter.next_values)
    assert_equal([1], iter.peek_values)
    assert_equal([1], iter.next_values)
    assert_equal([1,2], iter.next_values)
    assert_raise(StopIteration) { iter.peek_values }
    assert_raise(StopIteration) { iter.next_values }
  end

  def test_reader_rewind
    ary = [1,2,3]
    fe = ary.to_fileenumerator
    iter = fe.each
    assert_equal(1, iter.next)
    assert_equal(2, iter.next)
    iter.rewind
    assert_equal(1, iter.next)
    assert_equal(2, iter.next)
    assert_equal(3, iter.next)
    assert_raise(StopIteration) { iter.next }
    assert_raise(ArgumentError) { iter.rewind }
  end

end
