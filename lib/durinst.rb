# frozen_string_literal: true

require 'durinst/version'

require 'dry-equalizer'

module Durinst
  class Instant
    attr_reader :ns

    include Dry::Equalizer(:ns)
    include Comparable

    def initialize(ns = Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond))
      raise TypeError, 'Not an Integer' unless ns.is_a? Integer

      @ns = ns
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
      when Duration then Instant.new(self.ns + other.ns)
      when Integer then Instant.new(self.ns + other)
      else raise TypeError, 'Not a Duration or Integer'
      end
    end

    def -(other)
      case other
      when Instant then Duration.new(self.ns - other.ns)
      when Duration then Instant.new(self.ns - other.ns)
      when Integer then Instant.new(self.ns - other)
      else raise TypeError, 'Not an Instant, Duration or Integer'
      end
    end

    def <=>(other)
      case other
      when self.class then self.ns <=> other.ns
      else raise TypeError, 'Not a #{self.class}'
      end
    end
  end

  class Duration
    attr_reader :ns

    include Dry::Equalizer(:ns)
    include Comparable

    def initialize(ns = 0)
      raise TypeError, 'Not an Integer' unless ns.is_a? Integer

      @ns = ns
    end

    class << self
      def from_secs(secs)
        new(Integer(Float(secs) * 1_000_000_000))
      end

      def from_millis(millis)
        new(Integer(Float(millis) * 1_000_000))
      end

      def from_micros(micros)
        new(Integer(Float(micros) * 1_000))
      end

      def from_nanos(nanos)
        new(Integer(nanos))
      end
    end

    def +(other)
      case other
      when Duration then Duration.new(self.ns + other.ns)
      when Numeric then Duration.new(self.ns + other)
      else raise TypeError, 'Not a Duration or Numeric'
      end
    end

    def -(other)
      case other
      when Duration then Duration.new(self.ns - other.ns)
      when Numeric then Duration.new(self.ns - other)
      else raise TypeError, 'Not a Duration or Numeric'
      end
    end

    def <=>(other)
      case other
      when self.class then self.ns <=> other.ns
      else raise TypeError, "Not a #{self.class}"
      end
    end

    def to_secs
    	@ns / 1_000_000_000
    end

    def to_millis
    	@ns / 1_000_000
    end

    def to_micros
    	@ns * 1_000
    end

    def to_nanos
    	@ns
    end

    def to_s(precision = 9)
    	postfix = 's'
    	num = "%.#{precision}f" % if self.ns >= 1_000_000_000
        self.ns / 1_000_000_000.0
      elsif self.ns >= 1_000_000
      	postfix = 'ms'
        self.ns / 1_000_000.0
      elsif self.ns >= 1_000
      	postfix = 'μs'
        self.ns / 1_000.0
      else
      	postfix = 'ns'
        self.ns
      end
      num.sub(/\.?0*$/, '') << postfix
    end
  end
end
