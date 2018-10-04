# frozen_string_literal: true

require 'monotime/version'

module Monotime
  # A measurement from the operating system's monotonic clock, with up to
  # nanosecond precision.
  class Instant
    # A measurement, in nanoseconds.  Should be considered opaque and
    # non-portable outside the process that created it.
    protected def ns() @ns end

    include Comparable

    # Create a new +Instant+ from a given nanosecond measurement, defaulting to
    # that given by +Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond))+.
    #
    # Users should generally *not* pass anything to this function.
    def initialize(nanos = Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond))
      @ns = Integer(nanos)
    end

    # An alias to +new+, and generally preferred over it.
    def self.now
      new
    end

    # Return a +Duration+ between this +Instant+ and another.
    def duration_since(earlier)
      case earlier
      when Instant then earlier - self
      else raise TypeError, 'Not an Instant'
      end
    end

    # Return a +Duration+ since this +Instant+ and now.
    def elapsed
      duration_since(self.class.now)
    end

    # Sugar for +elapsed.to_s+.
    def to_s(*args)
      elapsed.to_s(*args)
    end

    # Add a +Duration+ to this +Instant+, returning a new +Instant+.
    def +(other)
      case other
      when Duration then Instant.new(@ns + other.to_nanos)
      else raise TypeError, 'Not a Duration'
      end
    end

    # Subtract another +Instant+ to generate a +Duration+ between the two,
    # or a +Duration+, to generate an +Instant+ offset by it.
    def -(other)
      case other
      when Instant then Duration.new(@ns - other.ns)
      when Duration then Instant.new(@ns - other.to_nanos)
      else raise TypeError, 'Not an Instant or Duration'
      end
    end

    # Compare this +Instant+ with another.
    def <=>(other)
      @ns <=> other.ns if other.is_a?(Instant)
    end

    def ==(other)
      other.is_a?(Instant) && @ns == other.ns
    end

    alias eql? ==

    def hash
      self.class.hash ^ @ns.hash
    end
  end

  # A type representing a span of time in nanoseconds.
  class Duration
    include Comparable

    # Create a new +Duration+ of a specified number of nanoseconds, zero by
    # default.
    def initialize(nanos = 0)
      @ns = Integer(nanos)
    end

    class << self
      # Generate a new +Duration+ measuring the given number of seconds.
      def from_secs(secs)
        new(Integer(Float(secs) * 1_000_000_000))
      end

      # Generate a new +Duration+ measuring the given number of milliseconds.
      def from_millis(millis)
        new(Integer(Float(millis) * 1_000_000))
      end

      # Generate a new +Duration+ measuring the given number of microseconds.
      def from_micros(micros)
        new(Integer(Float(micros) * 1_000))
      end

      # Generate a new +Duration+ measuring the given number of nanoseconds.
      def from_nanos(nanos)
        new(Integer(nanos))
      end

      # Return a +Duration+ measuring the elapsed time of the yielded block.
      def measure
        Instant.now.tap { yield }.elapsed
      end
    end

    # Add another +Duration+ to this one, returning a new +Duration+.
    def +(other)
      Duration.new(to_nanos + other.to_nanos)
    end

    # Subtract another +Duration+ from this one, returning a new +Duration+.
    def -(other)
      Duration.new(to_nanos - other.to_nanos)
    end

    # Compare this +Duration+ with another.
    def <=>(other)
      to_nanos <=> other.to_nanos if other.is_a? Duration
    end

    def ==(other)
      other.is_a?(Duration) && to_nanos == other.to_nanos
    end

    alias eql? ==

    def hash
      self.class.hash ^ to_nanos.hash
    end

    # Return this +Duration+ in seconds.
    def to_secs
      to_nanos / 1_000_000_000.0
    end

    # Return this +Duration+ in milliseconds.
    def to_millis
      to_nanos / 1_000_000.0
    end

    # Return this +Duration+ in microseconds.
    def to_micros
      to_nanos / 1_000.0
    end

    # Return this +Duration+ in nanoseconds.
    def to_nanos
      @ns
    end

    DIVISORS = [
      [1_000_000_000.0, 's'],
      [1_000_000.0, 'ms'],
      [1_000.0, 'μs'],
      [0, 'ns']
    ].map(&:freeze).freeze

    # Format this +Duration+ into a human-readable string, with a given number
    # of decimal places.
    #
    # The exact format is subject to change, users with specific requirements
    # are encouraged to use their own formatting methods.
    def to_s(precision = 9)
      precision = Integer(precision).abs
      ns = to_nanos.abs
      div, unit = DIVISORS.find { |d, _| ns >= d }
      ns /= div if div.nonzero?
      num = format("#{'-' if to_nanos.negative?}%.#{precision}f", ns)
      num.sub!(/\.?0*$/, '') if precision.nonzero?
      num << unit
    end
  end
end
