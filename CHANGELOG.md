# Changelog

## [0.8.1] - 2023-09-18

### Changed

- After further consideration, return to defaulting to `CLOCK_MONOTONIC` instead
  of the overly-elaborate auto-selection introduced in 0.8.0.

### Removed

- `Instant.clock_name`.  No I'm not incrementing to 0.9.  It's been a few hours,
   you're not using it, shut up.

## [0.8.0] - 2023-09-17

### Added

- Default precision for `Duration#to_s` can be set using
  `Duration.default_to_s_precision=`.
- Default sleep function can be set using `Duration.sleep_function=`
- `Duration::ZERO` and `Duration.zero` for an easy, memory-efficient
  zero-duration singleton.
- `Instant.clock_id` and `Instant.clock_id=` to control the default  clock
  source.
- `Instant.clock_getres` to get the minimum supported `Duration` from the
  selected clock source.
- `Instant.monotonic_function=` to completely replace the default monotonic
  function.

### Changed

- The default clock source is now chosen from a selection of options instead of
  defaulting to `CLOCK_MONOTONIC``.  Where possible options are used which are
  unaffected by NTP frequency skew and which do not count time in system suspend.
- CI matrix drops Ruby 2.5 and 2.6 and adds 3.1, 3.2, head branches of Ruby,
  JRuby, and TruffleRuby, and also tests under macOS.

### Fixed

- CI on TruffleRuby has been fixed by disabling SimpleCov.
- Several fragile tests depending on relatively narrow sleep times have been fixed.

### Thanks

- [@petergoldstein] for fixing CI on TruffleRuby and adding 3.1 and 3.2.
- [@fig] for fixing a README error.

## [0.7.1] - 2021-10-22

### Added

- `simplecov` introduced to test suite.
- `monotime/include.rb` to auto-include types globally.

### Changed

- All `Instant` and `Duration` instances are now frozen.
- Migrate from Travis CI to Github Actions
- Update development dependency on `rake`.

## [0.7.0] - 2019-04-24

### Added

- `Duration.with_measure`, which yields and returns an array containing its
  evaluated return value and its `Duration`.

### Changed

- Break `Duration` and `Instant` into their own files.
- Rename `Monotime::VERSION` to `Monotime::MONOTIME_VERSION` to reduce
  potential for collision if the module is included.
- Update to bundler 2.0.
- Rework README.md.  Includes fix for [issue #1] (added a "See Also" section).

## [0.6.1] - 2018-10-26

### Fixed

- Build gem from a clean git checkout, not my local development directory.
  No functional changes.

## [0.6.0] - 2018-10-26

### Added

- This `CHANGELOG.md` by request of [@celsworth].
- Aliases for `Duration.from_*` and `Duration#to_*` without the prefix.  e.g.
  `Duration.from_secs(42).to_secs == 42` can now be written as
  `Duration.secs(42).secs == 42`.
- `Duration#nonzero?`.
- `Instant#in_past?` and `Instant#in_future?`.

## [0.5.0] - 2018-10-13

### Added

- `Duration#abs` to make a `Duration` positive.
- `Duration#-@` to invert the sign of a `Duration`.
- `Duration#positive?`
- `Duration#negative?`
- `Duration#zero?`

### Changed

- `Instant#sleep` with no argument now sleeps until the `Instant`.
- `Duration.from_*` no longer coerce their argument to `Float`.
- `Duration#==` checks value via `#to_nanos`, not type.
- `Duration#eql?` checks value and type.
- `Duration#<=>` compares value via `#to_nanos`.

## [0.4.0] - 2018-10-09

### Added

- `Instant#sleep` - sleep to a given `Duration` past an `Instant`.
- `Instant#sleep_secs` and `Instant#sleep_millis` convenience methods.
- `Duration#sleep` - sleep for the `Duration`.
- `Duration#*` - multiply a `Duration` by a number.
- `Duration#/` - divide a `Duration` by a number.

### Changed

 More `#to_nanos` `Duration` duck-typing.

## [0.3.0] - 2018-10-04

### Added

- `#to_nanos` is now used to duck-type `Duration` everywhere.

### Changed

- Make `<=>` return nil on invalid types, rather than raising a `TypeError`.

### Removed

- Dependency on `dry-equalizer`.

## [0.2.0] - 2018-10-03

### Added

- `Instant#to_s` as an alias for `#elapsed.to_s`
- `Duration#to_nanos`, with some limited duck-typing.

### Changed

- Switch to microseconds internally.
- `Duration#to_{secs,millis,micros}` now return a `Float`.
- `Instant#ns` is now `protected`.

### Fixed

- `Duration#to_s` zero-stripping with precision=0.
- `Instant#-` argument ordering with other `Instant`.
- `Duration#to_micros` returns microseconds, not picoseconds.

### Removed

- `Instant` and `Duration` maths methods no longer support passing an `Integer`
  number of nanoseconds.

## [0.1.0] - 2018-10-02

### Added

- Initial release

[0.1.0]: https://github.com/Freaky/monotime/commits/v0.1.0
[0.2.0]: https://github.com/Freaky/monotime/commits/v0.2.0
[0.3.0]: https://github.com/Freaky/monotime/commits/v0.3.0
[0.4.0]: https://github.com/Freaky/monotime/commits/v0.4.0
[0.5.0]: https://github.com/Freaky/monotime/commits/v0.5.0
[0.6.0]: https://github.com/Freaky/monotime/commits/v0.6.0
[0.6.1]: https://github.com/Freaky/monotime/commits/v0.6.1
[0.7.0]: https://github.com/Freaky/monotime/commits/v0.7.0
[0.7.1]: https://github.com/Freaky/monotime/commits/v0.7.0
[0.8.0]: https://github.com/Freaky/monotime/commits/v0.8.0
[0.8.1]: https://github.com/Freaky/monotime/commits/v0.8.1
[issue #1]: https://github.com/Freaky/monotime/issues/1
[Ruby #16740]: https://bugs.ruby-lang.org/issues/16740
[@celsworth]: https://github.com/celsworth
[@petergoldstein]: https://github.com/petergoldstein
[@fig]: https://github.com/fig
