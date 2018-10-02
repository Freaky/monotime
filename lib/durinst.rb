# frozen_string_literal: true

require 'durinst/version'

require 'dry-equalizer'

module Durinst
  class Instant
    attr_reader :monotime

    include Dry::Equalizer(:monotime)
    include Comparable

    def initialize(monotime = Process.clock_gettime(Process::CLOCK_MONOTONIC))
      raise TypeError, 'Not a Float' unless monotime.is_a? Float

      @monotime = monotime
    end

    def self.now
      new
    end

    def duration_since(earlier)
      case earlier
      when Instant then earlier - self
      else raise TypeError, 'Not an Instant'
      end
    end

    def elapsed
      duration_since(self.class.now)
    end

    def +(other)
      case other
      when Duration then Instant.new(self.monotime + other.seconds)
      when Numeric then Instant.new(self.monotime + other)
      else raise TypeError, 'Not a Duration or Numeric'
      end
    end

    def -(other)
      case other
      when Instant then Duration.new(self.monotime - other.monotime)
      when Duration then Instant.new(self.monotime - other.seconds)
      when Numeric then Instant.new(self.monotime - other)
      else raise TypeError, 'Not an Instant, Duration or Numeric'
      end
    end

    def <=>(other)
      case other
      when self.class then self.monotime <=> other.monotime
      else raise TypeError, 'Not a #{self.class}'
      end
    end

    def to_f
      @monotime
    end

    def to_i
      @monotime.to_i
    end
  end

  class Duration
    attr_reader :seconds

    include Dry::Equalizer(:seconds)
    include Comparable

    def initialize(seconds = 0.0)
      raise TypeError, 'Not a Float' unless seconds.is_a? Float

      @seconds = seconds
    end

    class << self
      def from_secs(secs)
        new(Float(secs))
      end

      def from_millis(millis)
        new(Float(millis) / 1_000)
      end

      def from_micros(micros)
        new(Float(micros) / 1_000_000)
      end

      def from_nanos(nanos)
        new(Float(nanos) / 1_000_000_000)
      end
    end

    def +(other)
      case other
      when Duration then Duration.new(self.seconds + other.seconds)
      when Numeric then Duration.new(self.seconds + other)
      else raise TypeError, 'Not a Duration or Numeric'
      end
    end

    def -(other)
      case other
      when Duration then Duration.new(self.seconds - other.seconds)
      when Numeric then Duration.new(self.seconds - other)
      else raise TypeError, 'Not a Duration or Numeric'
      end
    end

    def <=>(other)
      case other
      when self.class then self.seconds <=> other.seconds
      else raise TypeError, "Not a #{self.class}"
      end
    end

    def to_secs
    	@seconds
    end

    def to_millis
    	@seconds * 1_000
    end

    def to_micros
    	@seconds * 1_000_000
    end

    def to_nanos
    	@seconds * 1_000_000_000
    end

    def to_s(precision = 9)
    	postfix = 's'
    	num = "%.#{precision}f" % if self.seconds >= 1
        self.seconds
      elsif self.seconds >= 0.001
      	postfix = 'ms'
        (self.seconds * 1_000)
      elsif self.seconds >= 0.000001
      	postfix = 'μs'
        (self.seconds * 1_000_000)
      else
      	postfix = 'ns'
        (self.seconds * 1_000_000_000)
      end
      num.sub(/\.?0*$/, '') << postfix
    end
  end
end
