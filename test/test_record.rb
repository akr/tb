require 'tb'
require 'test/unit'

class TestTbRecord < Test::Unit::TestCase
  def test_values_at
    t = Tb.new %w[fruit color],
               %w[apple red],
               %w[banana yellow],
               %w[orange orange]
    assert_equal(["apple", "red"], t.get_record(0).values_at("fruit", "color"))
  end
end
