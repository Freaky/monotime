# Changelog

## 0.6.0 - unreleased
### Added
 - This `CHANGELOG.md` by request of [@celsworth].

## [0.5.0] - 2018-10-13
### Added
 - `Duration#abs` to make a `Duration` positive.
 - `Duration#-@` to invert the sign of a `Duration`.

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
 - `Duration#to_micros` returns microseconds, not picoseconds.
 - Fixed `Instant#-` argument ordering with other `Instant`.
 - `Instant#ns` is now `protected`.
 - Fixed `Duration#to_s` zero-stripping with precision=0.

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
[@celsworth]: https://github.com/celsworth
