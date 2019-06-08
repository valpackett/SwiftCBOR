//
//  CBOREncoder.swift
//  Sunday
//
//  Created by Kevin Wooten on 7/11/18.
//  Copyright © 2018 Outfox, Inc. All rights reserved.
//
// This file was adapted from `JSONEncoder.swift` in the
// `swift-corelibs-foundation` project which carries the following
// copyright.
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation


/// `CBOREncoder` facilitates the encoding of `Encodable` values into CBOR values.
open class CBOREncoder {
    // MARK: Options

    /// The strategy to use for encoding `Date` values.
    public enum DateEncodingStrategy {
        /// Encode the `Date` as a UNIX timestamp (as integer seconds).
        case secondsSince1970

        /// Encode the `Date` as UNIX millisecond timestamp (as floating point seconds).
        case millisecondsSince1970

        /// Encode the `Date` as an ISO-8601-formatted string (in RFC 3339 format).
        case iso8601
    }

    /// The strategy to use for automatically changing the value of keys before encoding.
    public enum KeyEncodingStrategy {
        /// Use the keys specified by each type. This is the default strategy.
        case useDefaultKeys

        /// Convert from "camelCaseKeys" to "snake_case_keys" before writing a key to the payload.
        ///
        /// Capital characters are determined by testing membership in `CharacterSet.uppercaseLetters` and `CharacterSet.lowercaseLetters` (Unicode General Categories Lu and Lt).
        /// The conversion to lower case uses `Locale.system`, also known as the ICU "root" locale. This means the result is consistent regardless of the current user's locale and language preferences.
        ///
        /// Converting from camel case to snake case:
        /// 1. Splits words at the boundary of lower-case to upper-case
        /// 2. Inserts `_` between words
        /// 3. Lowercases the entire string
        /// 4. Preserves starting and ending `_`.
        ///
        /// For example, `oneTwoThree` becomes `one_two_three`. `_oneTwoThree_` becomes `_one_two_three_`.
        ///
        /// - Note: Using a key encoding strategy has a nominal performance cost, as each string key has to be converted.
        case convertToSnakeCase

        /// Provide a custom conversion to the encoded key from the keys specified by the encoded types.
        /// The full path to the current encoding position is provided for context (in case you need to locate this key within the payload). The returned key is used in place of the last component in the coding path before encoding.
        /// If the result of the conversion is a duplicate key, then only one value will be present in the result.
        case custom((_ codingPath: [CodingKey]) -> CodingKey)

        internal static func _convertToSnakeCase(_ stringKey: String) -> String {
            guard stringKey.count > 0 else { return stringKey }

            var words : [Range<String.Index>] = []
            // The general idea of this algorithm is to split words on transition from lower to upper case, then on transition of >1 upper case characters to lowercase
            //
            // myProperty -> my_property
            // myURLProperty -> my_url_property
            //
            // We assume, per Swift naming conventions, that the first character of the key is lowercase.
            var wordStart = stringKey.startIndex
            var searchRange = stringKey.index(after: wordStart)..<stringKey.endIndex

            // Find next uppercase character
            while let upperCaseRange = stringKey.rangeOfCharacter(from: CharacterSet.uppercaseLetters, options: [], range: searchRange) {
                let untilUpperCase = wordStart..<upperCaseRange.lowerBound
                words.append(untilUpperCase)

                // Find next lowercase character
                searchRange = upperCaseRange.lowerBound..<searchRange.upperBound
                guard let lowerCaseRange = stringKey.rangeOfCharacter(from: CharacterSet.lowercaseLetters, options: [], range: searchRange) else {
                    // There are no more lower case letters. Just end here.
                    wordStart = searchRange.lowerBound
                    break
                }

                // Is the next lowercase letter more than 1 after the uppercase? If so, we encountered a group of uppercase letters that we should treat as its own word
                let nextCharacterAfterCapital = stringKey.index(after: upperCaseRange.lowerBound)
                if lowerCaseRange.lowerBound == nextCharacterAfterCapital {
                    // The next character after capital is a lower case character and therefore not a word boundary.
                    // Continue searching for the next upper case for the boundary.
                    wordStart = upperCaseRange.lowerBound
                } else {
                    // There was a range of >1 capital letters. Turn those into a word, stopping at the capital before the lower case character.
                    let beforeLowerIndex = stringKey.index(before: lowerCaseRange.lowerBound)
                    words.append(upperCaseRange.lowerBound..<beforeLowerIndex)

                    // Next word starts at the capital before the lowercase we just found
                    wordStart = beforeLowerIndex
                }
                searchRange = lowerCaseRange.upperBound..<searchRange.upperBound
            }
            words.append(wordStart..<searchRange.upperBound)
            let result = words.map({ (range) in
                return stringKey[range].lowercased()
            }).joined(separator: "_")
            return result
        }
    }

    /// The strategy to use in encoding dates. Defaults to `.iso8601`.
    open var dateEncodingStrategy: DateEncodingStrategy = .iso8601

    /// The strategy to use for encoding keys. Defaults to `.useDefaultKeys`.
    open var keyEncodingStrategy: KeyEncodingStrategy = .useDefaultKeys

    /// Contextual user-provided information for use during encoding.
    open var userInfo: [CodingUserInfoKey : Any] = [:]

    /// Options set on the top-level encoder to pass down the encoding hierarchy.
    fileprivate struct _Options {
        let dateEncodingStrategy: DateEncodingStrategy
        let keyEncodingStrategy: KeyEncodingStrategy
        let userInfo: [CodingUserInfoKey : Any]
    }

    /// The options set on the top-level encoder.
    fileprivate var options: _Options {
        return _Options(dateEncodingStrategy: dateEncodingStrategy,
                        keyEncodingStrategy: keyEncodingStrategy,
                        userInfo: userInfo)
    }

    // MARK: - Constructing a CBOR Encoder
    /// Initializes `self` with default strategies.
    public init() {}

    // MARK: - Encoding Values
    /// Encodes the given top-level value and returns its representation.
    ///
    /// - parameter value: The value to encode.
    /// - returns: A new value containing the encoded data.
    /// - throws: `EncodingError.invalidValue` if a non-conforming floating-point value is encountered during encoding, and the encoding strategy is `.throw`.
    /// - throws: An error if any value throws an error during encoding.
    open func encodeTree<T : Encodable>(_ value: T) throws -> CBOR {
        let encoder = _CBOREncoder(options: self.options)

        guard let topLevel = try encoder.box_(value) else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Top-level \(T.self) did not encode any values."))
        }

        return topLevel
    }

    /// Encodes the given top-level value and returns its data.
    ///
    /// - parameter value: The value to encode.
    /// - returns: A new value containing the encoded data.
    /// - throws: `EncodingError.invalidValue` if a non-conforming floating-point value is encountered during encoding, and the encoding strategy is `.throw`.
    /// - throws: An error if any value throws an error during encoding.
    open func encode<T : Encodable>(_ value: T) throws -> Data {
        let tree = try encodeTree(value)
        return try CBORSerialization.data(with: tree)
    }

}

// MARK: - _CBOREncoder
fileprivate class _CBOREncoder : Encoder {
    // MARK: Properties
    /// The encoder's storage.
    fileprivate var storage: _CBOREncodingStorage

    /// Options set on the top-level encoder.
    fileprivate let options: CBOREncoder._Options

    /// The path to the current point in encoding.
    public var codingPath: [CodingKey]

    /// Contextual user-provided information for use during encoding.
    public var userInfo: [CodingUserInfoKey : Any] {
        return self.options.userInfo
    }

    // MARK: - Initialization
    /// Initializes `self` with the given top-level encoder options.
    fileprivate init(options: CBOREncoder._Options, codingPath: [CodingKey] = []) {
        self.options = options
        self.storage = _CBOREncodingStorage()
        self.codingPath = codingPath
    }

    /// Returns whether a new element can be encoded at this coding path.
    ///
    /// `true` if an element has not yet been encoded at this coding path; `false` otherwise.
    fileprivate var canEncodeNewValue: Bool {
        // Every time a new value gets encoded, the key it's encoded for is pushed onto the coding path (even if it's a nil key from an unkeyed container).
        // At the same time, every time a container is requested, a new value gets pushed onto the storage stack.
        // If there are more values on the storage stack than on the coding path, it means the value is requesting more than one container, which violates the precondition.
        //
        // This means that anytime something that can request a new container goes onto the stack, we MUST push a key onto the coding path.
        // Things which will not request containers do not need to have the coding path extended for them (but it doesn't matter if it is, because they will not reach here).
        return self.storage.count == self.codingPath.count
    }

    // MARK: - Encoder Methods
    public func container<Key>(keyedBy: Key.Type) -> KeyedEncodingContainer<Key> {
        // If an existing keyed container was already requested, return that one.
        let topContainer: _KeyedContainer
        if self.canEncodeNewValue {
            // We haven't yet pushed a container at this level; do so here.
            topContainer = self.storage.pushKeyedContainer()
        } else {
            guard let container = self.storage.containers.last as? _KeyedContainer else {
                preconditionFailure("Attempt to push new keyed encoding container when already previously encoded at this path.")
            }

            topContainer = container
        }

        let container = CBORCodingKeyedEncodingContainer<Key>(referencing: self, codingPath: self.codingPath, wrapping: topContainer)
        return KeyedEncodingContainer(container)
    }

    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        // If an existing unkeyed container was already requested, return that one.
        let topContainer: _UnkeyedContainer
        if self.canEncodeNewValue {
            // We haven't yet pushed a container at this level; do so here.
            topContainer = self.storage.pushUnkeyedContainer()
        } else {
            guard let container = self.storage.containers.last as? _UnkeyedContainer else {
                preconditionFailure("Attempt to push new unkeyed encoding container when already previously encoded at this path.")
            }

            topContainer = container
        }

        return _CBORUnkeyedEncodingContainer(referencing: self, codingPath: self.codingPath, wrapping: topContainer)
    }

    public func singleValueContainer() -> SingleValueEncodingContainer {
        return self
    }
}

// MARK: - Encoding Storage and Containers
fileprivate struct _CBOREncodingStorage {
    // MARK: Properties
    /// The container stack.
    /// Elements may be any one of the containers.
    private(set) fileprivate var containers: [_Container] = []

    // MARK: - Initialization
    /// Initializes `self` with no containers.
    fileprivate init() {}

    // MARK: - Modifying the Stack
    fileprivate var count: Int {
        return self.containers.count
    }

    fileprivate mutating func pushKeyedContainer() -> _KeyedContainer {
        let container = _KeyedContainer()
        self.containers.append(container)
        return container
    }

    fileprivate mutating func pushUnkeyedContainer() -> _UnkeyedContainer {
        let container = _UnkeyedContainer()
        self.containers.append(container)
        return container
    }

    fileprivate mutating func push(container: CBOR) {
        self.containers.append(_ValueContainer(value: container))
    }

    fileprivate mutating func popContainer() -> _Container {
        precondition(self.containers.count > 0, "Empty container stack.")
        return self.containers.popLast()!
    }
}

// MARK: - Encoding Containers
fileprivate struct CBORCodingKeyedEncodingContainer<K : CodingKey> : KeyedEncodingContainerProtocol {
    typealias Key = K

    // MARK: Properties
    /// A reference to the encoder we're writing to.
    private let encoder: _CBOREncoder

    /// A reference to the container we're writing to.
    private var container: _KeyedContainer

    /// The path of coding keys taken to get to this point in encoding.
    private(set) public var codingPath: [CodingKey]

    // MARK: - Initialization
    /// Initializes `self` with the given references.
    fileprivate init(referencing encoder: _CBOREncoder, codingPath: [CodingKey], wrapping container: _KeyedContainer) {
        self.encoder = encoder
        self.codingPath = codingPath
        self.container = container
    }

    // MARK: - Coding Path Operations
    private func _converted(_ key: CodingKey) -> CodingKey {
        switch encoder.options.keyEncodingStrategy {
        case .useDefaultKeys:
            return key
        case .convertToSnakeCase:
            let newKeyString = CBOREncoder.KeyEncodingStrategy._convertToSnakeCase(key.stringValue)
            return AnyCodingKey(stringValue: newKeyString, intValue: key.intValue)
        case .custom(let converter):
            return converter(codingPath + [key])
        }
    }

    // MARK: - KeyedEncodingContainerProtocol Methods
    public mutating func encodeNil(forKey key: Key) throws {
        self.container[_converted(key).stringValue] = .null
    }
    public mutating func encode(_ value: Bool, forKey key: Key) throws {
        self.container[_converted(key).stringValue] = try self.encoder.box(value)
    }
    public mutating func encode(_ value: Int, forKey key: Key) throws {
        self.container[_converted(key).stringValue] = try self.encoder.box(value)
    }
    public mutating func encode(_ value: Int8, forKey key: Key) throws {
        self.container[_converted(key).stringValue] = try self.encoder.box(value)
    }
    public mutating func encode(_ value: Int16, forKey key: Key) throws {
        self.container[_converted(key).stringValue] = try self.encoder.box(value)
    }
    public mutating func encode(_ value: Int32, forKey key: Key) throws {
        self.container[_converted(key).stringValue] = try self.encoder.box(value)
    }
    public mutating func encode(_ value: Int64, forKey key: Key) throws {
        self.container[_converted(key).stringValue] = try self.encoder.box(value)
    }
    public mutating func encode(_ value: UInt, forKey key: Key) throws {
        self.container[_converted(key).stringValue] = try self.encoder.box(value)
    }
    public mutating func encode(_ value: UInt8, forKey key: Key) throws {
        self.container[_converted(key).stringValue] = try self.encoder.box(value)
    }
    public mutating func encode(_ value: UInt16, forKey key: Key) throws {
        self.container[_converted(key).stringValue] = try self.encoder.box(value)
    }
    public mutating func encode(_ value: UInt32, forKey key: Key) throws {
        self.container[_converted(key).stringValue] = try self.encoder.box(value)
    }
    public mutating func encode(_ value: UInt64, forKey key: Key) throws {
        self.container[_converted(key).stringValue] = try self.encoder.box(value)
    }
    public mutating func encode(_ value: String, forKey key: Key) throws {
        self.container[_converted(key).stringValue] = try self.encoder.box(value)
    }

    public mutating func encode(_ value: Float, forKey key: Key) throws {
        // Since the float may be invalid and throw, the coding path needs to contain this key.
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        self.container[_converted(key).stringValue] = try self.encoder.box(value)
    }

    public mutating func encode(_ value: Double, forKey key: Key) throws {
        // Since the double may be invalid and throw, the coding path needs to contain this key.
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        self.container[_converted(key).stringValue] = try self.encoder.box(value)
    }

    public mutating func encode<T : Encodable>(_ value: T, forKey key: Key) throws {
        self.encoder.codingPath.append(key)
        defer { self.encoder.codingPath.removeLast() }
        self.container[_converted(key).stringValue] = try self.encoder.box(value)
    }

    public mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
        let keyed = _NestedKeyedContainer(_KeyedNesting(self.container, _converted(key).stringValue))
        self.container[keyed.nesting.key] = keyed.currentValue

        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }

        let container = CBORCodingKeyedEncodingContainer<NestedKey>(referencing: self.encoder, codingPath: self.codingPath, wrapping: keyed)
        return KeyedEncodingContainer(container)
    }

    public mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        let unkeyed = _NestedUnkeyedContainer(_KeyedNesting(self.container, _converted(key).stringValue))
        self.container[unkeyed.nesting.key] = unkeyed.currentValue

        self.codingPath.append(key)
        defer { self.codingPath.removeLast() }
        return _CBORUnkeyedEncodingContainer(referencing: self.encoder, codingPath: self.codingPath, wrapping: unkeyed)
    }

    public mutating func superEncoder() -> Encoder {
        return _CBORReferencingEncoder(referencing: self.encoder, key: AnyCodingKey.super, convertedKey: _converted(AnyCodingKey.super), wrapping: self.container)
    }

    public mutating func superEncoder(forKey key: Key) -> Encoder {
        return _CBORReferencingEncoder(referencing: self.encoder, key: key, convertedKey: _converted(key), wrapping: self.container)
    }
}

fileprivate struct _CBORUnkeyedEncodingContainer : UnkeyedEncodingContainer {
    // MARK: Properties
    /// A reference to the encoder we're writing to.
    private let encoder: _CBOREncoder

    /// A reference to the container we're writing to.
    private var container: _UnkeyedContainer

    /// The path of coding keys taken to get to this point in encoding.
    private(set) public var codingPath: [CodingKey]

    /// The number of elements encoded into the container.
    public var count: Int {
        return self.container.count
    }

    // MARK: - Initialization
    /// Initializes `self` with the given references.
    fileprivate init(referencing encoder: _CBOREncoder, codingPath: [CodingKey], wrapping container: _UnkeyedContainer) {
        self.encoder = encoder
        self.codingPath = codingPath
        self.container = container
    }

    // MARK: - UnkeyedEncodingContainer Methods
    public mutating func encodeNil()             throws { self.container.append(.null) }
    public mutating func encode(_ value: Bool)   throws { self.container.append(try self.encoder.box(value)) }
    public mutating func encode(_ value: Int)    throws { self.container.append(try self.encoder.box(value)) }
    public mutating func encode(_ value: Int8)   throws { self.container.append(try self.encoder.box(value)) }
    public mutating func encode(_ value: Int16)  throws { self.container.append(try self.encoder.box(value)) }
    public mutating func encode(_ value: Int32)  throws { self.container.append(try self.encoder.box(value)) }
    public mutating func encode(_ value: Int64)  throws { self.container.append(try self.encoder.box(value)) }
    public mutating func encode(_ value: UInt)   throws { self.container.append(try self.encoder.box(value)) }
    public mutating func encode(_ value: UInt8)  throws { self.container.append(try self.encoder.box(value)) }
    public mutating func encode(_ value: UInt16) throws { self.container.append(try self.encoder.box(value)) }
    public mutating func encode(_ value: UInt32) throws { self.container.append(try self.encoder.box(value)) }
    public mutating func encode(_ value: UInt64) throws { self.container.append(try self.encoder.box(value)) }
    public mutating func encode(_ value: String) throws { self.container.append(try self.encoder.box(value)) }

    public mutating func encode(_ value: Float)  throws {
        // Since the float may be invalid and throw, the coding path needs to contain this key.
        self.encoder.codingPath.append(AnyCodingKey(intValue: self.count))
        defer { self.encoder.codingPath.removeLast() }
        self.container.append(try self.encoder.box(value))
    }

    public mutating func encode(_ value: Double) throws {
        // Since the double may be invalid and throw, the coding path needs to contain this key.
        self.encoder.codingPath.append(AnyCodingKey(index: self.count))
        defer { self.encoder.codingPath.removeLast() }
        self.container.append(try self.encoder.box(value))
    }

    public mutating func encode<T : Encodable>(_ value: T) throws {
        self.encoder.codingPath.append(AnyCodingKey(index: self.count))
        defer { self.encoder.codingPath.removeLast() }
        self.container.append(try self.encoder.box(value))
    }

    public mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
        self.codingPath.append(AnyCodingKey(index: self.count))
        defer { self.codingPath.removeLast() }

        let keyed = _NestedKeyedContainer(_UnkeyedNesting(self.container, self.container.count))
        self.container.append(keyed.currentValue)

        let container = CBORCodingKeyedEncodingContainer<NestedKey>(referencing: self.encoder, codingPath: self.codingPath, wrapping: keyed)
        return KeyedEncodingContainer(container)
    }

    public mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        self.codingPath.append(AnyCodingKey(index: self.count))
        defer { self.codingPath.removeLast() }

        let unkeyed = _NestedUnkeyedContainer(_UnkeyedNesting(self.container, self.container.count))
        self.container.append(unkeyed.currentValue)

        return _CBORUnkeyedEncodingContainer(referencing: self.encoder, codingPath: self.codingPath, wrapping: unkeyed)
    }

    public mutating func superEncoder() -> Encoder {
        return _CBORReferencingEncoder(referencing: self.encoder, at: self.container.count, wrapping: self.container)
    }
}

extension _CBOREncoder : SingleValueEncodingContainer {
    // MARK: - SingleValueEncodingContainer Methods
    fileprivate func assertCanEncodeNewValue() {
        precondition(self.canEncodeNewValue, "Attempt to encode value through single value container when previously value already encoded.")
    }

    public func encodeNil() throws {
        assertCanEncodeNewValue()
        self.storage.push(container: .null)
    }

    public func encode(_ value: Bool) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: try self.box(value))
    }

    public func encode(_ value: Int) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: try self.box(value))
    }

    public func encode(_ value: Int8) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: try self.box(value))
    }

    public func encode(_ value: Int16) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: try self.box(value))
    }

    public func encode(_ value: Int32) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: try self.box(value))
    }

    public func encode(_ value: Int64) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: try self.box(value))
    }

    public func encode(_ value: UInt) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: try self.box(value))
    }

    public func encode(_ value: UInt8) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: try self.box(value))
    }

    public func encode(_ value: UInt16) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: try self.box(value))
    }

    public func encode(_ value: UInt32) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: try self.box(value))
    }

    public func encode(_ value: UInt64) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: try self.box(value))
    }

    public func encode(_ value: String) throws {
        assertCanEncodeNewValue()
        self.storage.push(container: try self.box(value))
    }

    public func encode(_ value: Float) throws {
        assertCanEncodeNewValue()
        try self.storage.push(container: self.box(value))
    }

    public func encode(_ value: Double) throws {
        assertCanEncodeNewValue()
        try self.storage.push(container: self.box(value))
    }

    public func encode<T : Encodable>(_ value: T) throws {
        assertCanEncodeNewValue()
        try self.storage.push(container: self.box(value))
    }
}

// MARK: - Concrete Value Representations
extension _CBOREncoder {

    /// Returns the given value boxed in a container appropriate for pushing onto the container stack.
    fileprivate func box(_ value: Bool)   throws -> CBOR { return CBOR(value) }
    fileprivate func box(_ value: Int)    throws -> CBOR { return CBOR(Int64(value)) }
    fileprivate func box(_ value: Int8)   throws -> CBOR { return CBOR(Int64(value)) }
    fileprivate func box(_ value: Int16)  throws -> CBOR { return CBOR(Int64(value)) }
    fileprivate func box(_ value: Int32)  throws -> CBOR { return CBOR(Int64(value)) }
    fileprivate func box(_ value: Int64)  throws -> CBOR { return CBOR(Int64(value)) }
    fileprivate func box(_ value: UInt)   throws -> CBOR { return CBOR(UInt64(value)) }
    fileprivate func box(_ value: UInt8)  throws -> CBOR { return CBOR(UInt64(value)) }
    fileprivate func box(_ value: UInt16) throws -> CBOR { return CBOR(UInt64(value)) }
    fileprivate func box(_ value: UInt32) throws -> CBOR { return CBOR(UInt64(value)) }
    fileprivate func box(_ value: UInt64) throws -> CBOR { return CBOR(UInt64(value)) }
    fileprivate func box(_ value: String) throws -> CBOR { return CBOR(value) }
    fileprivate func box(_ value: Float)  throws -> CBOR { return CBOR(value) }
    fileprivate func box(_ value: Double) throws -> CBOR { return CBOR(value) }
    fileprivate func box(_ value: Decimal)throws -> CBOR { return CBOR((value as NSDecimalNumber).doubleValue) }
    fileprivate func box(_ value: Data)   throws -> CBOR { return CBOR(value) }
    fileprivate func box(_ value: URL)    throws -> CBOR { return .tagged(.uri, .utf8String(value.absoluteString)) }

    fileprivate func box(_ value: UUID) throws -> CBOR {
        return withUnsafeBytes(of: value) { ptr in
            let bytes = Data(ptr.bindMemory(to: UInt8.self))
            return .tagged(.uuid, .byteString(bytes))
        }
    }

    fileprivate func box(_ value: Date)   throws -> CBOR {
        switch options.dateEncodingStrategy {
        case .iso8601: return .tagged(.iso8601DateTime, .utf8String(_iso8601Formatter.string(from: value)))
        case .secondsSince1970: return .tagged(.epochDateTime, CBOR(Int64(value.timeIntervalSince1970)))
        case .millisecondsSince1970: return .tagged(.epochDateTime, CBOR(value.timeIntervalSince1970))
        }
    }

    fileprivate func box(_ dict: [String : Encodable]) throws -> CBOR? {
        let depth = self.storage.count
        let result = self.storage.pushKeyedContainer()
        do {
            for (key, value) in dict {
                self.codingPath.append(AnyCodingKey(stringValue: key, intValue: nil))
                defer { self.codingPath.removeLast() }
                result[key] = try box(value)
            }
        } catch {
            // If the value pushed a container before throwing, pop it back off to restore state.
            if self.storage.count > depth {
                let _ = self.storage.popContainer()
            }

            throw error
        }

        // The top container should be a new container.
        guard self.storage.count > depth else {
            return nil
        }

        return self.storage.popContainer().value
    }

    fileprivate func box(_ value: Encodable) throws -> CBOR {
        return try self.box_(value) ?? .map([:])
    }

    // This method is called "box_" instead of "box" to disambiguate it from the overloads. Because the return type here is different from all of the "box" overloads (and is more general), any "box" calls in here would call back into "box" recursively instead of calling the appropriate overload, which is not what we want.
    fileprivate func box_(_ value: Encodable) throws -> CBOR? {
        let type = Swift.type(of: value)
        if type == Date.self || type == NSDate.self {
            // Respect Date encoding strategy
            return try self.box((value as! Date))
        } else if type == Data.self || type == NSData.self {
            // Respect Data encoding strategy
            return try self.box((value as! Data))
        } else if type == URL.self || type == NSURL.self {
            // Encode URLs as single strings.
            return try self.box((value as! URL).absoluteString)
        } else if type == Decimal.self || type == NSDecimalNumber.self {
            // Encode Decimals as doubles.
            return try self.box(NSDecimalNumber(decimal: value as! Decimal).doubleValue)
        } else if value is _CBORStringDictionaryEncodableMarker {
            return try self.box(value as! [String: Encodable])
        }

        // The value should request a container from the _CBOREncoder.
        let depth = self.storage.count
        do {
            try value.encode(to: self)
        } catch {
            // If the value pushed a container before throwing, pop it back off to restore state.
            if self.storage.count > depth {
                let _ = self.storage.popContainer()
            }

            throw error
        }

        // The top container should be a new container.
        guard self.storage.count > depth else {
            return nil
        }

        return self.storage.popContainer().value
    }
}

// MARK: - _CBORReferencingEncoder
/// _CBORReferencingEncoder is a special subclass of _CBOREncoder which has its own storage, but references the contents of a different encoder.
/// It's used in superEncoder(), which returns a new encoder for encoding a superclass -- the lifetime of the encoder should not escape the scope it's created in, but it doesn't necessarily know when it's done being used (to write to the original container).
fileprivate class _CBORReferencingEncoder : _CBOREncoder {
    // MARK: Reference types.
    /// The type of container we're referencing.
    private enum Reference {
        /// Referencing a specific index in an array container.
        case unkeyed(_UnkeyedContainer, Int)

        /// Referencing a specific key in a dictionary container.
        case keyed(_KeyedContainer, String)
    }

    // MARK: - Properties
    /// The encoder we're referencing.
    fileprivate let encoder: _CBOREncoder

    /// The container reference itself.
    private var reference: Reference

    // MARK: - Initialization
    /// Initializes `self` by referencing the given array container in the given encoder.
    fileprivate init(referencing encoder: _CBOREncoder, at index: Int, wrapping unkeyed: _UnkeyedContainer) {
        self.encoder = encoder
        self.reference = .unkeyed(unkeyed, index)
        super.init(options: encoder.options, codingPath: encoder.codingPath)

        self.codingPath.append(AnyCodingKey(index: index))
    }

    /// Initializes `self` by referencing the given dictionary container in the given encoder.
    fileprivate init(referencing encoder: _CBOREncoder,
                     key: CodingKey, convertedKey: CodingKey, wrapping keyed: _KeyedContainer) {
        self.encoder = encoder
        self.reference = .keyed(keyed, convertedKey.stringValue)
        super.init(options: encoder.options, codingPath: encoder.codingPath)

        self.codingPath.append(key)
    }

    // MARK: - Coding Path Operations
    fileprivate override var canEncodeNewValue: Bool {
        // With a regular encoder, the storage and coding path grow together.
        // A referencing encoder, however, inherits its parents coding path, as well as the key it was created for.
        // We have to take this into account.
        return self.storage.count == self.codingPath.count - self.encoder.codingPath.count - 1
    }

    // MARK: - Deinitialization
    // Finalizes `self` by writing the contents of our storage to the referenced encoder's storage.
    deinit {
        let value: CBOR
        switch self.storage.count {
        case 0: value = .map([:])
        case 1: value = self.storage.popContainer().value
        default: fatalError("Referencing encoder deallocated with multiple containers on stack.")
        }

        switch self.reference {
        case .unkeyed(let unkeyed, let index):
            unkeyed.insert(value, at: index)

        case .keyed(let keyed, let key):
            keyed[key] = value
        }
    }
}

private protocol _Container {
    var value: CBOR { get }
}

private struct _ValueContainer : _Container {

    fileprivate var value: CBOR

}

private class _KeyedContainer : _Container {

    fileprivate var backing: [String: CBOR] = [:]

    fileprivate subscript(key: String) -> CBOR? {
        get {
            return backing[key]
        }
        set {
            backing[key] = newValue
        }
    }

    fileprivate var value: CBOR { return .map(Dictionary(uniqueKeysWithValues: backing.map { key, value in (CBOR(key), value) })) }

}

private protocol _Nesting {

    func finalize(_ value: CBOR)

}

private class _UnkeyedContainer : _Container {

    fileprivate var backing: [CBOR] = []

    fileprivate var count: Int { return backing.count }

    fileprivate func append(_ newElement: CBOR) {
        backing.append(newElement)
    }

    fileprivate func insert(_ newElement: CBOR, at: Int) {
        backing.insert(newElement, at: at)
    }

    fileprivate subscript(index: Int) -> CBOR {
        get {
            return backing[index]
        }
        set {
            backing[index] = newValue
        }
    }

    fileprivate var value: CBOR { return .array(backing) }

}

private struct _KeyedNesting : _Nesting {

    fileprivate let parent: _KeyedContainer
    fileprivate let key: String

    fileprivate init(_ parent: _KeyedContainer, _ key: String) {
        self.parent = parent
        self.key = key
    }

    func finalize(_ value: CBOR) {
        parent[key] = value
    }

}

private struct _UnkeyedNesting : _Nesting {

    fileprivate let parent: _UnkeyedContainer
    fileprivate let index: Int

    fileprivate init(_ parent: _UnkeyedContainer, _ index: Int) {
        self.parent = parent
        self.index = index
    }

    func finalize(_ value: CBOR) {
        parent[index] = value
    }

}

private class _NestedKeyedContainer<N: _Nesting> : _KeyedContainer {

    fileprivate let nesting: N

    required init(_ nesting: N) {
        self.nesting = nesting
        super.init()
    }

    var currentValue: CBOR {
        return super.value
    }

    override var value: CBOR {
        let value = super.value
        nesting.finalize(value)
        return value
    }

}

private class _NestedUnkeyedContainer<N: _Nesting> : _UnkeyedContainer {

    fileprivate let nesting: N

    required init(_ nesting: N) {
        self.nesting = nesting
        super.init()
    }

    var currentValue: CBOR {
        return super.value
    }

    override var value: CBOR {
        let value = super.value
        nesting.finalize(value)
        return value
    }

}

private let _iso8601Formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
    return formatter
}()

/// A marker protocol used to determine whether a value is a `String`-keyed `Dictionary`
/// containing `Encodable` values (in which case it should be exempt from key conversion strategies).
///
fileprivate protocol _CBORStringDictionaryEncodableMarker { }

extension Dictionary : _CBORStringDictionaryEncodableMarker where Key == String, Value: Encodable { }
