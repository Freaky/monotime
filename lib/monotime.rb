# frozen_string_literal: true

require 'monotime/version'

require 'dry-equalizer'

module Monotime
  # A measurement from the operating system's monotonic clock, with up to
  # nanosecond precision.
  class Instant
    # A measurement, in nanoseconds.  Should be considered opaque and
    # non-portable outside the process that created it.
    attr_reader :ns

    include Dry::Equalizer(:ns)
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
      when Instant then self - earlier
      else raise TypeError, 'Not an Instant'
      end
    end

    # Return a +Duration+ since this +Instant+ and now.
    def elapsed
      duration_since(self.class.now)
    end

    # Add a +Duration+ to this +Instant+, returning a new +Instant+.
    def +(other)
      case other
      when Duration then Instant.new(@ns + other.ns)
      else raise TypeError, 'Not a Duration'
      end
    end

    # Subtract another +Instant+ to generate a +Duration+ between the two,
    # or a +Duration+, to generate an +Instant+ offset by it.
    def -(other)
      case other
      when Instant then Duration.new(other.ns - @ns)
      when Duration then Instant.new(@ns - other.ns)
      else raise TypeError, 'Not an Instant or Duration'
      end
    end

    # Compare this +Instant+ with another.
    def <=>(other)
      case other
      when self.class then @ns <=> other.ns
      else raise TypeError, "Not a #{self.class}"
      end
    end
  end

  # A type representing a span of time in nanoseconds.
  class Duration
    # The span in nanoseconds.  Direct use should be avoided in favour of
    # +to_nanos+.
    attr_reader :ns

    include Dry::Equalizer(:ns)
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
      case other
      when Duration then Duration.new(@ns + other.ns)
      else raise TypeError, 'Not a Duration'
      end
    end

    # Subtract another +Duration+ from this one, returning a new +Duration+.
    def -(other)
      case other
      when Duration then Duration.new(@ns - other.ns)
      else raise TypeError, 'Not a Duration'
      end
    end

    # Compare this +Duration+ with another.
    def <=>(other)
      case other
      when self.class then @ns <=> other.ns
      else raise TypeError, "Not a #{self.class}"
      end
    end

    # Return this +Duration+ in seconds.
    def to_secs
      @ns / 1_000_000_000.0
    end

    # Return this +Duration+ in milliseconds.
    def to_millis
      @ns / 1_000_000.0
    end

    # Return this +Duration+ in microseconds.
    def to_micros
      @ns / 1_000.0
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
    ].freeze

    # Format this +Duration+ into a human-readable string, with a given number
    # of decimal places.
    #
    # The exact format is subject to change, users with specific requirements
    # are encouraged to use their own formatting methods.
    def to_s(precision = 9)
      ns = @ns.abs
      div, unit = DIVISORS.find { |div, _| ns >= div }
      ns /= div if div.nonzero?
      num = format("#{'-' if @ns.negative?}%.#{precision}f", ns)
      num.sub(/\.?0*$/, '') << unit
    end
  end
end
