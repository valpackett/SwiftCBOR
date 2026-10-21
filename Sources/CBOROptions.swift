public struct CBOROptions {
    let useStringKeys: Bool
    let dateStrategy: DateStrategy
    let forbidNonStringMapKeys: Bool
    /// The maximum number of nested items, inclusive, to decode. A maximum set to 0 dissallows anything other than top-level primitives.
    let maximumDepth: Int
    let shouldSortMapKeys: Bool
    /// Reject repeated map keys during CBOR decoding instead of keeping the last value.
    let rejectDuplicateMapKeys: Bool

    public init(
        useStringKeys: Bool = false,
        dateStrategy: DateStrategy = .taggedAsEpochTimestamp,
        forbidNonStringMapKeys: Bool = false,
        maximumDepth: Int = .max,
        shouldSortMapKeys: Bool = true,
        rejectDuplicateMapKeys: Bool = false
    ) {
        self.useStringKeys = useStringKeys
        self.dateStrategy = dateStrategy
        self.forbidNonStringMapKeys = forbidNonStringMapKeys
        self.maximumDepth = maximumDepth
        self.shouldSortMapKeys = shouldSortMapKeys
        self.rejectDuplicateMapKeys = rejectDuplicateMapKeys
    }

    func toCodableEncoderOptions() -> CodableCBOREncoder._Options {
        return CodableCBOREncoder._Options(
            useStringKeys: self.useStringKeys,
            dateStrategy: self.dateStrategy,
            forbidNonStringMapKeys: self.forbidNonStringMapKeys
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
