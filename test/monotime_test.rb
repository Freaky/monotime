require 'test_helper'

class MonotimeTest < Minitest::Test
  include Monotime

  puts "Clock source: #{Instant.clock_name}"

  def test_that_it_has_a_version_number
    refute_nil ::Monotime::MONOTIME_VERSION
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
    assert_equal a.hash, a.dup.hash
    assert((a <=> a).zero?)
    assert(a < a + dur)
    assert(a > a - dur)
    refute_equal a, a + dur
    assert a.eql?(a + Duration.from_nanos(0))
    refute a.eql?(a + Duration.from_nanos(1))

    assert_nil a <=> 'meep'
  end

  def test_instant_past_future
    past = Instant.now - Duration.secs(1)

    assert past.in_past?
    refute past.in_future?

    future = Instant.now + Duration.secs(1)
    assert future.in_future?
    refute future.in_past?
  end

  def test_duration_zeros
    z = Duration.from_nanos(0)
    nz = Duration.from_nanos(1)

    assert z.zero?
    refute nz.zero?

    refute z.nonzero?
    assert nz.nonzero?
  end

  def test_instant_elapsed
    a = Instant.now - Duration.from_millis(100)
    elapsed = a.elapsed

    assert elapsed.nonzero?
    assert elapsed.positive?
  end

  def test_instant_to_s
    assert_match(/\A\d+.s\z/, Instant.now.to_s(0))
  end

  def test_duration_equality
    a = Duration.from_secs(1)
    b = Duration.from_secs(2)
    duck_a = Class.new { def to_nanos() Duration.from_secs(1).to_nanos end }.new

    assert_equal a, Duration.from_secs(1)
    assert_equal a.hash, Duration.from_secs(1).hash
    assert a.eql?(Duration.from_secs(1))

    assert_equal a, duck_a
    refute_equal b, duck_a
    refute a.eql?(duck_a)
    refute b.eql?(duck_a)

    refute_equal a, b
    assert a < b
    assert b > a

    assert_nil a <=> 'meep'
  end

  def test_duration_conversions
    secs = Duration.from_secs(10)
    assert_equal secs, Duration.from_secs(secs.to_secs)
    assert_equal secs, Duration.from_millis(secs.to_millis)
    assert_equal secs, Duration.from_micros(secs.to_micros)
    assert_equal secs, Duration.from_nanos(secs.to_nanos)

    assert_equal secs, Duration.secs(secs.secs)
    assert_equal secs, Duration.millis(secs.millis)
    assert_equal secs, Duration.micros(secs.micros)
    assert_equal secs, Duration.nanos(secs.nanos)
  end

  def test_duration_maths
    one_sec = Duration.from_secs(1)
    two_secs = Duration.from_secs(2)
    three_secs = Duration.from_secs(3)

    assert_equal one_sec * 2, two_secs
    assert_equal two_secs / 2, one_sec
    assert_equal one_sec + two_secs, three_secs
    assert_equal two_secs - one_sec, one_sec
  end

  def test_duration_measure
    elapsed = Duration.measure { "bleep" }
    assert_instance_of Duration, elapsed
    assert elapsed.positive?
  end

  def test_duration_with_measure
    res, elapsed = Duration.with_measure { "bloop" }
    assert_equal "bloop", res
    assert_instance_of Duration, elapsed
    assert elapsed.positive?
  end

  def test_type_errors
    assert_raises(TypeError) { Instant.now.duration_since(0) }
    assert_raises(TypeError) { Instant.now - 0 }
    assert_raises(TypeError) { Duration.secs(1) + 0 }
    assert_raises(TypeError) { Duration.secs(1) - 0 }
  end

  def test_sleeps
    slept = Duration.zero
    old_sleep_function = Duration.sleep_function
    Duration.sleep_function = ->(secs) { slept += Duration.secs(secs);secs }
    ten_ms = Duration.from_millis(10)

    t = Instant.now
    a = t.sleep(ten_ms)
    t -= ten_ms
    b = t.sleep(ten_ms)

    assert((t - ten_ms).sleep.negative?)

    assert_includes 9..11, a.to_millis
    assert a > b
    assert b.negative?

    # Quick check of aliases
    assert_includes 9..11, Instant.now.sleep_millis(10).to_millis
    assert_includes 9..11, Instant.now.sleep_secs(0.01).to_millis
    Duration.sleep_function = old_sleep_function
  end

  def test_duration_unary
    one_sec = Duration.from_secs(1)
    minus_one_sec = Duration.from_secs(-1)

    assert_equal one_sec, minus_one_sec.abs
    assert_equal one_sec.abs, minus_one_sec.abs
    assert_equal(-one_sec, minus_one_sec)
    assert_equal one_sec, -minus_one_sec
  end

  def test_instant_hashing
    inst0 = Instant.now
    inst1 = inst0 + Duration.from_nanos(1)
    inst2 = inst0 + Duration.from_secs(1)
    inst3 = inst0 + Duration.from_secs(10)

    hash = {inst0 => 0, inst1 => 1, inst2 => 2, inst3 => 3}

    assert_equal hash[inst0], 0
    assert_equal hash[inst1], 1
    assert_equal hash[inst2], 2
    assert_equal hash[inst3], 3

    assert_equal hash.keys.sort, [inst0, inst1, inst2, inst3]
  end

  def test_duration_hashing
    dur0 = Duration.new
    dur1 = Duration.from_nanos(1)
    dur2 = Duration.from_secs(1)
    dur3 = Duration.from_secs(10)

    hash = {dur0 => 0, dur1 => 1, dur2 => 2, dur3 => 3}

    assert_equal hash[dur0], 0
    assert_equal hash[dur1], 1
    assert_equal hash[dur2], 2
    assert_equal hash[dur3], 3

    assert_equal hash.keys.sort, [dur0, dur1, dur2, dur3]
  end

  def test_duration_format
    assert_equal '1s', Duration.from_secs(1).to_s
    assert_equal '1.5s', Duration.from_secs(1.5).to_s
    assert_equal '1.25s', Duration.from_secs(1.25).to_s
    assert_equal '1.2s', Duration.from_secs(1.25).to_s(1)
    assert_equal '1.3s', Duration.from_secs(1.26).to_s(1)
    assert_equal '2s', Duration.from_secs(1.6).to_s(0)

    assert_equal '1ms', Duration.from_millis(1).to_s
    assert_equal '1.5ms', Duration.from_millis(1.5).to_s
    assert_equal '1.25ms', Duration.from_millis(1.25).to_s
    assert_equal '1.2ms', Duration.from_millis(1.25).to_s(1)
    assert_equal '1.3ms', Duration.from_millis(1.26).to_s(1)
    assert_equal '2ms', Duration.from_millis(1.6).to_s(0)

    assert_equal '1μs', Duration.from_micros(1).to_s
    assert_equal '1.5μs', Duration.from_micros(1.5).to_s
    assert_equal '1.25μs', Duration.from_micros(1.25).to_s
    assert_equal '1.2μs', Duration.from_micros(1.25).to_s(1)
    assert_equal '1.3μs', Duration.from_micros(1.26).to_s(1)
    assert_equal '2μs', Duration.from_micros(1.6).to_s(0)

    assert_equal '-1μs', Duration.from_micros(-1).to_s
    assert_equal '-1.5μs', Duration.from_micros(-1.5).to_s
    assert_equal '-1.25μs', Duration.from_micros(-1.25).to_s
    assert_equal '-1.2μs', Duration.from_micros(-1.25).to_s(1)
    assert_equal '-1.3μs', Duration.from_micros(-1.26).to_s(1)
    assert_equal '-2μs', Duration.from_micros(-1.6).to_s(0)

    assert_equal '1ns', Duration.from_nanos(1).to_s
    assert_equal '-1ns', Duration.from_nanos(-1).to_s
  end

  def test_duration_format_zero_stripping
    # Zeros should not be stripped if precision = 0
    assert_equal '100s', Duration.from_secs(100).to_s(0)
    assert_equal '100ns', Duration.from_nanos(100).to_s
  end

  def test_duration_to_s_precision
    duration = Duration.from_nanos(1111111111)
    assert_equal "1.111111111s", duration.to_s
    assert_equal 9, Duration.default_to_s_precision

    Duration.default_to_s_precision = 2
    assert_equal 2, Duration.default_to_s_precision
    assert_equal "1.11s", duration.to_s

    Duration.default_to_s_precision = 9
  end

  def test_duration_sleep_function
    assert_equal Kernel.method(:sleep), Duration.sleep_function

    slept = 0
    Duration.sleep_function = ->(duration) { slept += duration }

    Duration.secs(1).sleep
    Duration.millis(1).sleep
    assert_in_epsilon slept, 1.001

    Duration.sleep_function = Kernel.method(:sleep)
  end

  def test_zero_constant
    assert_equal Duration.zero.object_id, Duration::ZERO.object_id
    assert_equal Duration.new.object_id, Duration::ZERO.object_id
    assert_equal Duration.secs(0).object_id, Duration::ZERO.object_id
  end

  def test_getres
    assert_instance_of Duration, Instant.clock_getres
  end

  def test_instant_clock_id
    old_clock_id = Instant.clock_id
    Instant.clock_id = Process::CLOCK_REALTIME
    assert_equal Process::CLOCK_REALTIME, Instant.clock_id

    assert_instance_of Instant, Instant.now
    Instant.clock_id = old_clock_id
  end

  def test_instant_monotonic_function
    old_fn = Instant.monotonic_function
    now = 0
    Instant.monotonic_function = ->() { now += 1 }
    assert_equal Duration.nanos(1), Instant.now.elapsed
    assert_equal 2, now
    Instant.monotonic_function = old_fn
  end

  def test_clock_name
    old_clock_id = Instant.clock_id
    Instant.clock_id = Process::CLOCK_REALTIME
    assert_equal :CLOCK_REALTIME, Instant.clock_name
    Instant.clock_id = old_clock_id
  end
end
