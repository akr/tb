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
    assert(!iter.closed?)
    assert_raise(StopIteration) { iter.peek }
    assert(iter.closed?)
    assert_raise(StopIteration) { iter.next }
    assert(iter.closed?)
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
    assert(!iter.closed?)
    assert_raise(StopIteration) { iter.peek_values }
    assert(iter.closed?)
    assert_raise(StopIteration) { iter.next_values }
    assert(iter.closed?)
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
    assert(!iter.closed?)
    assert_raise(StopIteration) { iter.next }
    assert(iter.closed?)
    assert_raise(ArgumentError) { iter.rewind }
    assert(iter.closed?)
  end

  def test_reader_pos
    ary = [1,2,3]
    fe = ary.to_fileenumerator
    iter = fe.each
    assert_respond_to(iter, :next)
    assert_respond_to(iter, :peek)
    pos1 = iter.pos
    assert_equal(1, iter.peek)
    assert_equal(pos1, iter.pos)
    assert_equal(1, iter.peek)
    assert_equal(pos1, iter.pos)
    assert_equal(1, iter.next)
    pos2 = iter.pos
    assert_not_equal(pos1, pos2)
    assert_equal(2, iter.peek)
    assert_equal(pos2, iter.pos)
    assert_equal(2, iter.next)
    assert_equal(3, iter.next)
    posEnd = iter.pos
    iter.pos = pos2
    assert_equal(2, iter.next)
    iter.pos = pos1
    assert_equal(1, iter.next)
    iter.pos = posEnd
    assert(!iter.closed?)
    assert_raise(StopIteration) { iter.next }
    assert(iter.closed?)
  end

  def test_reader_use
    ary = [1,2]
    fe = ary.to_fileenumerator
    iter = fe.each
    iter.use {
      assert_equal(1, iter.next)
      pos2 = iter.pos
      assert_equal(2, iter.next)
      assert_raise(StopIteration) { iter.next }
      iter.pos = pos2
      assert_equal(2, iter.next)
      assert_raise(StopIteration) { iter.next }
      assert(!iter.closed?)
    }
    assert(iter.closed?)
  end

  def test_open_reader
    ary = [1,2]
    fe = ary.to_fileenumerator
    iter0 = nil
    fe.open_reader {|iter|
      iter0 = iter
      assert_equal(1, iter.next)
      pos2 = iter.pos
      assert_equal(2, iter.next)
      assert_raise(StopIteration) { iter.next }
      iter.pos = pos2
      assert_equal(2, iter.next)
      assert_raise(StopIteration) { iter.next }
      assert(!iter.closed?)
    }
    assert(iter0.closed?)
  end

  def test_open_reader
    ary = [1,2]
    fe = ary.to_fileenumerator
    iter0 = nil
    fe.open_reader {|iter|
      iter0 = iter
      assert_equal(1, iter.next)
      pos2 = iter.pos
      assert_equal(2, iter.next)
      assert_raise(StopIteration) { iter.next }
      iter.pos = pos2
      assert_equal(2, iter.next)
      assert_raise(StopIteration) { iter.next }
      assert(!iter.closed?)
    }
    assert(iter0.closed?)
  end

  def test_to_fileheaderenumerator_reader
    tb = Tb.new %w[a b], [1, 2], [3, 4]
    fe = tb.to_fileenumerator
    iter = fe.each
    assert_respond_to(iter, :next)
    assert_respond_to(iter, :peek)
    assert_equal([["a", 1], ["b", 2]], iter.peek.to_a)
    assert_equal([["a", 1], ["b", 2]], iter.peek.to_a)
    assert_equal([["a", 1], ["b", 2]], iter.next.to_a)
    assert_equal([["a", 3], ["b", 4]], iter.peek.to_a)
    assert_equal([["a", 3], ["b", 4]], iter.next.to_a)
    assert(!iter.closed?)
    assert_raise(StopIteration) { iter.peek }
    assert(iter.closed?)
    assert_raise(StopIteration) { iter.next }
    assert(iter.closed?)
  end

  def test_to_fileheaderenumerator_with_header_reader
    tb = Tb.new %w[a b], [1, 2], [3, 4]
    header = nil
    fe = tb.with_header {|h0|
      header = h0
    }.to_fileenumerator
    assert_equal(%w[a b], header)
    iter = fe.each
    assert_respond_to(iter, :next)
    assert_respond_to(iter, :peek)
    assert_equal([["a", 1], ["b", 2]], iter.peek.to_a)
    assert_equal([["a", 1], ["b", 2]], iter.peek.to_a)
    assert_equal([["a", 1], ["b", 2]], iter.next.to_a)
    assert_equal([["a", 3], ["b", 4]], iter.peek.to_a)
    assert_equal([["a", 3], ["b", 4]], iter.next.to_a)
    assert(!iter.closed?)
    assert_raise(StopIteration) { iter.peek }
    assert(iter.closed?)
    assert_raise(StopIteration) { iter.next }
    assert(iter.closed?)
  end

  def test_fileheaderenumerator_open_reader
    tb = Tb.new %w[a b], [1, 2], [3, 4]
    fe = tb.to_fileenumerator
    iter0 = nil
    fe.open_reader {|iter|
      iter0 = iter
      assert_respond_to(iter, :next)
      assert_respond_to(iter, :peek)
      assert_equal([["a", 1], ["b", 2]], iter.peek.to_a)
      assert_equal([["a", 1], ["b", 2]], iter.peek.to_a)
      assert_equal([["a", 1], ["b", 2]], iter.next.to_a)
      assert_equal([["a", 3], ["b", 4]], iter.peek.to_a)
      assert_equal([["a", 3], ["b", 4]], iter.next.to_a)
      assert_raise(StopIteration) { iter.peek }
      assert_raise(StopIteration) { iter.next }
      assert(!iter.closed?)
    }
    assert(iter0.closed?)
  end
end
