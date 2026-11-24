[![unlicense](https://img.shields.io/badge/un-license-green.svg?style=flat)](http://unlicense.org)

# SwiftCBOR

A [CBOR (Concise Binary Object Representation)](https://www.rfc-editor.org/rfc/rfc8949) decoder and encoder in Swift, implementing RFC 8949. Encode directly from Swift types or use a wrapper object. Decode to a CBOR value type that can be accessed with native Swift subscripting and expressed with the equivalent literal notation.

- A fully cross-platform Swift 5.x package!
- `Codable` support!
- Negative integers are decoded as `NegativeInt(UInt)`, where the actual number is `-1 - i` (CBOR's negative integers can be larger than 64-bit signed integers).
- Tags are preserved as `CBOR.tagged` values and are not otherwise type-checked. With Foundation available, tag 1 (epoch-based date/time) is decoded as `CBOR.date`.
- Literal convertibles are defined for the `CBOR` type!
- And `subscript` too. So you can access CBOR maps and arrays like this: `myDecodedObject["numbers"][1]`.
- If you want to decode from a stream, implement the `CBORInputStream` protocol on your stream and create the decoder like this: `CBORDecoder(stream: yourStream)`.
- Half floats can be decoded to a Float and encoded again from a `CBOR.half` value.
- A map that holds the same key twice keeps the last value for that key. Pass `rejectDuplicateMapKeys` to `CBOROptions` to reject such a map instead, as RFC 8949 Section 5.6 describes.
- Memory efficiency of encoding needs tuning. (Encoding is not typically done in-place.)
- Encoding indefinite-length data is supported but you need to explicitly add open and close information to your streaming data.
- [cbor.me](http://cbor.me) is recommended for viewing your CBOR-encoded data.

## Installation

Swift Package Manager is the recommended dependency manager. You can also use CocoaPods or a git submodule.

CocoaPods Trunk is scheduled to become permanently read-only on **2 December 2026**. Existing pods will remain installable, but new pods and versions will no longer be accepted through Trunk. See the [CocoaPods Specs repository announcement](https://blog.cocoapods.org/CocoaPods-Specs-Repo/) for the current timeline. Swift Package Manager is recommended for new integrations and future updates.

## Decoding

```swift
import SwiftCBOR

let decoded = try! CBOR.decode([0x9f, 0x18, 255, 0x9b, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 2, 0x18, 1, 0x79, 0x00, 3, 0x41, 0x42, 0x43, 0x79, 0x00, 3, 0x41, 0x42, 0x43, 0xff])
print(decoded)
// CBOR.array([CBOR.unsignedInt(255), CBOR.array([CBOR.unsignedInt(1), CBOR.utf8String("ABC")]), CBOR.utf8String("ABC")])
```

To unwrap the decoded `CBOR` values, use [PATTERN MATCHING](https://alisoftware.github.io/swift/pattern-matching/2016/05/16/pattern-matching-4/)!!

Types conforming to `Codable` can use `CodableCBOREncoder` and `CodableCBORDecoder`:

```swift
import Foundation
import SwiftCBOR

struct Message: Codable, Equatable {
    var text: String
    var priority: Int
}

let message = Message(text: "hello", priority: 1)
let data = try CodableCBOREncoder().encode(message)
let decodedMessage = try CodableCBORDecoder().decode(Message.self, from: data)
```

## Encoding

Encoding a value returns an array of bytes, `[UInt8]`. You can encode with `CBOR.encode(myValue)` or `myValue.encode()`. Any type that conforms to the `CBOREncodable` protocol may be encoded. You can implement the `CBOREncodable` protocol for your types and then encode as usual.

```swift
CBOR.encode(100)  // --> [0x18, 0x64] of type [UInt8]
Int(100).encode() // --> [0x18, 0x64]. Int conforms to the CBOREncodable protocol
"hello".encode()  // --> [0x65, 0x68, 0x65, 0x6c, 0x6c, 0x6f]. So does String
CBOR.encode(["a", "b", "c"])

let byteString: [UInt8] = [0x01, 0x02]
CBOR.encode(byteString, asByteString: true)
```

Arrays and dictionaries also provide `encode()` when their elements, keys, and values conform to `CBOREncodable`. Alternatively, use `CBOR.encode(someArrayOrMap)`.

In some cases it may be necessary to create a `CBOR` intermediate representation before encoding. For example, if you want to encode an array or dictionary containing heterogeneous types, as is common for JSON-like objects, you can't use native Swift maps yet. You can implement `CBOREncodable` on your type that would build a `CBOR` value and encode that, or do the `CBOR` value thing without `CBOREncodable`.

The `CBOR` enum can be [expressed with literals](https://developer.apple.com/documentation/swift/initialization_with_literals), but note that variables are not literals, so you might have to call the constructors manually.

```swift
public protocol CBOREncodable {
    func encode(options: CBOROptions) -> [UInt8]
}

struct MyStruct: CBOREncodable {
    var x: Int
    var y: String

    public func encode(options: CBOROptions = CBOROptions()) -> [UInt8] {
        let cborWrapper: CBOR = [
            "x": CBOR(integerLiteral: self.x), // You can use the literal constructors
            "y": CBOR.utf8String(self.y), // Or the enum variants
            "z": 123 // Or literals
        ]
        return cborWrapper.encode()
    }
}

MyStruct(x: 42, y: "words").encode()
// --> bytes (as hex): a2 61 79 65 77 6f 72 64 73 61 78 18 2a
```

The `encode` function doesn't *have* to look like that. If you want to do something custom, like [preserving the order of map keys](https://github.com/valpackett/SwiftCBOR/issues/21), you can build the `[UInt8]` manually. Look at the [encoder functions](https://github.com/valpackett/SwiftCBOR/blob/master/Sources/CBOREncoder.swift) for inspiration.

By default, `shouldSortMapKeys` sorts map entries using the bytewise lexicographic map-key ordering described by RFC 8949 Section 4.2.1. Set it to `false` to disable sorting. Sorting alone does not provide a complete deterministic-encoding mode: preferred float serialization and definite-length encoding also need to be considered for your data.

### Encoding API

The current general-purpose API is listed below. When you need fine grained control over the type you are encoding, use the following.

```swift
func encode<T: CBOREncodable>(_ value: T) -> [UInt8]
func encode<A: CBOREncodable, B: CBOREncodable>(_ dict: [A: B]) -> [UInt8]

// NOTE: Please see the note on encoding byte strings at the end of this readme.
func encode<T: CBOREncodable>(_ array: [T], asByteString: Bool = false) -> [UInt8]

/// Only needed for fine-grained control:
func encodeUInt{8, 16, 32, 64}(_ x: UInt8) -> [UInt8]
func encodeNegativeInt(_ x: Int) -> [UInt8]
func encodeByteString(_ bs: [UInt8]) -> [UInt8] // does no endian interpretation
func encodeString(_ str: String) -> [UInt8]
func encodeArray<T: CBOREncodable>(_ arr: [T]) -> [UInt8]
func encodeMap<A: CBOREncodable, B: CBOREncodable>(_ map: [A: B]) -> [UInt8]
func encodeTagged<T: CBOREncodable>(tag: CBOR.Tag, value: T) -> [UInt8]
func encodeSimpleValue(_ x: UInt8) -> [UInt8]
func encode{Null, Undefined, Break}() -> [UInt8]
func encodeHalf(_ x: Float) -> [UInt8]
func encodeFloat(_ x: Float) -> [UInt8]
func encodeDouble(_ x: Double) -> [UInt8]
func encodeBool(_ x: Bool) -> [UInt8]
```

### Indefinite-length data

To encode indefinite-length arrays, maps, strings, and byte strings, explicitly use the open- and close-stream CBOR values. In between these two values, use encoded array and map *chunks* with `CBOR.encodeArrayChunk` and `CBOR.encodeMapChunk`. Encode each string or byte-string chunk as a normal definite-length value; these chunks do not need their own `chunk` function.

```swift
let map: [String: Int] = ["a": 1]
let map2 = ["B": 2]
CBOR.encodeMapStreamStart() + CBOR.encodeMapChunk(map) + CBOR.encodeMapChunk(map2) + CBOR.encodeStreamEnd()

let bs: [UInt8] = [0xf0]
let bs2: [UInt8] = [0xff]
CBOR.encodeByteStringStreamStart()
    + CBOR.encode(bs, asByteString: true)
    + CBOR.encode(bs2, asByteString: true)
    + CBOR.encodeStreamEnd()

// Current stream-encoding API:
func encodeArrayStreamStart() -> [UInt8]
func encodeMapStreamStart() -> [UInt8]
func encodeStringStreamStart() -> [UInt8]
func encodeByteStringStreamStart() -> [UInt8]
func encodeStreamEnd() -> [UInt8] // Equal to CBOR.encodeBreak()
func encodeArrayChunk<T: CBOREncodable>(_ chunk: [T]) -> [UInt8]
func encodeMapChunk<A: CBOREncodable, B: CBOREncodable>(_ map: [A: B]) -> [UInt8]
```

### Note on endian reversal

Finally, a technical note on encoding byte strings when using the general-purpose array encoder, `CBOR.encode(..)`. If `asByteString` is true, arrays of all types except `UInt8` have the raw bytes of each item reversed (but not the order of the items) on little-endian computers, because CBOR uses big-endian (network) byte order. Arrays of `UInt8` are considered to already be in network byte order.

## Contributing

By participating in this project you agree to follow the [Contributor Code of Conduct](https://contributor-covenant.org/version/1/4/).

[The list of contributors is available on GitHub](https://github.com/valpackett/SwiftCBOR/graphs/contributors).

## License

This is free and unencumbered software released into the public domain.
For more information, please refer to the `UNLICENSE` file or [unlicense.org](https://unlicense.org).
