# Changelog

## 0.7.0

### Added

- `CBOROptions` now supports `useShortestFloatEncoding`, `useShortestIntegerEncoding`, and `rejectDuplicateMapKeys`. `CodableCBOREncoder` exposes `shouldSortMapKeys`, `useShortestFloatEncoding`, and `useShortestIntegerEncoding`; `CodableCBORDecoder` exposes `maximumDepth`.
- `CBOREncodable.encode(into:options:)` supports encoding into a shared output buffer. Its default implementation preserves source compatibility for existing conforming types, which can override it to avoid temporary arrays.
- `CBOR.encodeHalf(_:)` provides explicit half-precision floating-point encoding, and `CBORError.duplicateMapKey` reports rejected duplicate map keys.
- An Apple privacy manifest is included with Swift Package Manager and CocoaPods distributions. FreeBSD compilation is supported.

### Changed

- **Source-breaking:** the `CBOROptions` initializer label `shouldShortMapKeys` has been corrected to `shouldSortMapKeys`.
- General-purpose integer and floating-point encoding now defaults to RFC 8949 preferred shortest-width serialization. This changes the default byte output for some `UInt16`, `UInt32`, `UInt64`, `Float`, and `Double` values.
- The `useShortestIntegerEncoding` and `useShortestFloatEncoding` options on `CBOROptions` and `CodableCBOREncoder` can be set to `false` to retain fixed-width output for that kind of value.
- Fine-grained `CBOR.encodeUInt16`, `CBOR.encodeUInt32`, and `CBOR.encodeUInt64` remain available for explicit fixed-width integer output.
- `CodableCBOREncoder` now sorts map entries deterministically by their encoded key bytes by default. Set `shouldSortMapKeys` to `false` to disable sorting.
- With the existing default map-key sorting and definite-length encoding of sized values, the new defaults provide RFC 8949 core deterministic encoding for ordinary values through both the direct `CBOR` API and `CodableCBOREncoder`. Explicit indefinite-length streaming values are not covered by that guarantee.
- Duplicate map keys continue to keep the last value by default. Enable `rejectDuplicateMapKeys` to throw `CBORError.duplicateMapKey` instead.

### Fixed

- `CBOR.half` now encodes as half precision instead of `undefined`; subnormal half-precision decoding and half-precision tag 1 epoch timestamps are handled correctly.
- Codable class hierarchies can use `superEncoder`, and multiple keyed encoding containers can be created on one encoder.
- Assigning `nil` through a `CBOR` subscript no longer traps: array elements become `.null` and map entries are removed.
- Malformed CBOR now throws decoding errors instead of trapping or being accepted in several cases, and `maximumDepth` is enforced throughout Codable decoding containers.
- Decoded negative integers across the full CBOR range, down to `-2^64`, can be re-encoded without trapping.
