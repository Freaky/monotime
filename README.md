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

## Usage

The typical way everyone does "correct" elapsed-time measurements in Ruby is
this pile of nonsense:

```ruby
start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
do_something
elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
```

Not only is it long-winded, it's imprecise, converting to floating point instead
of working off precise timestamps.

`Monotime` offers this alternative:

```ruby
include Monotime

start = Instant.now
do_something
elapsed = start.elapsed

# or
elapsed = Duration.measure { do_something }
```

`elapsed` is not a dimensionless `Float`, but a `Duration` type, and internally
both `Instant` and `Duration` operate in *nanoseconds* to most closely match
the native timekeeping types used by most operating systems.

`Duration` knows how to format itself:

```ruby
Duration.from_millis(42).to_s       # => "42ms"
Duration.from_nanos(12345).to_s     # => "12.345μs"
Duration.from_secs(1.12345).to_s(2) # => "1.12s"
```

And how to do basic maths on itself:

```ruby
(Duration.from_millis(42) + Duration.from_secs(1)).to_s  # => "1.042s"
(Duration.from_millis(42) - Duration.from_secs(-1)).to_s # => "-958ms"
```

`Instant` does some simple maths too:

```ruby
# Instant - Duration => Instant
(Instant.now - Duration.from_secs(1)).elapsed.to_s # => "1.000014627s"

# Instant - Instant => Duration
(Instant.now - Instant.now).to_s                   # => "-5.585μs"
```

`Duration` and `Instant` are also `Comparable` with other instances of their
type, and support `#hash` for use in, er, hashes.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Freaky/monotime.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
