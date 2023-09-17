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
      # The +Process.clock_gettime+ clock id used to create +Instant+ instances
      # by the default monotonic function.
      #
      # Suggested options include:
      #
      # * +Process::CLOCK_MONOTONIC+
      # * +Process::CLOCK_MONOTONIC_FAST+
      # * +Process::CLOCK_MONOTONIC_PRECISE+
      # * +Process::CLOCK_UPTIME_RAW+
      # * +Process::CLOCK_MONOTONIC_RAW+
      # * +Process::CLOCK_HIRES+
      #
      # These are platform-dependant and may vary in resolution, performance,
      # and behaviour from ntpd timer skew.
      #
      # It is possible to set non-monotonic clock sources here.  You probably
      # shouldn't.
      #
      # Defaults to auto-detect.
      attr_writer :clock_id

      # The symbolic name of the automatically-selected +Process.clock_gettime+
      # clock id, if available.  This will *not* reflect a manually-set +clock_id+.
      #
      # @return [Symbol, nil]
      attr_reader :clock_name

      # The function used to create +Instant+ instances.
      #
      # This function must return a +Numeric+, monotonic count of nanoseconds
      # since a fixed point in the past.
      #
      # Defaults to `lambda { Process.clock_gettime(clock_id, :nanosecond) }`.
      #
      # @overload monotonic_function=(function)
      #   @param function [#call]
      attr_accessor :monotonic_function

      def clock_id
        @clock_id ||= detect_clock_id
      end

      # Return the claimed resolution of the given clock id or the configured
      # +clock_id+, as a +Duration+, or +nil+ if invalid.
      #
      # @param clock [Numeric] Optional clock id instead of default.
      def clock_getres(clock = nil)
        # Defend against unset @clock_id
        clock = @clock_id if @clock_id && clock.nil?
        Duration.from_nanos(Process.clock_getres(clock, :nanosecond))
      rescue SystemCallError
        # suppress errors
      end

      private

      def detect_clock_id
        name, id, =
          [
            :CLOCK_MONOTONIC_RAW,     # Linux, not affected by NTP frequency adjustments
            :CLOCK_UPTIME_RAW,        # macOS, not affected by NTP frequency adjustments
            :CLOCK_UPTIME_PRECISE,    # FreeBSD, increments while system is running
            :CLOCK_UPTIME,            # OpenBSD, increments while system is running
            :CLOCK_MONOTONIC_PRECISE, # FreeBSD, precise monotonic clock
            :CLOCK_MONOTONIC,         # Standard cross-platform monotonic clock
          ]
          .each_with_index # Used to force a stable sort in min_by
          .filter { |name, _| Process.const_defined?(name) }
          .map { |name, index| [name, Process.const_get(name), index] }
          .filter_map { |clock| clock.insert(2, clock_getres(clock[1])) }
          .min_by { |clock| clock[2..] } # find smallest resolution and index
          .tap { |clock| raise NotImplementedError, 'No usable clock' unless clock }

        @clock_name = name
        id
      end
    end

    self.monotonic_function = -> { Process.clock_gettime(clock_id, :nanosecond) }
    clock_id # detect our clock_id early

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
    # @return [Integer]
    def hash
      [self.class, @ns].hash
    end
  end
end
