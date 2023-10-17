# frozen_string_literal: true

module Monotime
  # A measurement from the operating system's monotonic clock, with up to
  # nanosecond precision.
  class Instant
    # A measurement, in nanoseconds.  Should be considered opaque and
    # non-portable outside the process that created it.
    attr_reader :ns
    protected :ns

    include Comparable

    class << self
      # @overload clock_id
      #   The +Process.clock_gettime+ clock id used to create +Instant+ instances
      #   by the default monotonic function.
      #
      #   @return [Numeric]
      #
      # @overload clock_id=(id)
      #
      #   Override the default +Process.clock_gettime+ clock id.  Some potential
      #   choices include but are not limited to:
      #
      #   * +Process::CLOCK_MONOTONIC_RAW+
      #   * +Process::CLOCK_UPTIME_RAW+
      #   * +Process::CLOCK_UPTIME_PRECISE+
      #   * +Process::CLOCK_UPTIME_FAST+
      #   * +Process::CLOCK_UPTIME+
      #   * +Process::CLOCK_MONOTONIC_PRECISE+
      #   * +Process::CLOCK_MONOTONIC_FAST+
      #   * +Process::CLOCK_MONOTONIC+
      #   * +:MACH_ABSOLUTE_TIME_BASED_CLOCK_MONOTONIC+
      #   * +:TIMES_BASED_CLOCK_MONOTONIC+
      #
      #   These are platform-dependant and may vary in resolution, accuracy,
      #   performance, and behaviour in light of system suspend/resume and NTP
      #   frequency skew.  They should be selected carefully based on your specific
      #   needs and environment.
      #
      #   It is possible to set non-monotonic clock sources here.  You probably
      #   shouldn't.
      #
      #   Defaults to auto-selection from whatever is available from:
      #
      #   * +CLOCK_UPTIME_RAW+ (if running under macOS)
      #   * +CLOCK_MONOTONIC+
      #   * +CLOCK_REALTIME+ (non-monotonic fallback, issues a run-time warning)
      #
      #   @param id [Numeric, Symbol]
      attr_accessor :clock_id

      # The function used to create +Instant+ instances.
      #
      # This function must return a +Numeric+, monotonic count of nanoseconds
      # since a fixed point in the past.
      #
      # Defaults to +-> { Process.clock_gettime(clock_id, :nanosecond) }+.
      #
      # @overload monotonic_function=(function)
      #   @param function [#call]
      attr_accessor :monotonic_function

      # Return the claimed resolution of the given clock id or the configured
      # +clock_id+, as a +Duration+, or +nil+ if invalid.
      #
      # Note per Ruby issue #16740, the practical usability of this method is
      # dubious and non-portable.
      #
      # @param clock [Numeric, Symbol] Optional clock id instead of default.
      def clock_getres(clock = clock_id)
        Duration.from_nanos(Process.clock_getres(clock, :nanosecond))
      rescue SystemCallError
        # suppress errors
      end

      # The symbolic name of the currently-selected +clock_id+, if available.
      #
      # @return [Symbol, nil]
      def clock_name
        return clock_id if clock_id.is_a? Symbol

        Process.constants.find do |c|
          c.to_s.start_with?('CLOCK_') && Process.const_get(c) == clock_id
        end
      end

      private

      def select_clock_id
        if RUBY_PLATFORM.include?('darwin') && Process.const_defined?(:CLOCK_UPTIME_RAW)
          # Offers nanosecond resolution and appears to be slightly faster on two
          # different Macs (M1 and x64)
          #
          # There is also :MACH_ABSOLUTE_TIME_BASED_CLOCK_MONOTONIC which calls
          # mach_absolute_time() directly, but documentation for that recommends
          # CLOCK_UPTIME_RAW, and the performance difference is minimal.
          Process::CLOCK_UPTIME_RAW
        elsif Process.const_defined?(:CLOCK_MONOTONIC)
          Process::CLOCK_MONOTONIC
        else
          # There is also :TIMES_BASED_CLOCK_MONOTONIC, but having seen it just return
          # 0 instead of an error on a MSVC build this may be the safer option.
          warn 'No monotonic clock source detected, falling back to CLOCK_REALTIME'
          Process::CLOCK_REALTIME
        end
      end
    end

    self.monotonic_function = -> { Process.clock_gettime(clock_id, :nanosecond) }
    self.clock_id = select_clock_id

    # Create a new +Instant+ from an optional nanosecond measurement.
    #
    # Users should generally *not* pass anything to this function.
    #
    # @param nanos [Integer]
    # @see #now
    def initialize(nanos = self.class.monotonic_function.call)
      @ns = Integer(nanos)
      freeze
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

    # Return whether this +Instant+ is in the past.
    #
    # @return [Boolean]
    def in_past?
      elapsed.positive?
    end

    alias past? in_past?

    # Return whether this +Instant+ is in the future.
    #
    # @return [Boolean]
    def in_future?
      elapsed.negative?
    end

    alias future? in_future?

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
    def to_s(...)
      elapsed.to_s(...)
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
      raise TypeError, 'Not one of: [Duration, #to_nanos]' unless other.respond_to?(:to_nanos)

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
    # @return [Integer]
    def hash
      [self.class, @ns].hash
    end
  end
end
