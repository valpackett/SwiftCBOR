public struct CBOROptions {
    let useStringKeys: Bool

    public init(useStringKeys: Bool = false) {
        self.useStringKeys = useStringKeys
    }

    func toEncoderOptions() -> CodableCBOREncoder._Options {
        return CodableCBOREncoder._Options(useStringKeys: self.useStringKeys)
    }
}
