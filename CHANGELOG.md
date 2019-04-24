# Changelog

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
- More `#to_nanos` `Duration` duck-typing.

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
[issue #1]: https://github.com/Freaky/monotime/issues/1
[@celsworth]: https://github.com/celsworth
