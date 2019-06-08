import Foundation


/// Convenience API for serializing and deserialization CBOR items.
///
/// The API is simple and should fit most user's needs, if
/// required users can drop down and use `CBORStreamEncoder`/
/// `CBORStreamDecoder` directly.
public struct CBORSerialization {

    /// Errors throws during serialization and deserialization
    ///
    /// + Note: These are informational only, all errors are
    /// fatal and represent corrupted data; no recovery is
    /// possible
    public enum Error : Swift.Error {
        /// End of data stream unexpectedly encounteredd during deserialization
        case unexpectedEndOfStream
        /// Invalid item type was encountered during deserialization
        case invalidItemType
        /// Invalid indefinite sequence item was encountered during deserialization
        /// + Important: `string` and `byte-string` that are indefinitely encoded
        /// must only contains items of their corresponding type. E.g. An indefinite
        /// `string` must only contain other `strings`
        case invalidIndefiniteElement
        /// Invalid `break` item encountered during deserialization
        case invalidBreak
        /// A sequence with more than `Int32.max` items was encountered during
        /// deserialization
        case sequenceTooLong
        /// An invalid UTF-8 `string` sequence was encountered during deserialization
        case invalidUTF8String
    }

    /// Serialize `CBOR` value into a byte data.
    ///
    /// - Parameters:
    ///     - with: The `CBOR` item to serialize
    /// - Throws:
    ///     - `Swift.Error`: If any stream I/O error is encountered
    public static func data(with value: CBOR) throws -> Data {
        let stream = CBORDataStream()
        let encoder = CBORStreamEncoder(stream: stream)
        try encoder.encode(value)
        return stream.data
    }

    /// Deserialize CBOR encoded `Data` object.
    ///
    /// - Parameters:
    ///     - from: The `Data` value containing CBOR encoded bytes
    /// - Throws:
    ///     - `CBORSerialization.Error`: if any corrupted data is encountered
    ///     - 'Swift.Error`: if any stream I/O error is encountered
    public static func cbor(from data: Data) throws -> CBOR {
        return try cbor(from: CBORDataStream(data: data))
    }

    /// Deserialize CBOR encoded data stream.
    ///
    /// - Parameters:
    ///     - from: The stream containing CBOR encoded bytes
    /// - Throws:
    ///     - `CBORSerialization.Error`: if any corrupted data is encountered
    ///     - 'Swift.Error`: if any stream I/O error is encountered
    public static func cbor(from stream: CBORInputStream) throws -> CBOR {
        return try CBORStreamDecoder(stream: stream).decodeRequiredItem()
    }

}
