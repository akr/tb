require 'tb'
require 'test/unit'

class TestTbRecord < Test::Unit::TestCase
  def test_pretty_print
    t = Tb.new %w[fruit color],
               %w[apple red],
               %w[banana yellow],
               %w[orange orange]
    s = t.get_record(0).pretty_inspect
    assert_match(/apple/, s)
    assert_match(/red/, s)
  end

  def test_has_field?
    t = Tb.new %w[fruit color],
               %w[apple red],
               %w[banana yellow],
               %w[orange orange]
    r = t.get_record(0)
    assert_equal(true, r.has_field?("fruit"))
    assert_equal(false, r.has_field?("price"))
  end

  def test_to_a
    t = Tb.new %w[fruit color],
               %w[apple red],
               %w[banana yellow],
               %w[orange orange]
    assert_equal([["fruit", "apple"], ["color", "red"]], t.get_record(0).to_a)
  end

  def test_to_a_with_reserved
    t = Tb.new %w[fruit color],
               %w[apple red],
               %w[banana yellow],
               %w[orange orange]
    assert_equal([["_recordid", 0], ["fruit", "apple"], ["color", "red"]], t.get_record(0).to_a_with_reserved)
  end

  def test_each_with_reserved
    t = Tb.new %w[fruit color],
               %w[apple red],
               %w[banana yellow],
               %w[orange orange]
    result = []
    t.get_record(0).each_with_reserved {|r|
      result << r
    }
    assert_equal([["_recordid", 0], ["fruit", "apple"], ["color", "red"]], result)
  end

  def test_values_at
    t = Tb.new %w[fruit color],
               %w[apple red],
               %w[banana yellow],
               %w[orange orange]
    assert_equal(["apple", "red"], t.get_record(0).values_at("fruit", "color"))
  end

end
