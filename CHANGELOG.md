# Changelog

## 0.7.0

### Changed

- General-purpose integer and floating-point encoding now defaults to RFC 8949 preferred shortest-width serialization. This changes the default byte output for some `UInt16`, `UInt32`, `UInt64`, `Float`, and `Double` values.
- The `useShortestIntegerEncoding` and `useShortestFloatEncoding` options on `CBOROptions` and `CodableCBOREncoder` can be set to `false` to retain fixed-width output for that kind of value.
- Fine-grained `CBOR.encodeUInt16`, `CBOR.encodeUInt32`, and `CBOR.encodeUInt64` remain available for explicit fixed-width integer output.
- With the existing default map-key sorting and definite-length encoding of sized values, the new defaults provide RFC 8949 core deterministic encoding for ordinary values through both the direct `CBOR` API and `CodableCBOREncoder`. Explicit indefinite-length streaming values are not covered by that guarantee.
