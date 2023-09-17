# frozen_string_literal: true

module Monotime
  # A type representing a span of time in nanoseconds.
  class Duration
    include Comparable

    # A static instance for zero durations
    ZERO = allocate.tap { |d| d.instance_eval { @ns = 0 ; freeze } }

    class << self
      # The sleep function used by all +Monotime+ sleep functions.
      #
      # This function must accept a positive +Float+ number of seconds and return
      # the +Float+ time slept.
      #
      # Defaults to +Kernel.method(:sleep)+
      #
      # @overload sleep_function=(function)
      #   @param function [#call]
      attr_accessor :sleep_function

      # Precision for +Duration#to_s+ if not otherwise specified
      #
      # Defaults to 9.
      #
      # @overload default_to_s_precision=(precision)
      #   @param precision [Numeric]
      attr_accessor :default_to_s_precision
    end

    self.sleep_function = Kernel.method(:sleep)
    self.default_to_s_precision = 9

    # Create a new +Duration+ of a specified number of nanoseconds, zero by
    # default.
    #
    # Users are strongly advised to use +#from_nanos+ instead.
    #
    # @param nanos [Integer]
    # @see #from_nanos
    def initialize(nanos = 0)
      @ns = Integer(nanos)
      freeze
    end

    class << self
      # @!visibility private
      def new(nanos = 0)
        return ZERO if nanos.zero?
        super
      end

      # Return a zero +Duration+.
      #
      # @return [Duration]
      def zero
        ZERO
      end

      # Generate a new +Duration+ measuring the given number of seconds.
      #
      # @param secs [Numeric]
      # @return [Duration]
      def from_secs(secs)
        new(Integer(secs * 1_000_000_000))
      end

      alias secs from_secs

      # Generate a new +Duration+ measuring the given number of milliseconds.
      #
      # @param millis [Numeric]
      # @return [Duration]
      def from_millis(millis)
        new(Integer(millis * 1_000_000))
      end

      alias millis from_millis

      # Generate a new +Duration+ measuring the given number of microseconds.
      #
      # @param micros [Numeric]
      # @return [Duration]
      def from_micros(micros)
        new(Integer(micros * 1_000))
      end

      alias micros from_micros

      # Generate a new +Duration+ measuring the given number of nanoseconds.
      #
      # @param nanos [Numeric]
      # @return [Duration]
      def from_nanos(nanos)
        new(Integer(nanos))
      end

      alias nanos from_nanos

      # Return a +Duration+ measuring the elapsed time of the yielded block.
      #
      # @example
      #   Duration.measure { sleep(0.5) }.to_s # => "512.226109ms"
      #
      # @return [Duration]
      def measure
        Instant.now.tap { yield }.elapsed
      end

      # Return the result of the yielded block alongside a +Duration+.
      #
      # @example
      #   Duration.with_measure { "bloop" } # => ["bloop", #<Monotime::Duration: ...>]
      #
      # @return [Object, Duration]
      def with_measure
        start = Instant.now
        ret = yield
        [ret, start.elapsed]
      end
    end

    # Add another +Duration+ or +#to_nanos+-coercible object to this one,
    # returning a new +Duration+.
    #
    # @example
    #   (Duration.from_secs(10) + Duration.from_secs(5)).to_s # => "15s"
    #
    # @param other [Duration, #to_nanos]
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
    # @param other [Duration, #to_nanos]
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
    # @param other [Numeric]
    # @return [Duration]
    def /(other)
      Duration.new(to_nanos / other)
    end

    # Multiply this duration by a +Numeric+.
    #
    # @example
    #   (Duration.from_secs(10) * 2).to_s # => "20s"
    #
    # @param other [Numeric]
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
    # @param other [Duration, #to_nanos, Object]
    # @return [-1, 0, 1, nil]
    def <=>(other)
      to_nanos <=> other.to_nanos if other.respond_to?(:to_nanos)
    end

    # Compare the equality of the *value* of this +Duration+ with another, or
    # any +#to_nanos+-coercible object, or nil if not comparable.
    #
    # @param other [Duration, #to_nanos, Object]
    # @return [Boolean]
    def ==(other)
      other.respond_to?(:to_nanos) && to_nanos == other.to_nanos
    end

    # Check equality of the value and type of this +Duration+ with another.
    #
    # @param other [Duration, Object]
    # @return [Boolean]
    def eql?(other)
      other.is_a?(Duration) && to_nanos == other.to_nanos
    end

    # Generate a hash for this type and value.
    #
    # @return [Integer]
    def hash
      self.class.hash ^ to_nanos.hash
    end

    # Return this +Duration+ in seconds.
    #
    # @return [Float]
    def to_secs
      to_nanos / 1_000_000_000.0
    end

    alias secs to_secs

    # Return this +Duration+ in milliseconds.
    #
    # @return [Float]
    def to_millis
      to_nanos / 1_000_000.0
    end

    alias millis to_millis

    # Return this +Duration+ in microseconds.
    #
    # @return [Float]
    def to_micros
      to_nanos / 1_000.0
    end

    alias micros to_micros

    # Return this +Duration+ in nanoseconds.
    #
    # @return [Integer]
    def to_nanos
      @ns
    end

    alias nanos to_nanos

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

    # Return true if this +Duration+ is non-zero.
    #
    # @return [Boolean]
    def nonzero?
      to_nanos.nonzero?
    end

    # Sleep for the duration of this +Duration+.  Equivalent to
    # +Kernel.sleep(duration.to_secs)+.
    #
    # The sleep function may be overridden globally using +Duration.sleep_function=+
    #
    # @example
    #   Duration.from_secs(1).sleep  # => 1
    #   Duration.from_secs(-1).sleep # => raises NotImplementedError
    #
    # @raise [NotImplementedError] negative +Duration+ sleeps are not yet supported.
    # @return [Integer]
    # @see Instant#sleep
    # @see Duration.sleep_function=
    def sleep
      raise NotImplementedError, 'time travel module missing' if negative?

      self.class.sleep_function.call(to_secs)
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
    # The default precision may be set globally using +Duration.default_to_s_precision=+
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
    # @see Duration.default_to_s_precision=
    def to_s(precision = self.class.default_to_s_precision)
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
