public struct CBOROptions {
    let useStringKeys: Bool
    let dateStrategy: DateStrategy
    let forbidNonStringMapKeys: Bool

    public init(
        useStringKeys: Bool = false,
        dateStrategy: DateStrategy = .taggedAsEpochTimestamp,
        forbidNonStringMapKeys: Bool = false
    ) {
        self.useStringKeys = useStringKeys
        self.dateStrategy = dateStrategy
        self.forbidNonStringMapKeys = forbidNonStringMapKeys
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
            dateStrategy: self.dateStrategy
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
