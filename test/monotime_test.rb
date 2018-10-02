require "test_helper"

class MonotimeTest < Minitest::Test
  include Monotime

  def test_that_it_has_a_version_number
    refute_nil ::Monotime::VERSION
  end

  def test_instant_monotonic
    10.times do
      assert Instant.now <= Instant.now
    end
  end

  def test_instant_equality
    a = Instant.now
    assert_equal a, a
    assert_equal a.hash, a.hash
    assert (a <=> a).zero?
    assert (a < a + 1)
    assert (a > a - 1)
  end

  def test_instant_elapsed
    a = Instant.now
    sleep 0.01
    elapsed = a.elapsed

    assert elapsed >= Duration::from_secs(0.01)
    assert elapsed <= Duration::from_secs(0.02)
  end
end
