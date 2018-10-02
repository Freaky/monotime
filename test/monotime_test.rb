require 'test_helper'

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
    dur = Duration::from_nanos(1)
    assert_equal a, a
    assert_equal a.hash, a.hash
    assert((a <=> a).zero?)
    assert(a < a + dur)
    assert(a > a - dur)
  end

  def test_instant_elapsed
    a = Instant.now
    sleep 0.01
    elapsed = a.elapsed

    assert elapsed >= Duration.from_secs(0.01)
    assert elapsed <= Duration.from_secs(0.02)
  end

  def test_duration_format
    assert_equal '1s', Duration.from_secs(1).to_s
    assert_equal '1.5s', Duration.from_secs(1.5).to_s
    assert_equal '1.25s', Duration.from_secs(1.25).to_s

    assert_equal '1ms', Duration.from_millis(1).to_s
    assert_equal '1.5ms', Duration.from_millis(1.5).to_s
    assert_equal '1.25ms', Duration.from_millis(1.25).to_s

    assert_equal '1μs', Duration.from_micros(1).to_s
    assert_equal '1.5μs', Duration.from_micros(1.5).to_s
    assert_equal '1.25μs', Duration.from_micros(1.25).to_s

    assert_equal '1ns', Duration.from_nanos(1).to_s
  end

  def test_duration_format_zero_stripping
    # Zeros should not be stripped if precision = 0
    assert_equal '100s', Duration.from_secs(100).to_s(0)
    assert_equal '100ns', Duration.from_nanos(100).to_s
  end
end
