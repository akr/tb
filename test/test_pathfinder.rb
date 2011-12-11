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
        [:rmove, :south], "d",
        [:rmove, :west], "c",
        [:rmove, :north], "a",
        [:rmove, :east], "b"],
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

end
