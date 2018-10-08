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

    # Create a new +Instant+ from an optional nanosecond measurement.
    #
    # Users should generally *not* pass anything to this function.
    #
    # @param nanos [Integer]
    def initialize(nanos = Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond))
      @ns = Integer(nanos)
    end

    # An alias to +new+, and generally preferred over it.
    #
    # @return [Instant]
    def self.now
      new
    end

    # Return a +Duration+ between this +Instant+ and another.
    #
    # @param earlier [Instant]
    # @return [Duration]
    def duration_since(earlier)
      raise TypeError, 'Not an Instant' unless earlier.is_a?(Instant)

      earlier - self
    end

    # Return a +Duration+ since this +Instant+ and now.
    #
    # @return [Duration]
    def elapsed
      duration_since(self.class.now)
    end

    # Sugar for +#elapsed.to_s+.
    #
    # @see Duration#to_s
    def to_s(*args)
      elapsed.to_s(*args)
    end

    # Add a +Duration+ or +#to_nanos+-coercible object to this +Instant+, returning
    # a new +Instant+.
    #
    # @param other [Duration, #to_nanos]
    # @return [Instant]
    def +(other)
      return TypeError, 'Not one of: [Duration, #to_nanos]' unless other.respond_to?(:to_nanos)

      Instant.new(@ns + other.to_nanos)
    end

    # Subtract another +Instant+ to generate a +Duration+ between the two,
    # or a +Duration+ or +#to_nanos+-coercible object, to generate an +Instant+
    # offset by it.
    #
    # @param other [Instant, Duration, #to_nanos]
    # @return [Duration, Instant]
    def -(other)
      if other.is_a?(Instant)
        Duration.new(@ns - other.ns)
      elsif other.respond_to?(:to_nanos)
        Instant.new(@ns - other.to_nanos)
      else
        raise TypeError, 'Not one of: [Instant, Duration, #to_nanos]'
      end
    end

    # Determine if the given +Instant+ is before, equal to or after this one.
    # +nil+ if not passed an +Instant+.
    #
    # @return [-1, 0, 1, nil]
    def <=>(other)
      @ns <=> other.ns if other.is_a?(Instant)
    end

    # Determine if +other+'s value equals that of this +Instant+.
    # Use +eql?+ if type checks are desired for future compatibility.
    #
    # @return [Boolean]
    # @see #eql?
    def ==(other)
      other.is_a?(Instant) && @ns == other.ns
    end

    alias eql? ==

    # Generate a hash for this type and value.
    #
    # @return [Fixnum]
    def hash
      self.class.hash ^ @ns.hash
    end
  end

  # A type representing a span of time in nanoseconds.
  class Duration
    include Comparable

    # Create a new +Duration+ of a specified number of nanoseconds, zero by
    # default.
    #
    # @param nanos [Integer]
    def initialize(nanos = 0)
      @ns = Integer(nanos)
    end

    class << self
      # Generate a new +Duration+ measuring the given number of seconds.
      #
      # @param secs [Numeric]
      # @return [Duration]
      def from_secs(secs)
        new(Integer(Float(secs) * 1_000_000_000))
      end

      # Generate a new +Duration+ measuring the given number of milliseconds.
      #
      # @param millis [Numeric]
      # @return [Duration]
      def from_millis(millis)
        new(Integer(Float(millis) * 1_000_000))
      end

      # Generate a new +Duration+ measuring the given number of microseconds.
      #
      # @param micros [Numeric]
      # @return [Duration]
      def from_micros(micros)
        new(Integer(Float(micros) * 1_000))
      end

      # Generate a new +Duration+ measuring the given number of nanoseconds.
      #
      # @param nanos [Numeric]
      # @return [Duration]
      def from_nanos(nanos)
        new(Integer(nanos))
      end

      # Return a +Duration+ measuring the elapsed time of the yielded block.
      #
      # @return [Duration]
      def measure
        Instant.now.tap { yield }.elapsed
      end
    end

    # Add another +Duration+ or +#to_nanos+-coercible object to this one,
    # returning a new +Duration+.
    #
    # @param [Duration, #to_nanos]
    #
    # @return [Duration]
    def +(other)
      raise TypeError, 'Not one of: [Duration, #to_nanos]' unless other.respond_to?(:to_nanos)

      Duration.new(to_nanos + other.to_nanos)
    end

    # Subtract another +Duration+ or +#to_nanos+-coercible object from this one,
    # returning a new +Duration+.
    #
    # @param [Duration, #to_nanos]
    # @return [Duration]
    def -(other)
      raise TypeError, 'Not one of: [Duration, #to_nanos]' unless other.respond_to?(:to_nanos)

      Duration.new(to_nanos - other.to_nanos)
    end

    # Compare the *value* of this +Duration+ with another, or any +#to_nanos+-coercible
    # object, or nil if not comparable.
    #
    # @param [Duration, #to_nanos, Object]
    # @return [-1, 0, 1, nil]
    def <=>(other)
      to_nanos <=> other.to_nanos if other.respond_to?(:to_nanos)
    end

    # Compare the equality of the *value* of this +Duration+ with another, or
    # any +#to_nanos+-coercible object, or nil if not comparable.
    #
    # @param [Duration, #to_nanos, Object]
    # @return [Boolean]
    def ==(other)
      other.respond_to?(:to_nanos) && to_nanos == other.to_nanos
    end

    # Check equality of the value and type of this +Duration+ with another.
    #
    # @param [Duration, Object]
    # @return [Boolean]
    def eql?(other)
      other.is_a?(Duration) && to_nanos == other.to_nanos
    end

    # Generate a hash for this type and value.
    #
    # @return [Fixnum]
    def hash
      self.class.hash ^ to_nanos.hash
    end

    # Return this +Duration+ in seconds.
    #
    # @return [Float]
    def to_secs
      to_nanos / 1_000_000_000.0
    end

    # Return this +Duration+ in milliseconds.
    #
    # @return [Float]
    def to_millis
      to_nanos / 1_000_000.0
    end

    # Return this +Duration+ in microseconds.
    #
    # @return [Float]
    def to_micros
      to_nanos / 1_000.0
    end

    # Return this +Duration+ in nanoseconds.
    #
    # @return [Integer]
    def to_nanos
      @ns
    end

    DIVISORS = [
      [1_000_000_000.0, 's'],
      [1_000_000.0, 'ms'],
      [1_000.0, 'μs'],
      [0, 'ns']
    ].map(&:freeze).freeze

    private_constant :DIVISORS

    # Format this +Duration+ into a human-readable string, with a given number
    # of decimal places.
    #
    # The exact format is subject to change, users with specific requirements
    # are encouraged to use their own formatting methods.
    #
    # @param precision [Integer] the maximum number of decimal places
    # @return [String]
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
