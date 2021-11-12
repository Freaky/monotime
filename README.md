[![Gem Version](https://badge.fury.io/rb/monotime.svg)](https://badge.fury.io/rb/monotime)
![Build Status](https://github.com/Freaky/monotime/actions/workflows/ci.yml/badge.svg)
[![Inline docs](http://inch-ci.org/github/Freaky/monotime.svg?branch=master)](http://inch-ci.org/github/Freaky/monotime)
[![Yard Docs](http://img.shields.io/badge/yard-docs-blue.svg)](https://www.rubydoc.info/gems/monotime)

# Monotime

A sensible interface to Ruby's monotonic clock, inspired by Rust.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'monotime'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install monotime

`Monotime` is tested on Ruby 2.5&mdash;3.0 and recent JRuby 9.x releases.

## Usage

```ruby
require 'monotime'
# or, to automatically include Monotime::* in the global scope,
# as used by these examples:
require 'monotime/include'
```

`Monotime` offers a `Duration` type for describing spans of time, and an
`Instant` type for describing points in time.  Both operate at nanosecond
resolution to the limits of whatever your Ruby implementation supports.

For example, to measure an elapsed time, either create an `Instant` to mark the
start point, perform the action and then ask for the `Duration` that has elapsed
since:

```ruby
start = Instant.now
do_something
elapsed = start.elapsed
```

Or use a convenience method:

```ruby
elapsed = Duration.measure { do_something }
# or
return_value, elapsed = Duration.with_measure { compute_something }
```

`Duration` offers formatting:

```ruby
Duration.millis(42).to_s       # => "42ms"
Duration.nanos(12345).to_s     # => "12.345μs"
Duration.secs(1.12345).to_s(2) # => "1.12s"
```

Conversions:

```ruby
Duration.secs(10).millis    # => 10000.0
Duration.micros(12345).secs # => 0.012345
```

And basic mathematical operations:

```ruby
(Duration.millis(42) + Duration.secs(1)).to_s  # => "1.042s"
(Duration.millis(42) - Duration.secs(1)).to_s  # => "-958ms"
(Duration.secs(42) * 2).to_s                   # => "84s"
(Duration.secs(42) / 2).to_s                   # => "21s"
```

`Instant` does some simple maths too:

```ruby
# Instant - Duration => Instant
(Instant.now - Duration.secs(1)).elapsed.to_s      # => "1.000014627s"

# Instant - Instant => Duration
(Instant.now - Instant.now).to_s                   # => "-5.585μs"
```

`Duration` and `Instant` are also `Comparable` with other instances of their
type, and can be used in hashes, sets, and similar structures.

## Sleeping

`Duration` can be used to sleep a thread, assuming it's positive (time travel
is not yet implemented):

```ruby
# Equivalent
sleep(Duration.secs(1).secs)  # => 1
Duration.secs(1).sleep        # => 1
```

So can `Instant`, taking a `Duration` and sleeping until the given `Duration`
past the time the `Instant` was created, if any. This can be useful for
maintaining a precise cadence between tasks:

```ruby
interval = Duration.secs(60)
start = Instant.now
loop do
  do_stuff
  start.sleep(interval)
  start += interval
end
```

Or you can declare an `Instant` in the future and sleep to that point:

```ruby
interval = Duration.secs(60)
deadline = Instant.now + interval
loop do
  do_stuff
  deadline.sleep
  deadline += interval
end
```

`Instant#sleep` returns a `Duration` which was slept, or a negative `Duration`
indicating that the desired sleep point was in the past.

## Duration duck typing

Operations taking a `Duration` can also accept any type which implements
`#to_nanos`, returning an (Integer) number of nanoseconds the value represents.

For example, to treat built-in numeric types as second durations, you could do:

```ruby
class Numeric
  def to_nanos
    Integer(self * 1_000_000_000)
  end
end

(Duration.secs(1) + 41).to_s  # => "42s"
(Instant.now - 42).to_s       # => "42.000010545s"
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Freaky/monotime.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## See Also

### Core Ruby

For a zero-dependency alternative, see
[`Process.clock_gettime`](https://ruby-doc.org/core-2.6.3/Process.html#method-c-clock_gettime).
`monotime` currently only uses `Process::CLOCK_MONOTONIC`, but others may offer higher precision
depending on platform.

### Other Gems

[hitimes](https://rubygems.org/gems/hitimes) is a popular and mature alternative
which also includes a variety of features for gathering statistics about
measurements, and may offer higher precision on some platforms.

