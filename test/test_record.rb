require 'table'
require 'test/unit'

class TestTableRecord < Test::Unit::TestCase
  def test_values_at
    t = Table.new %w[fruit color],
                  %w[apple red],
                  %w[banana yellow],
                  %w[orange orange]
    assert_equal(["apple", "red"], t.get_record(0).values_at("fruit", "color"))
  end
end
