require 'tb'
require 'test/unit'

class TestTbPathFinder < Test::Unit::TestCase
  def test_strary_to_aa
    assert_equal([["a", "b"], ["c", "d"]],
                 Tb::Pathfinder.strary_to_aa(["ab", "cd"]))
  end

  def test_match
    ret = Tb::Pathfinder.match(
      "b",
      [%w[a b],
       %w[c d]])
    spos, epos, _ = ret
    assert_equal([1, 0], spos)
    assert_equal([1, 0], epos)
  end

  def test_each_match_with_spos
    res = []
    Tb::Pathfinder.each_match(
      "b",
      [%w[a b],
       %w[c d]],
      [1,0]) {|spos, epos, cap|
      res << [spos, epos, cap]
    }
    assert_equal(1, res.size)
    spos, epos, _ = res[0]
    assert_equal([1, 0], spos)
    assert_equal([1, 0], epos)
  end

  def test_each_match_without_spos
    res = []
    Tb::Pathfinder.each_match(
      "b",
      [%w[a b],
       %w[c d]]) {|spos, epos, cap|
      res << [spos, epos, cap]
    }
    assert_equal(1, res.size)
    spos, epos, _ = res[0]
    assert_equal([1, 0], spos)
    assert_equal([1, 0], epos)
  end

  def test_pat_nil
    res = []
    Tb::Pathfinder.each_match(
      nil,
      [%w[a b],
       %w[c d]],
      [1,0]) {|spos, epos, cap|
      res << [spos, epos, cap]
    }
    assert_equal(1, res.size)
    spos, epos, _ = res[0]
    assert_equal([1, 0], spos)
    assert_equal([1, 0], epos)
  end

  def test_pat_regexp1
    res = []
    Tb::Pathfinder.each_match(
      /[bc]/,
      [%w[a b],
       %w[c d]]) {|spos, epos, cap|
      res << [spos, epos, cap]
    }
    assert_equal(2, res.size)
    assert_equal([[1,0], [1,0]], res[0][0..1])
    assert_equal([[0,1], [0,1]], res[1][0..1])
  end

  def test_pat_regexp2
    res = []
    Tb::Pathfinder.each_match(
      [:regexp, /[bc]/],
      [%w[a b],
       %w[c d]]) {|spos, epos, cap|
      res << [spos, epos, cap]
    }
    assert_equal(2, res.size)
    assert_equal([[1,0], [1,0]], res[0][0..1])
    assert_equal([[0,1], [0,1]], res[1][0..1])
  end

  def test_pat_alt
    res = []
    Tb::Pathfinder.each_match(
      [:alt, "b", "c"],
      [%w[a b],
       %w[c d]]) {|spos, epos, cap|
      res << [spos, epos, cap]
    }
    assert_equal(2, res.size)
    assert_equal([[1,0], [1,0]], res[0][0..1])
    assert_equal([[0,1], [0,1]], res[1][0..1])
  end

  def test_pat_lit
    res = []
    Tb::Pathfinder.each_match(
      [:lit, "b"],
      [%w[a b],
       %w[c d]]) {|spos, epos, cap|
      res << [spos, epos, cap]
    }
    assert_equal(1, res.size)
    assert_equal([[1,0], [1,0]], res[0][0..1])
  end

  def test_pat_nsew
    res = []
    Tb::Pathfinder.each_match(
      [:cat, "b", :s, "d", :w, "c", :n, "a", :e, "b"],
      [%w[a b],
       %w[c d]]) {|spos, epos, cap|
      res << [spos, epos, cap]
    }
    assert_equal(1, res.size)
    assert_equal([[1,0], [1,0]], res[0][0..1])
  end

  def test_pat_rmove
    res = []
    Tb::Pathfinder.each_match(
      [:cat, "b",
        [:rmove, 0, 1], "d",
        [:rmove, -1, 0], "c",
        [:rmove, 0, -1], "a",
        [:rmove, 1, 0], "b"],
      [%w[a b],
       %w[c d]]) {|spos, epos, cap|
      res << [spos, epos, cap]
    }
    assert_equal(1, res.size)
    assert_equal([[1,0], [1,0]], res[0][0..1])
  end

  def test_pat_rep
    res = []
    Tb::Pathfinder.each_match(
      [:cat, "a", :e, [:rep, "b", :e]],
      [%w[a b b d],
       %w[c d c d]]) {|spos, epos, cap|
      res << [spos, epos, cap]
    }
    assert_equal(3, res.size)
    assert_equal([[0,0], [3,0]], res[0][0..1])
    assert_equal([[0,0], [2,0]], res[1][0..1])
    assert_equal([[0,0], [1,0]], res[2][0..1])
  end

  def test_pat_rep_to_boundary
    res = []
    Tb::Pathfinder.each_match(
      [:rep, "a", :e],
      [%w[a a]],
      [0,0]) {|spos, epos, cap|
      res << [spos, epos, cap]
    }
    assert_equal(3, res.size)
    assert_equal([[0,0], [2,0]], res[0][0..1])
    assert_equal([[0,0], [1,0]], res[1][0..1])
    assert_equal([[0,0], [0,0]], res[2][0..1])
  end

  def test_pat_rep1
    res = []
    Tb::Pathfinder.each_match(
      [:cat, "a", :e, [:rep1, "b", :e]],
      [%w[a b b d],
       %w[c d c d]]) {|spos, epos, cap|
      res << [spos, epos, cap]
    }
    assert_equal(2, res.size)
    assert_equal([[0,0], [3,0]], res[0][0..1])
    assert_equal([[0,0], [2,0]], res[1][0..1])
  end

  def test_pat_rep_nongreedy
    res = []
    Tb::Pathfinder.each_match(
      [:cat, "a", :e, [:rep_nongreedy, "b", :e]],
      [%w[a b b d],
       %w[c d c d]]) {|spos, epos, cap|
      res << [spos, epos, cap]
    }
    assert_equal(3, res.size)
    assert_equal([[0,0], [1,0]], res[0][0..1])
    assert_equal([[0,0], [2,0]], res[1][0..1])
    assert_equal([[0,0], [3,0]], res[2][0..1])
  end

  def test_pat_rep1_nongreedy
    res = []
    Tb::Pathfinder.each_match(
      [:cat, "a", :e, [:rep1_nongreedy, "b", :e]],
      [%w[a b b d],
       %w[c d c d]]) {|spos, epos, cap|
      res << [spos, epos, cap]
    }
    assert_equal(2, res.size)
    assert_equal([[0,0], [2,0]], res[0][0..1])
    assert_equal([[0,0], [3,0]], res[1][0..1])
  end

  def test_pat_opt
    res = []
    Tb::Pathfinder.each_match(
      [:cat, "a", :e, [:opt, "b", :e]],
      [%w[a b b d],
       %w[c d c d]]) {|spos, epos, cap|
      res << [spos, epos, cap]
    }
    assert_equal(2, res.size)
    assert_equal([[0,0], [2,0]], res[0][0..1])
    assert_equal([[0,0], [1,0]], res[1][0..1])
  end

  def test_pat_opt_nongreedy
    res = []
    Tb::Pathfinder.each_match(
      [:cat, "a", :e, [:opt_nongreedy, "b", :e]],
      [%w[a b b d],
       %w[c d c d]]) {|spos, epos, cap|
      res << [spos, epos, cap]
    }
    assert_equal(2, res.size)
    assert_equal([[0,0], [1,0]], res[0][0..1])
    assert_equal([[0,0], [2,0]], res[1][0..1])
  end

  def test_pat_repn
    res = []
    Tb::Pathfinder.each_match(
      [:cat, "a", :e, [:repn, 2, "b", :e]],
      [%w[a b b b d],
       %w[c d c d x]]) {|spos, epos, cap|
      res << [spos, epos, cap]
    }
    assert_equal(1, res.size)
    assert_equal([[0,0], [3,0]], res[0][0..1])
  end

  def test_pat_repeat
    res = []
    Tb::Pathfinder.each_match(
      [:cat, "a", :e, [:repeat, :v, 1, 2, "b", :e]],
      [%w[a b b b d],
       %w[c d c d x]]) {|spos, epos, cap|
      res << [spos, epos, cap]
    }
    assert_equal(2, res.size)
    assert_equal([[0,0], [3,0]], res[0][0..1])
    assert_equal(2, res[0][2][:v])
    assert_equal([[0,0], [2,0]], res[1][0..1])
    assert_equal(1, res[1][2][:v])
  end

  def test_pat_repeat_empty
    res = []
    Tb::Pathfinder.each_match(
      [:rep, [:rep, "a", :e]],
      [%w[a a b]],
      [0,0]) {|spos, epos, cap|
      res << [spos, epos, cap]
    }
    assert_equal(4, res.size)
    assert_equal([[0,0], [2,0]], res[0][0..1])
    assert_equal([[0,0], [2,0]], res[1][0..1])
    assert_equal([[0,0], [1,0]], res[2][0..1])
    assert_equal([[0,0], [0,0]], res[3][0..1])
  end

  def test_pat_bfs
    res = []
    Tb::Pathfinder.each_match(
      [:bfs, [:pos], [:cat, [:alt, :e, :s], "a"]],
      [%w[a a a a a],
       %w[a b b b b],
       %w[a b b b b]],
      [0,0]) {|spos, epos, cap|
      res << [spos, epos, cap]
    }
    assert_equal(7, res.size)
    assert_equal([[0, 0], [0, 0], Tb::Pathfinder::EmptyState], res[0])
    assert_equal([[0, 0], [1, 0], Tb::Pathfinder::EmptyState], res[1])
    assert_equal([[0, 0], [0, 1], Tb::Pathfinder::EmptyState], res[2])
    assert_equal([[0, 0], [2, 0], Tb::Pathfinder::EmptyState], res[3])
    assert_equal([[0, 0], [0, 2], Tb::Pathfinder::EmptyState], res[4])
    assert_equal([[0, 0], [3, 0], Tb::Pathfinder::EmptyState], res[5])
    assert_equal([[0, 0], [4, 0], Tb::Pathfinder::EmptyState], res[6])
  end

  def test_pat_grid_start_goal
    res = []
    Tb::Pathfinder.each_match(
      [:grid,
        [:start, "b", "a"],
        ["b",    "a", "b"],
        ["a",    "b", :goal]],
      [%w[a b a b a],
       %w[b a b a b],
       %w[a b a b a]]) {|spos, epos, cap|
      res << [spos, epos, cap]
    }
    assert_equal(2, res.size)
    assert_equal([[0, 0], [2, 2], Tb::Pathfinder::EmptyState], res[0])
    assert_equal([[2, 0], [4, 2], Tb::Pathfinder::EmptyState], res[1])
  end

  def test_pat_grid_start_goal_with_pattern
    res = []
    Tb::Pathfinder.each_match(
      [:grid,
        [[:start, "a"], "b", "a"],
        ["b",           "a", "b"],
        ["a",           "b", [:goal, "a"]]],
      [%w[a b a b a],
       %w[b a b a b],
       %w[a b a b a]]) {|spos, epos, cap|
      res << [spos, epos, cap]
    }
    assert_equal(2, res.size)
    assert_equal([[0, 0], [2, 2], Tb::Pathfinder::EmptyState], res[0])
    assert_equal([[2, 0], [4, 2], Tb::Pathfinder::EmptyState], res[1])
  end

  def test_pat_grid_origin
    res = []
    Tb::Pathfinder.each_match(
      [:grid,
        ["a", "b",     "a"],
        ["b", :origin, "b"],
        ["a", "b",     "a"]],
      [%w[a b a b a],
       %w[b a b a b],
       %w[a b a b a]]) {|spos, epos, cap|
      res << [spos, epos, cap]
    }
    assert_equal(2, res.size)
    assert_equal([[1, 1], [1, 1], Tb::Pathfinder::EmptyState], res[0])
    assert_equal([[3, 1], [3, 1], Tb::Pathfinder::EmptyState], res[1])
  end

  def test_pat_grid_origin_with_pattern
    res = []
    Tb::Pathfinder.each_match(
      [:grid,
        ["a", "b",            "a"],
        ["b", [:origin, "a"], "b"],
        ["a", "b",            "a"]],
      [%w[a b a b a],
       %w[b a b a b],
       %w[a b a b a]]) {|spos, epos, cap|
      res << [spos, epos, cap]
    }
    assert_equal(2, res.size)
    assert_equal([[1, 1], [1, 1], Tb::Pathfinder::EmptyState], res[0])
    assert_equal([[3, 1], [3, 1], Tb::Pathfinder::EmptyState], res[1])
  end

  def test_pat_capval
    res = []
    Tb::Pathfinder.each_match(
      [:capval, :name],
      [%w[a b]]) {|spos, epos, cap|
      res << [spos, epos, cap]
    }
    assert_equal(2, res.size)
    assert_equal([[0, 0], [0, 0], Tb::Pathfinder::State.make(:name => "a")], res[0])
    assert_equal([[1, 0], [1, 0], Tb::Pathfinder::State.make(:name => "b")], res[1])
  end

  def test_pat_refval
    res = []
    Tb::Pathfinder.each_match(
      [:cat, [:capval, :name], [:rep1, :e, [:refval, :name]]],
      [%w[a a b b b c]]) {|spos, epos, cap|
      res << [spos, epos, cap]
    }
    assert_equal(4, res.size)
    assert_equal([[0, 0], [1, 0], Tb::Pathfinder::State.make(:name => "a")], res[0])
    assert_equal([[2, 0], [4, 0], Tb::Pathfinder::State.make(:name => "b")], res[1])
    assert_equal([[2, 0], [3, 0], Tb::Pathfinder::State.make(:name => "b")], res[2])
    assert_equal([[3, 0], [4, 0], Tb::Pathfinder::State.make(:name => "b")], res[3])
  end

  def test_pat_tmp_pos
    res = []
    Tb::Pathfinder.each_match(
      [:cat, "a", [:tmp_pos, 1, 0, "b"]],
      [%w[a b a a b b]]) {|spos, epos, cap|
      res << [spos, epos, cap]
    }
    assert_equal(2, res.size)
    assert_equal([[0, 0], [0, 0], Tb::Pathfinder::EmptyState], res[0])
    assert_equal([[3, 0], [3, 0], Tb::Pathfinder::EmptyState], res[1])
  end

  def test_pat_save_pos
    res = []
    Tb::Pathfinder.each_match(
      [:cat, "a", [:save_pos, :n]],
      [%w[a b a a b b]]) {|spos, epos, cap|
      res << [spos, epos, cap]
    }
    assert_equal(3, res.size)
    assert_equal([[0, 0], [0, 0], Tb::Pathfinder::State.make(:n => [0,0])], res[0])
    assert_equal([[2, 0], [2, 0], Tb::Pathfinder::State.make(:n => [2,0])], res[1])
    assert_equal([[3, 0], [3, 0], Tb::Pathfinder::State.make(:n => [3,0])], res[2])
  end

  def test_pat_push_pos
    res = []
    Tb::Pathfinder.each_match(
      [:rep1, "a", [:push_pos, :n], :e],
      [%w[a b a a b b]]) {|spos, epos, cap|
      res << [spos, epos, cap]
    }
    assert_equal(4, res.size)
    assert_equal([[0, 0], [1, 0], Tb::Pathfinder::State.make(:n => [[0,0]])], res[0])
    assert_equal([[2, 0], [4, 0], Tb::Pathfinder::State.make(:n => [[2,0],[3,0]])], res[1])
    assert_equal([[2, 0], [3, 0], Tb::Pathfinder::State.make(:n => [[2,0]])], res[2])
    assert_equal([[3, 0], [4, 0], Tb::Pathfinder::State.make(:n => [[3,0]])], res[3])
  end

  def test_pat_pop_pos
    res = []
    Tb::Pathfinder.each_match(
      [:cat, [:push_pos, :n], "a", :e, "b", [:pop_pos, :n]],
      [%w[a b a a b b]]) {|spos, epos, cap|
      res << [spos, epos, cap]
    }
    assert_equal(2, res.size)
    assert_equal([[0, 0], [0, 0], Tb::Pathfinder::State.make(:n => [])], res[0])
    assert_equal([[3, 0], [3, 0], Tb::Pathfinder::State.make(:n => [])], res[1])
  end

  def test_pat_update
    res = []
    Tb::Pathfinder.each_match(
      [:cat,
        [:capval, :n],
        [:update, lambda {|st| st.merge(:n => st[:n].succ) }],
        :e,
        [:refval, :n]],
      [%w[a a b b b c]]) {|spos, epos, cap|
      res << [spos, epos, cap]
    }
    assert_equal(2, res.size)
    assert_equal([[1, 0], [2, 0], Tb::Pathfinder::State.make(:n => "b")], res[0])
    assert_equal([[4, 0], [5, 0], Tb::Pathfinder::State.make(:n => "c")], res[1])
  end

  def test_pat_assert
    res = []
    Tb::Pathfinder.each_match(
      [:cat,
        [:capval, :n],
        [:assert, lambda {|st| st[:n] == 'a' }]],
      [%w[a a b b b c]]) {|spos, epos, cap|
      res << [spos, epos, cap]
    }
    assert_equal(2, res.size)
    assert_equal([[0, 0], [0, 0], Tb::Pathfinder::State.make(:n => "a")], res[0])
    assert_equal([[1, 0], [1, 0], Tb::Pathfinder::State.make(:n => "a")], res[1])
  end

  def test_pat_invalid_tag_in_array
    assert_raise(ArgumentError) {
      Tb::Pathfinder.each_match(
        [:foo],
        [%w[a b c]]) {|spos, epos, cap|
      }
    }
  end

  def test_pat_invalid
    assert_raise(ArgumentError) {
      Tb::Pathfinder.each_match(
        Object.new,
        [%w[a b c]]) {|spos, epos, cap|
      }
    }
  end

  def test_emptystate_to_h
    s = Tb::Pathfinder::EmptyState
    assert_equal({}, s.to_h)
  end

  def test_emptystate_fetch
    s = Tb::Pathfinder::EmptyState
    assert_equal("foo", s.fetch(:k) {|k| assert_equal(:k, k); "foo" })
    assert_equal("bar", s.fetch(:k, "bar"))
    if defined? KeyError
      assert_raise(KeyError) { s.fetch(:k) } # Ruby 1.9
    else
      assert_raise(IndexError) { s.fetch(:k) } # Ruby 1.8
    end
  end

  def test_emptystate_values_at
    s = Tb::Pathfinder::EmptyState
    assert_equal([], s.values_at())
    assert_equal([nil, nil, nil], s.values_at(:x, :y, :z))
  end

  def test_emptystate_keys
    s = Tb::Pathfinder::EmptyState
    assert_equal([], s.keys)
  end

  def test_emptystate_reject
    s = Tb::Pathfinder::EmptyState
    assert_equal(Tb::Pathfinder::EmptyState, s.reject {|k, v| flunk })
  end

  def test_emptystate_inspect
    s = Tb::Pathfinder::EmptyState
    assert_kind_of(String, s.inspect)
  end

  def test_state_fetch
    s = Tb::Pathfinder::State.make(:k => 1)
    assert_equal(1, s.fetch(:k))
    assert_equal(:foo, s.fetch(:x) {|k| assert_equal(:x, k); :foo })
    if defined? KeyError
      assert_raise(KeyError) { s.fetch(:x) } # Ruby 1.9
    else
      assert_raise(IndexError) { s.fetch(:x) } # Ruby 1.8
    end
  end

  def test_state_keys
    s = Tb::Pathfinder::State.make(:k => 1)
    assert_equal([:k], s.keys)
  end

  def test_state_inspect
    s = Tb::Pathfinder::State.make(:k => 1)
    assert_kind_of(String, s.inspect)
  end

end
