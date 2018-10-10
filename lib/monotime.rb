# frozen_string_literal: true

require 'monotime/version'

module Monotime
  # A measurement from the operating system's monotonic clock, with up to
  # nanosecond precision.
  class Instant
    # A measurement, in nanoseconds.  Should be considered opaque and
    # non-portable outside the process that created it.
    attr_reader :ns
    protected :ns

    include Comparable

    # Create a new +Instant+ from an optional nanosecond measurement.
    #
    # Users should generally *not* pass anything to this function.
    #
    # @param nanos [Integer]
    # @see #now
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

    # Sleep until this +Instant+, plus an optional +Duration+, returning a +Duration+
    # that's either positive if any time was slept, or negative if sleeping would
    # require time travel.
    #
    # @example Sleeps for a second
    #   start = Instant.now
    #   sleep 0.5 # do stuff for half a second
    #   start.sleep(Duration.from_secs(1)).to_s # => "490.088706ms" (slept)
    #   start.sleep(Duration.from_secs(1)).to_s # => "-12.963502ms" (did not sleep)
    #
    # @example Also sleeps for a second.
    #   one_second_in_the_future = Instant.now + Duration.from_secs(1)
    #   one_second_in_the_future.sleep.to_s     # => "985.592712ms" (slept)
    #   one_second_in_the_future.sleep.to_s     # => "-4.71217ms" (did not sleep)
    #
    # @param duration [nil, Duration, #to_nanos]
    # @return [Duration] the slept duration, if +#positive?+, else the overshot time
    def sleep(duration = nil)
      remaining = duration ? duration - elapsed : -elapsed

      remaining.tap { |rem| rem.sleep if rem.positive? }
    end

    # Sleep for the given number of seconds past this +Instant+, if any.
    #
    # Equivalent to +#sleep(Duration.from_secs(secs))+
    #
    # @param secs [Numeric] number of seconds to sleep past this +Instant+
    # @return [Duration] the slept duration, if +#positive?+, else the overshot time
    # @see #sleep
    def sleep_secs(secs)
      sleep(Duration.from_secs(secs))
    end

    # Sleep for the given number of milliseconds past this +Instant+, if any.
    #
    # Equivalent to +#sleep(Duration.from_millis(millis))+
    #
    # @param millis [Numeric] number of milliseconds to sleep past this +Instant+
    # @return [Duration] the slept duration, if +#positive?+, else the overshot time
    # @see #sleep
    def sleep_millis(millis)
      sleep(Duration.from_millis(millis))
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
    # @example
    #   (Instant.now + Duration.from_secs(1)).to_s # => "-999.983976ms"
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
    # @example
    #   (Instant.now - Duration.from_secs(1)).to_s # => "1.000016597s"
    #   (Instant.now - Instant.now).to_s           # => "-3.87μs"
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
    # Users are strongly advised to use +#from_nanos+ instead.
    #
    # @param nanos [Integer]
    # @see #from_nanos
    def initialize(nanos = 0)
      @ns = Integer(nanos)
    end

    class << self
      # Generate a new +Duration+ measuring the given number of seconds.
      #
      # @param secs [Numeric]
      # @return [Duration]
      def from_secs(secs)
        new(Integer(secs * 1_000_000_000))
      end

      # Generate a new +Duration+ measuring the given number of milliseconds.
      #
      # @param millis [Numeric]
      # @return [Duration]
      def from_millis(millis)
        new(Integer(millis * 1_000_000))
      end

      # Generate a new +Duration+ measuring the given number of microseconds.
      #
      # @param micros [Numeric]
      # @return [Duration]
      def from_micros(micros)
        new(Integer(micros * 1_000))
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
      # @example
      #   Duration.measure { sleep(0.5) }.to_s # => "512.226109ms"
      #
      # @return [Duration]
      def measure
        Instant.now.tap { yield }.elapsed
      end
    end

    # Add another +Duration+ or +#to_nanos+-coercible object to this one,
    # returning a new +Duration+.
    #
    # @example
    #   (Duration.from_secs(10) + Duration.from_secs(5)).to_s # => "15s"
    #
    # @param [Duration, #to_nanos]
    # @return [Duration]
    def +(other)
      raise TypeError, 'Not one of: [Duration, #to_nanos]' unless other.respond_to?(:to_nanos)

      Duration.new(to_nanos + other.to_nanos)
    end

    # Subtract another +Duration+ or +#to_nanos+-coercible object from this one,
    # returning a new +Duration+.
    #
    # @example
    #   (Duration.from_secs(10) - Duration.from_secs(5)).to_s # => "5s"
    #
    # @param [Duration, #to_nanos]
    # @return [Duration]
    def -(other)
      raise TypeError, 'Not one of: [Duration, #to_nanos]' unless other.respond_to?(:to_nanos)

      Duration.new(to_nanos - other.to_nanos)
    end

    # Divide this duration by a +Numeric+.
    #
    # @example
    #   (Duration.from_secs(10) / 2).to_s # => "5s"
    #
    # @param [Numeric]
    # @return [Duration]
    def /(other)
      Duration.new(to_nanos / other)
    end

    # Multiply this duration by a +Numeric+.
    #
    # @example
    #   (Duration.from_secs(10) * 2).to_s # => "20s"
    #
    # @param [Numeric]
    # @return [Duration]
    def *(other)
      Duration.new(to_nanos * other)
    end

    # Unary minus: make a positive +Duration+ negative, and vice versa.
    #
    # @example
    #   -Duration.from_secs(-1).to_s # => "1s"
    #   -Duration.from_secs(1).to_s  # => "-1s"
    #
    # @return [Duration]
    def -@
      Duration.new(-to_nanos)
    end

    # Return a +Duration+ that's absolute (positive).
    #
    # @example
    #   Duration.from_secs(-1).abs.to_s # => "1s"
    #   Duration.from_secs(1).abs.to_s  # => "1s"
    #
    # @return [Duration]
    def abs
      return self if positive? || zero?
      Duration.new(to_nanos.abs)
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

    # Return true if this +Duration+ is positive.
    #
    # @return [Boolean]
    def positive?
      to_nanos.positive?
    end

    # Return true if this +Duration+ is negative.
    #
    # @return [Boolean]
    def negative?
      to_nanos.negative?
    end

    # Return true if this +Duration+ is zero.
    #
    # @return [Boolean]
    def zero?
      to_nanos.zero?
    end

    # Sleep for the duration of this +Duration+.  Equivalent to
    # +Kernel.sleep(duration.to_secs)+.
    #
    # @example
    #   Duration.from_secs(1).sleep  # => 1
    #   Duration.from_secs(-1).sleep # => raises NotImplementedError
    #
    # @raise [NotImplementedError] negative +Duration+ sleeps are not yet supported.
    # @return [Integer]
    # @see Instant#sleep
    def sleep
      raise NotImplementedError, 'time travel module missing' if negative?
      Kernel.sleep(to_secs)
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
    # @example
    #   Duration.from_nanos(100).to_s  # => "100ns"
    #   Duration.from_micros(100).to_s # => "100μs"
    #   Duration.from_millis(100).to_s # => "100ms"
    #   Duration.from_secs(100).to_s   # => "100s"
    #   Duration.from_nanos(1234567).to_s # => "1.234567ms"
    #   Duration.from_nanos(1234567).to_s(2) # => "1.23ms"
    #
    # @param precision [Integer] the maximum number of decimal places
    # @return [String]
    def to_s(precision = 9)
      precision = Integer(precision).abs
      div, unit = DIVISORS.find { |d, _| to_nanos.abs >= d }

      if div.zero?
        format('%d%s', to_nanos, unit)
      else
        format("%#.#{precision}f", to_nanos / div).sub(/\.?0*\z/, '') << unit
      end
    end
  end
end
