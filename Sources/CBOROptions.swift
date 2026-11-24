public struct CBOROptions {
    let useStringKeys: Bool
    let dateStrategy: DateStrategy
    let forbidNonStringMapKeys: Bool
    /// The maximum number of nested items, inclusive, to decode. A maximum set to 0 dissallows anything other than top-level primitives.
    let maximumDepth: Int
    let shouldSortMapKeys: Bool
    /// Whether to use the shortest floating-point encoding that preserves the value exactly.
    let useShortestFloatEncoding: Bool
    /// Whether to reject a map that holds the same key more than once.
    ///
    /// A map with duplicate keys is well formed, but not valid. RFC 8949 Section 5.6 lists
    /// three things a generic decoder can do with them, of which rejecting them is the one
    /// that is universally useful. The decoder rejects them when this is true, and keeps
    /// the last value for a key that appears more than once when it is false.
    let rejectDuplicateMapKeys: Bool

    public init(
        useStringKeys: Bool = false,
        dateStrategy: DateStrategy = .taggedAsEpochTimestamp,
        forbidNonStringMapKeys: Bool = false,
        maximumDepth: Int = .max,
        shouldSortMapKeys: Bool = true,
        useShortestFloatEncoding: Bool = false,
        rejectDuplicateMapKeys: Bool = false
    ) {
        self.useStringKeys = useStringKeys
        self.dateStrategy = dateStrategy
        self.forbidNonStringMapKeys = forbidNonStringMapKeys
        self.maximumDepth = maximumDepth
        self.shouldSortMapKeys = shouldSortMapKeys
        self.useShortestFloatEncoding = useShortestFloatEncoding
        self.rejectDuplicateMapKeys = rejectDuplicateMapKeys
    }

    func toCodableEncoderOptions() -> CodableCBOREncoder._Options {
        return CodableCBOREncoder._Options(
            useStringKeys: self.useStringKeys,
            dateStrategy: self.dateStrategy,
            forbidNonStringMapKeys: self.forbidNonStringMapKeys,
            useShortestFloatEncoding: self.useShortestFloatEncoding
        )
    }

    func toCodableDecoderOptions() -> CodableCBORDecoder._Options {
        return CodableCBORDecoder._Options(
            useStringKeys: self.useStringKeys,
            dateStrategy: self.dateStrategy,
            maximumDepth: self.maximumDepth
        )
    }
}

public enum DateStrategy {
    case taggedAsEpochTimestamp
    case annotatedMap
}

struct AnnotatedMapDateStrategy {
    static let typeKey = "__type"
    static let typeValue = "date_epoch_timestamp"
    static let valueKey = "__value"
}

protocol SwiftCBORStringKey {}

extension String: SwiftCBORStringKey {}
