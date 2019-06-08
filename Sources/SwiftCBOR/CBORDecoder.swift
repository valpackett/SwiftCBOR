//
//  CBORDecoder.swift
//  Sunday
//
//  Created by Kevin Wooten on 6/25/18.
//  Copyright © 2018 Outfox, Inc. All rights reserved.
//
//
// This file was adapted from `JSONDecoder.swift` in the
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


/// `CBORDecoder` facilitates the decoding of CBOR into semantic `Decodable` types.
open class CBORDecoder {

    /// The strategy to use for automatically changing the value of keys before decoding.
    public enum KeyDecodingStrategy {

        /// Use the keys specified by each type. This is the default strategy.
        case useDefaultKeys

        /// Convert from "snake_case_keys" to "camelCaseKeys" before attempting to match a key with the one specified by each type.
        ///
        /// The conversion to upper case uses `Locale.system`, also known as the ICU "root" locale. This means the result is consistent regardless of the current user's locale and language preferences.
        ///
        /// Converting from snake case to camel case:
        /// 1. Capitalizes the word starting after each `_`
        /// 2. Removes all `_`
        /// 3. Preserves starting and ending `_` (as these are often used to indicate private variables or other metadata).
        /// For example, `one_two_three` becomes `oneTwoThree`. `_one_two_three_` becomes `_oneTwoThree_`.
        ///
        /// - Note: Using a key decoding strategy has a nominal performance cost, as each string key has to be inspected for the `_` character.
        case convertFromSnakeCase

        /// Provide a custom conversion from the key in the encoded CBOR to the keys specified by the decoded types.
        /// The full path to the current decoding position is provided for context (in case you need to locate this key within the payload). The returned key is used in place of the last component in the coding path before decoding.
        /// If the result of the conversion is a duplicate key, then only one value will be present in the container for the type to decode from.
        case custom(([CodingKey]) -> CodingKey)
    }

    /// The strategy to use for decoding keys. Defaults to `.useDefaultKeys`.
    open var keyDecodingStrategy: KeyDecodingStrategy = .useDefaultKeys

    /// Contextual user-provided information for use during decoding.
    open var userInfo: [CodingUserInfoKey : Any] = [:]

    /// Options set on the top-level encoder to pass down the decoding hierarchy.
    fileprivate struct _Options {
        let keyDecodingStrategy: KeyDecodingStrategy
        let userInfo: [CodingUserInfoKey : Any]
    }

    /// The options set on the top-level decoder.
    fileprivate var options: _Options {
        return _Options(
            keyDecodingStrategy: keyDecodingStrategy,
            userInfo: userInfo
        )
    }

    // MARK: - Constructing a CBOR Decoder
    /// Initializes `self` with default strategies.
    public init() {}

    // MARK: - Decoding Values

    /// Decodes a top-level value of the given type from the given value.
    ///
    /// - parameter type: The type of the value to decode.
    /// - parameter CBOR: The value to decode from.
    /// - returns: A value of the requested type.
    /// - throws: `DecodingError.dataCorrupted` if values requested from the payload are corrupted.
    /// - throws: `DecodingError.valueNotFound` if source contains a `null` value.
    /// - throws: An error if any value throws an error during decoding.
    public func decode<T : Decodable>(_ type: T.Type, from CBOR: CBOR) throws -> T {
        guard let value = try decodeIfPresent(type, from: CBOR) as T? else {
            throw DecodingError.valueNotFound(T.self,
                                              DecodingError.Context(codingPath: [],
                                                                    debugDescription: "CBOR contained null when attempting to decode non-optional type"))
        }
        return value
    }

    /// Decodes a top-level value of the given type from the given data.
    ///
    /// - parameter type: The type of the value to decode.
    /// - parameter CBOR: The value to decode from.
    /// - returns: A value of the requested type.
    /// - throws: `DecodingError.dataCorrupted` if values requested from the payload are corrupted.
    /// - throws: `DecodingError.valueNotFound` if source contains a `null` value.
    /// - throws: An error if any value throws an error during decoding.
    public func decode<T : Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let CBOR = try CBORSerialization.cbor(from: data)
        guard CBOR != .null, let value = try decodeIfPresent(type, from: CBOR) as T? else {
            throw DecodingError.valueNotFound(T.self,
                                              DecodingError.Context(codingPath: [],
                                                                    debugDescription: "CBOR contained null when attempting to decode non-optional type"))
        }
        return value
    }

    /// Decodes a top-level value of the given type from the given value or
    /// nil if the value contains a `null`.
    ///
    /// - parameter type: The type of the value to decode.
    /// - parameter CBOR: The value to decode from.
    /// - returns: A value of the requested type or nil.
    /// - throws: `DecodingError.dataCorrupted` if values requested from the payload are corrupted.
    /// - throws: An error if any value throws an error during decoding.
    open func decodeIfPresent<T : Decodable>(_ type: T.Type, from CBOR: CBOR) throws -> T? {
        guard !CBOR.isNull else { return nil }
        let decoder = _CBORDecoder(referencing: CBOR, options: self.options)
        guard let value = try decoder.unbox(CBOR, as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: [], debugDescription: "The given data did not contain a top-level value."))
        }
        return value
    }

    /// Decodes a top-level value of the given type from the given value or
    /// nil if the value contains a `null`.
    ///
    /// - parameter type: The type of the value to decode.
    /// - parameter CBOR: The value to decode from.
    /// - returns: A value of the requested type or nil.
    /// - throws: `DecodingError.dataCorrupted` if values requested from the payload are corrupted.
    /// - throws: An error if any value throws an error during decoding.
    open func decodeIfPresent<T : Decodable>(_ type: T.Type, from data: Data) throws -> T? {
        let CBOR = try CBORSerialization.cbor(from: data)
        guard CBOR != .null else { return nil }
        let decoder = _CBORDecoder(referencing: CBOR, options: self.options)
        guard let value = try decoder.unbox(CBOR, as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: [], debugDescription: "The given data did not contain a top-level value."))
        }
        return value
    }

}

// MARK: - _CBORDecoder
fileprivate class _CBORDecoder : Decoder {
    // MARK: Properties
    /// The decoder's storage.
    fileprivate var storage: _CBORDecodingStorage

    /// Options set on the top-level decoder.
    fileprivate let options: CBORDecoder._Options

    /// The path to the current point in encoding.
    fileprivate(set) public var codingPath: [CodingKey]

    /// Contextual user-provided information for use during encoding.
    public var userInfo: [CodingUserInfoKey : Any] {
        return self.options.userInfo
    }

    // MARK: - Initialization
    /// Initializes `self` with the given top-level container and options.
    fileprivate init(referencing container: CBOR, at codingPath: [CodingKey] = [], options: CBORDecoder._Options) {
        self.storage = _CBORDecodingStorage()
        self.storage.push(container: container)
        self.codingPath = codingPath
        self.options = options
    }

    // MARK: - Decoder Methods
    public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        guard !self.storage.topContainer.isNull else {
            throw DecodingError.valueNotFound(KeyedDecodingContainer<Key>.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get keyed decoding container -- found null value instead."))
        }

        guard let topContainer = try valueToKeyedValues(self.storage.topContainer, at: self.codingPath) else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: [String : CBOR].self, reality: self.storage.topContainer)
        }

        let container = CBORCodingKeyedDecodingContainer<Key>(referencing: self, wrapping: topContainer)
        return KeyedDecodingContainer(container)
    }

    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard !self.storage.topContainer.isNull else {
            throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get unkeyed decoding container -- found null value instead."))
        }

        guard let topContainer = try valueToUnkeyedValues(self.storage.topContainer, at: self.codingPath) else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: [CBOR].self, reality: self.storage.topContainer)
        }

        return _CBORUnkeyedDecodingContainer(referencing: self, wrapping: topContainer)
    }

    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        return self
    }
}

// MARK: - Decoding Storage
fileprivate struct _CBORDecodingStorage {
    // MARK: Properties
    /// The container stack.
    private(set) fileprivate var containers: [CBOR] = []

    // MARK: - Initialization
    /// Initializes `self` with no containers.
    fileprivate init() {}

    // MARK: - Modifying the Stack
    fileprivate var count: Int {
        return self.containers.count
    }

    fileprivate var topContainer: CBOR {
        precondition(self.containers.count > 0, "Empty container stack.")
        return self.containers.last!
    }

    fileprivate mutating func push(container: CBOR) {
        self.containers.append(container)
    }

    fileprivate mutating func popContainer() {
        precondition(self.containers.count > 0, "Empty container stack.")
        self.containers.removeLast()
    }
}

// MARK: Decoding Containers
fileprivate struct CBORCodingKeyedDecodingContainer<K : CodingKey> : KeyedDecodingContainerProtocol {
    typealias Key = K

    // MARK: Properties
    /// A reference to the decoder we're reading from.
    private let decoder: _CBORDecoder

    /// A reference to the container we're reading from.
    private let container: [String : CBOR]

    /// The path of coding keys taken to get to this point in decoding.
    private(set) public var codingPath: [CodingKey]

    // MARK: - Initialization
    /// Initializes `self` by referencing the given decoder and container.
    fileprivate init(referencing decoder: _CBORDecoder, wrapping container: [String : CBOR]) {
        self.decoder = decoder
        switch decoder.options.keyDecodingStrategy {
        case .convertFromSnakeCase:
            // Convert the snake case keys in the container to camel case.
            // If we hit a duplicate key after conversion, then we'll use the first one we saw. Effectively an undefined behavior with dictionaries.
            self.container = Dictionary(container.map {
                (CBORDecoder.KeyDecodingStrategy._convertFromSnakeCase($0.key), $0.value)
            }, uniquingKeysWith: { (first, _) in first })
        case .custom(let converter):
            self.container = Dictionary(container.map {
                key, value in (converter(decoder.codingPath + [AnyCodingKey(stringValue: key, intValue: nil)]).stringValue, value)
            }, uniquingKeysWith: { (first, _) in first })
        case .useDefaultKeys:
            fallthrough
        @unknown default:
            self.container = container
        }
        self.codingPath = decoder.codingPath
    }

    // MARK: - KeyedDecodingContainerProtocol Methods
    public var allKeys: [Key] {
        return self.container.keys.compactMap { Key(stringValue: $0) }
    }

    public func contains(_ key: Key) -> Bool {
        return self.container[key.stringValue] != nil
    }

    internal func notFoundError(key: Key) -> DecodingError {
        return DecodingError.keyNotFound(key, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "No value associated with key \(_errorDescription(of: key))."))
    }

    internal func nullFoundError<T>(type: T.Type) -> DecodingError {
        return DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
    }

    private func _errorDescription(of key: CodingKey) -> String {
        switch decoder.options.keyDecodingStrategy {
        case .convertFromSnakeCase:
            // In this case we can attempt to recover the original value by reversing the transform
            let original = key.stringValue
            let converted = CBOREncoder.KeyEncodingStrategy._convertToSnakeCase(original)
            if converted == original {
                return "\(key) (\"\(original)\")"
            } else {
                return "\(key) (\"\(original)\"), converted to \(converted)"
            }
        default:
            // Otherwise, just report the converted string
            return "\(key) (\"\(key.stringValue)\")"
        }
    }

    public func decodeNil(forKey key: Key) throws -> Bool {
        guard let entry = self.container[key.stringValue] else {
            throw notFoundError(key: key)
        }

        return entry.isNull
    }

    internal func decode<T : Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
        guard let entry = self.container[key.stringValue] else {
            throw notFoundError(key: key)
        }

        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = try self.decoder.unbox(entry, as: type) else {
            throw nullFoundError(type: type)
        }

        return value
    }

    public func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key,
                                            DecodingError.Context(codingPath: self.codingPath,
                                                                  debugDescription: "Cannot get \(KeyedDecodingContainer<NestedKey>.self) -- no value found for key \(_errorDescription(of: key))"))
        }

        guard let dictionary = try valueToKeyedValues(value, at: self.codingPath) else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: [String : CBOR].self, reality: value)
        }

        let container = CBORCodingKeyedDecodingContainer<NestedKey>(referencing: self.decoder, wrapping: dictionary)
        return KeyedDecodingContainer(container)
    }

    public func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        guard let value = self.container[key.stringValue] else {
            throw DecodingError.keyNotFound(key,
                                            DecodingError.Context(codingPath: self.codingPath,
                                                                  debugDescription: "Cannot get UnkeyedDecodingContainer -- no value found for key \(_errorDescription(of: key))"))
        }

        guard let array = try valueToUnkeyedValues(value, at: self.codingPath) else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: [CBOR].self, reality: value)
        }

        return _CBORUnkeyedDecodingContainer(referencing: self.decoder, wrapping: array)
    }

    private func _superDecoder(forKey key: CodingKey) throws -> Decoder {
        self.decoder.codingPath.append(key)
        defer { self.decoder.codingPath.removeLast() }

        let value: CBOR = self.container[key.stringValue] ?? .null
        return _CBORDecoder(referencing: value, at: self.decoder.codingPath, options: self.decoder.options)
    }

    public func superDecoder() throws -> Decoder {
        return try _superDecoder(forKey: AnyCodingKey.super)
    }

    public func superDecoder(forKey key: Key) throws -> Decoder {
        return try _superDecoder(forKey: key)
    }
}

fileprivate struct _CBORUnkeyedDecodingContainer : UnkeyedDecodingContainer {
    // MARK: Properties
    /// A reference to the decoder we're reading from.
    private let decoder: _CBORDecoder

    /// A reference to the container we're reading from.
    private let container: [CBOR]

    /// The path of coding keys taken to get to this point in decoding.
    private(set) public var codingPath: [CodingKey]

    /// The index of the element we're about to decode.
    private(set) public var currentIndex: Int

    // MARK: - Initialization
    /// Initializes `self` by referencing the given decoder and container.
    fileprivate init(referencing decoder: _CBORDecoder, wrapping container: [CBOR]) {
        self.decoder = decoder
        self.container = container
        self.codingPath = decoder.codingPath
        self.currentIndex = 0
    }

    // MARK: - UnkeyedDecodingContainer Methods
    public var count: Int? {
        return self.container.count
    }

    public var isAtEnd: Bool {
        return self.currentIndex >= self.count!
    }

    public mutating func decodeNil() throws -> Bool {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(Any?.self, DecodingError.Context(codingPath: self.decoder.codingPath + [AnyCodingKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        if self.container[self.currentIndex].isNull {
            self.currentIndex += 1
            return true
        } else {
            return false
        }
    }

    public mutating func decode(_ type: Bool.Type) throws -> Bool {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [AnyCodingKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(AnyCodingKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Bool.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [AnyCodingKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: Int.Type) throws -> Int {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [AnyCodingKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(AnyCodingKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Int.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [AnyCodingKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: Int8.Type) throws -> Int8 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [AnyCodingKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(AnyCodingKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Int8.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [AnyCodingKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: Int16.Type) throws -> Int16 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [AnyCodingKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(AnyCodingKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Int16.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [AnyCodingKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: Int32.Type) throws -> Int32 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [AnyCodingKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(AnyCodingKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Int32.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [AnyCodingKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: Int64.Type) throws -> Int64 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [AnyCodingKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(AnyCodingKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Int64.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [AnyCodingKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: UInt.Type) throws -> UInt {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [AnyCodingKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(AnyCodingKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: UInt.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [AnyCodingKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [AnyCodingKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(AnyCodingKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: UInt8.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [AnyCodingKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [AnyCodingKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(AnyCodingKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: UInt16.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [AnyCodingKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [AnyCodingKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(AnyCodingKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: UInt32.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [AnyCodingKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [AnyCodingKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(AnyCodingKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: UInt64.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [AnyCodingKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: Float.Type) throws -> Float {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [AnyCodingKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(AnyCodingKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Float.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [AnyCodingKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: Double.Type) throws -> Double {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [AnyCodingKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(AnyCodingKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: Double.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [AnyCodingKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode(_ type: String.Type) throws -> String {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [AnyCodingKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(AnyCodingKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: String.self) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [AnyCodingKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func decode<T : Decodable>(_ type: T.Type) throws -> T {
        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [AnyCodingKey(index: self.currentIndex)], debugDescription: "Unkeyed container is at end."))
        }

        self.decoder.codingPath.append(AnyCodingKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard let decoded = try self.decoder.unbox(self.container[self.currentIndex], as: type) else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath + [AnyCodingKey(index: self.currentIndex)], debugDescription: "Expected \(type) but found null instead."))
        }

        self.currentIndex += 1
        return decoded
    }

    public mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
        self.decoder.codingPath.append(AnyCodingKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(KeyedDecodingContainer<NestedKey>.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get nested keyed container -- unkeyed container is at end."))
        }

        let value = self.container[self.currentIndex]
        guard !value.isNull else {
            throw DecodingError.valueNotFound(KeyedDecodingContainer<NestedKey>.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get keyed decoding container -- found null value instead."))
        }

        guard let dictionary = try valueToKeyedValues(value, at: self.codingPath) else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: [String : Any].self, reality: value)
        }

        self.currentIndex += 1
        let container = CBORCodingKeyedDecodingContainer<NestedKey>(referencing: self.decoder, wrapping: dictionary)
        return KeyedDecodingContainer(container)
    }

    public mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        self.decoder.codingPath.append(AnyCodingKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get nested keyed container -- unkeyed container is at end."))
        }

        let value = self.container[self.currentIndex]
        guard !value.isNull else {
            throw DecodingError.valueNotFound(UnkeyedDecodingContainer.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get keyed decoding container -- found null value instead."))
        }

        guard let array = try valueToUnkeyedValues(value, at: self.codingPath) else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: [CBOR].self, reality: value)
        }

        self.currentIndex += 1
        return _CBORUnkeyedDecodingContainer(referencing: self.decoder, wrapping: array)
    }

    public mutating func superDecoder() throws -> Decoder {
        self.decoder.codingPath.append(AnyCodingKey(index: self.currentIndex))
        defer { self.decoder.codingPath.removeLast() }

        guard !self.isAtEnd else {
            throw DecodingError.valueNotFound(Decoder.self,
                                              DecodingError.Context(codingPath: self.codingPath,
                                                                    debugDescription: "Cannot get superDecoder() -- unkeyed container is at end."))
        }

        let value = self.container[self.currentIndex]
        self.currentIndex += 1
        return _CBORDecoder(referencing: value, at: self.decoder.codingPath, options: self.decoder.options)
    }
}

extension _CBORDecoder : SingleValueDecodingContainer {
    // MARK: SingleValueDecodingContainer Methods
    private func expectNonNull<T>(_ type: T.Type) throws {
        guard !self.decodeNil() else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected \(type) but found null value instead."))
        }
    }

    public func decodeNil() -> Bool {
        return self.storage.topContainer.isNull
    }

    public func decode(_ type: Bool.Type) throws -> Bool {
        try expectNonNull(Bool.self)
        return try self.unbox(self.storage.topContainer, as: Bool.self)!
    }

    public func decode(_ type: Int.Type) throws -> Int {
        try expectNonNull(Int.self)
        return try self.unbox(self.storage.topContainer, as: Int.self)!
    }

    public func decode(_ type: Int8.Type) throws -> Int8 {
        try expectNonNull(Int8.self)
        return try self.unbox(self.storage.topContainer, as: Int8.self)!
    }

    public func decode(_ type: Int16.Type) throws -> Int16 {
        try expectNonNull(Int16.self)
        return try self.unbox(self.storage.topContainer, as: Int16.self)!
    }

    public func decode(_ type: Int32.Type) throws -> Int32 {
        try expectNonNull(Int32.self)
        return try self.unbox(self.storage.topContainer, as: Int32.self)!
    }

    public func decode(_ type: Int64.Type) throws -> Int64 {
        try expectNonNull(Int64.self)
        return try self.unbox(self.storage.topContainer, as: Int64.self)!
    }

    public func decode(_ type: UInt.Type) throws -> UInt {
        try expectNonNull(UInt.self)
        return try self.unbox(self.storage.topContainer, as: UInt.self)!
    }

    public func decode(_ type: UInt8.Type) throws -> UInt8 {
        try expectNonNull(UInt8.self)
        return try self.unbox(self.storage.topContainer, as: UInt8.self)!
    }

    public func decode(_ type: UInt16.Type) throws -> UInt16 {
        try expectNonNull(UInt16.self)
        return try self.unbox(self.storage.topContainer, as: UInt16.self)!
    }

    public func decode(_ type: UInt32.Type) throws -> UInt32 {
        try expectNonNull(UInt32.self)
        return try self.unbox(self.storage.topContainer, as: UInt32.self)!
    }

    public func decode(_ type: UInt64.Type) throws -> UInt64 {
        try expectNonNull(UInt64.self)
        return try self.unbox(self.storage.topContainer, as: UInt64.self)!
    }

    public func decode(_ type: Float.Type) throws -> Float {
        try expectNonNull(Float.self)
        return try self.unbox(self.storage.topContainer, as: Float.self)!
    }

    public func decode(_ type: Double.Type) throws -> Double {
        try expectNonNull(Double.self)
        return try self.unbox(self.storage.topContainer, as: Double.self)!
    }

    public func decode(_ type: String.Type) throws -> String {
        try expectNonNull(String.self)
        return try self.unbox(self.storage.topContainer, as: String.self)!
    }

    public func decode<T : Decodable>(_ type: T.Type) throws -> T {
        try expectNonNull(type)
        return try self.unbox(self.storage.topContainer, as: type)!
    }
}

// MARK: - Concrete Value Representations
extension _CBORDecoder {
    /// Returns the given value unboxed from a container.
    fileprivate func unbox(_ value: CBOR, as type: Bool.Type) throws -> Bool? {
        switch value {
        case .boolean(let value): return value
        case .null: return nil
        case let cbor:
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: cbor)
        }
    }

    fileprivate func overflow(_ type: Any.Type, value: Any) -> Error {
        let context = DecodingError.Context(codingPath: self.codingPath, debugDescription: "\(value) overflows \(type)")
        return DecodingError.typeMismatch(type, context)
    }

    fileprivate func coerce<T, F>(_ from: F) throws -> T where T : BinaryInteger, F : BinaryInteger {
        guard let result = T(exactly: from) else {
            throw overflow(T.self, value: from)
        }
        return result
    }

    fileprivate func coerce<T, F>(_ from: F) throws -> T where T : BinaryInteger, F : BinaryFloatingPoint {
        guard let result = T(exactly: from) else {
            throw overflow(T.self, value: from)
        }
        return result
    }

    fileprivate func coerce<T, F>(_ from: F) throws -> T where T : BinaryFloatingPoint, F : BinaryInteger {
        guard let result = T(exactly: from) else {
            throw overflow(T.self, value: from)
        }
        return result
    }

    fileprivate func coerce<T, F>(_ from: F) throws -> T where T : BinaryFloatingPoint, F : BinaryFloatingPoint {
        guard let result = T(exactly: from) else {
            throw overflow(T.self, value: from)
        }
        return result
    }

    fileprivate func unbox(_ value: CBOR, as type: Int.Type) throws -> Int? {
        switch value.untagged {
        case .double(let dbl): return try coerce(dbl)
        case .float(let flt): return try coerce(flt)
        case .unsignedInt(let uint): return try coerce(uint)
        case .negativeInt(let nint): return try -1 - coerce(nint)
        case .null: return nil
        case let cbor:
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: cbor)
        }
    }

    fileprivate func unbox(_ value: CBOR, as type: Int8.Type) throws -> Int8? {
        switch value.untagged {
        case .double(let dbl): return try coerce(dbl)
        case .float(let flt): return try coerce(flt)
        case .unsignedInt(let uint): return try coerce(uint)
        case .negativeInt(let nint): return try -1 - coerce(nint)
        case .null: return nil
        case let cbor:
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: cbor)
        }
    }

    fileprivate func unbox(_ value: CBOR, as type: Int16.Type) throws -> Int16? {
        switch value.untagged {
        case .double(let dbl): return try coerce(dbl)
        case .float(let flt): return try coerce(flt)
        case .unsignedInt(let uint): return try coerce(uint)
        case .negativeInt(let nint): return try -1 - coerce(nint)
        case .null: return nil
        case let cbor:
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: cbor)
        }
    }

    fileprivate func unbox(_ value: CBOR, as type: Int32.Type) throws -> Int32? {
        switch value.untagged {
        case .double(let dbl): return try coerce(dbl)
        case .float(let flt): return try coerce(flt)
        case .unsignedInt(let uint): return try coerce(uint)
        case .negativeInt(let nint): return try -1 - coerce(nint)
        case .null: return nil
        case let cbor:
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: cbor)
        }
    }

    fileprivate func unbox(_ value: CBOR, as type: Int64.Type) throws -> Int64? {
        switch value.untagged {
        case .double(let dbl): return try coerce(dbl)
        case .float(let flt): return try coerce(flt)
        case .unsignedInt(let uint): return try coerce(uint)
        case .negativeInt(let nint): return try -1 - coerce(nint)
        case .null: return nil
        case let cbor:
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: cbor)
        }
    }

    fileprivate func unbox(_ value: CBOR, as type: UInt.Type) throws -> UInt? {
        switch value.untagged {
        case .double(let dbl): return try coerce(dbl)
        case .float(let flt): return try coerce(flt)
        case .unsignedInt(let uint): return try coerce(uint)
        case .null: return nil
        case let cbor:
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: cbor)
        }
    }

    fileprivate func unbox(_ value: CBOR, as type: UInt8.Type) throws -> UInt8? {
        switch value.untagged {
        case .double(let dbl): return try coerce(dbl)
        case .float(let flt): return try coerce(flt)
        case .unsignedInt(let uint): return try coerce(uint)
        case .null: return nil
        case let cbor:
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: cbor)
        }
    }

    fileprivate func unbox(_ value: CBOR, as type: UInt16.Type) throws -> UInt16? {
        switch value.untagged {
        case .double(let dbl): return try coerce(dbl)
        case .float(let flt): return try coerce(flt)
        case .unsignedInt(let uint): return try coerce(uint)
        case .null: return nil
        case let cbor:
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: cbor)
        }
    }

    fileprivate func unbox(_ value: CBOR, as type: UInt32.Type) throws -> UInt32? {
        switch value.untagged {
        case .double(let dbl): return try coerce(dbl)
        case .float(let flt): return try coerce(flt)
        case .unsignedInt(let uint): return try coerce(uint)
        case .null: return nil
        case let cbor:
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: cbor)
        }
    }

    fileprivate func unbox(_ value: CBOR, as type: UInt64.Type) throws -> UInt64? {
        switch value.untagged {
        case .double(let dbl): return try coerce(dbl)
        case .float(let flt): return try coerce(flt)
        case .unsignedInt(let uint): return uint
        case .null: return nil
        case let cbor:
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: cbor)
        }
    }

    fileprivate func unbox(_ value: CBOR, as type: Float.Type) throws -> Float? {
        switch value.untagged {
        case .double(let dbl): return try coerce(dbl)
        case .float(let flt): return flt
        case .unsignedInt(let uint): return try coerce(uint)
        case .negativeInt(let nint): return try -1 - coerce(nint)
        case .null: return nil
        case let cbor:
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: cbor)
        }
    }

    fileprivate func unbox(_ value: CBOR, as type: Double.Type) throws -> Double? {
        switch value.untagged {
        case .double(let dbl): return dbl
        case .float(let flt): return try coerce(flt)
        case .unsignedInt(let uint): return try coerce(uint)
        case .negativeInt(let nint): return try -1 - coerce(nint)
        case .null: return nil
        case let cbor:
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: cbor)
        }
    }

    fileprivate func unbox(_ value: CBOR, as type: String.Type) throws -> String? {
        switch value.untagged {
        case .null: return nil
        case .utf8String(let string):
            return string
        case let cbor:
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: cbor)
        }
    }

    fileprivate func unbox(_ value: CBOR, as type: UUID.Type) throws -> UUID? {
        switch value {
        case .null: return nil
        case .utf8String(let string):
            return UUID(uuidString: string)
        case .byteString(let data):
            var uuid = UUID_NULL
            withUnsafeMutableBytes(of: &uuid) { ptr in
                _ = data.copyBytes(to: ptr)
            }
            return UUID(uuid: uuid)
        case .tagged(.uuid, let tagged):
            guard case .byteString(let data) = tagged else {
                throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: tagged)
            }
            var uuid = UUID_NULL
            withUnsafeMutableBytes(of: &uuid) { ptr in
                _ = data.copyBytes(to: ptr)
            }
            return UUID(uuid: uuid)
        case .tagged(_, let tagged):
            return try unbox(tagged, as: UUID.self)
        case let cbor:
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: cbor)
        }
    }

    fileprivate func unbox(_ value: CBOR, as type: Date.Type) throws -> Date? {
        switch value {
        case .null: return nil
        case .utf8String(let string):
            return _iso8601Formatter.date(from: string)
        case .double(let dbl):
            return Date(timeIntervalSince1970: dbl)
        case .float(let float):
            return Date(timeIntervalSince1970: Double(float))
        case .half(let half):
            return Date(timeIntervalSince1970: Double(half.floatValue))
        case .unsignedInt(let uint):
            return Date(timeIntervalSince1970: Double(uint))
        case .negativeInt(let nint):
            return Date(timeIntervalSince1970: Double(-1 - Int(nint)))
        case .tagged(.iso8601DateTime, let tagged):
            guard case .utf8String(let string) = tagged else {
                throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: tagged)
            }
            guard let date = _iso8601Formatter.date(from: string) else {
                throw DecodingError.dataCorruptedError(in: self, debugDescription: "Invalid ISO8601 Date/Time")
            }
            return date
        case .tagged(.epochDateTime, let tagged):
            guard tagged.isNumber else {
                throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: tagged)
            }
            guard let secondsDec = tagged.numberValue, let seconds = Double(secondsDec.description) else {
                throw DecodingError.dataCorruptedError(in: self, debugDescription: "Invalid ISO8601 Date/Time")
            }
            return Date(timeIntervalSince1970: seconds)
        case let cbor:
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: cbor)
        }
    }

    fileprivate func unbox(_ value: CBOR, as type: Data.Type) throws -> Data? {
        switch value.untagged {
        case .null: return nil
        case .byteString(let data): return data
        case let cbor:
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: cbor)
        }
    }

    fileprivate func unbox(_ value: CBOR, as type: Decimal.Type) throws -> Decimal? {
        guard !value.isNull else { return nil }
        let doubleValue = try self.unbox(value, as: Double.self)!
        return Decimal(doubleValue)
    }

    fileprivate func unbox<T>(_ value: CBOR, as type: _CBORStringDictionaryDecodableMarker.Type) throws -> T? {
        guard !value.isNull else { return nil }

        var result = [String : Any]()
        guard case let .map(dict) = value else {
            throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
        }
        let elementType = type.elementType
        for (key, value) in dict {
            guard case let .utf8String(key) = key else {
                throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
            }
            self.codingPath.append(AnyCodingKey(stringValue: key, intValue: nil))
            defer { self.codingPath.removeLast() }

            result[key] = try unbox_(value, as: elementType)
        }

        return result as? T
    }

    fileprivate func unbox<T : Decodable>(_ value: CBOR, as type: T.Type) throws -> T? {
        return try unbox_(value, as: type) as? T
    }

    fileprivate func unbox_(_ value: CBOR, as type: Decodable.Type) throws -> Any? {
        if type == Date.self || type == NSDate.self {
            return try self.unbox(value, as: Date.self)
        } else if type == Data.self || type == NSData.self {
            return try self.unbox(value, as: Data.self)
        } else if type == UUID.self || type == CFUUID.self {
            return try self.unbox(value, as: UUID.self)
        } else if type == URL.self || type == NSURL.self {
            guard let urlString = try self.unbox(value, as: String.self) else {
                return nil
            }

            guard let url = URL(string: urlString) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath,
                                                                        debugDescription: "Invalid URL string."))
            }

            return url
        } else if type == Decimal.self || type == NSDecimalNumber.self {
            return try self.unbox(value, as: Decimal.self)
        } else if let stringKeyedDictType = type as? _CBORStringDictionaryDecodableMarker.Type {
            return try self.unbox(value, as: stringKeyedDictType)
        } else {
            self.storage.push(container: value)
            defer { self.storage.popContainer() }
            return try type.init(from: self)
        }
    }
}


extension CBORDecoder.KeyDecodingStrategy {

    fileprivate static func _convertFromSnakeCase(_ stringKey: String) -> String {
        guard !stringKey.isEmpty else { return stringKey }

        // Find the first non-underscore character
        guard let firstNonUnderscore = stringKey.firstIndex(where: { $0 != "_" }) else {
            // Reached the end without finding an _
            return stringKey
        }

        // Find the last non-underscore character
        var lastNonUnderscore = stringKey.index(before: stringKey.endIndex)
        while lastNonUnderscore > firstNonUnderscore && stringKey[lastNonUnderscore] == "_" {
            stringKey.formIndex(before: &lastNonUnderscore);
        }

        let keyRange = firstNonUnderscore...lastNonUnderscore
        let leadingUnderscoreRange = stringKey.startIndex..<firstNonUnderscore
        let trailingUnderscoreRange = stringKey.index(after: lastNonUnderscore)..<stringKey.endIndex

        let components = stringKey[keyRange].split(separator: "_")
        let joinedString : String
        if components.count == 1 {
            // No underscores in key, leave the word as is - maybe already camel cased
            joinedString = String(stringKey[keyRange])
        } else {
            joinedString = ([components[0].lowercased()] + components[1...].map { $0.capitalized }).joined()
        }

        // Do a cheap isEmpty check before creating and appending potentially empty strings
        let result : String
        if (leadingUnderscoreRange.isEmpty && trailingUnderscoreRange.isEmpty) {
            result = joinedString
        } else if (!leadingUnderscoreRange.isEmpty && !trailingUnderscoreRange.isEmpty) {
            // Both leading and trailing underscores
            result = String(stringKey[leadingUnderscoreRange]) + joinedString + String(stringKey[trailingUnderscoreRange])
        } else if (!leadingUnderscoreRange.isEmpty) {
            // Just leading
            result = String(stringKey[leadingUnderscoreRange]) + joinedString
        } else {
            // Just trailing
            result = joinedString + String(stringKey[trailingUnderscoreRange])
        }
        return result
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

func valueToUnkeyedValues(_ value: CBOR, at: [CodingKey]) throws -> [CBOR]? {
    guard case .array(let array) = value else { return nil }
    return array
}

func valueToKeyedValues(_ value: CBOR, at codingPath: [CodingKey]) throws -> [String: CBOR]? {
    guard case .map(let map) = value else { return nil }
    return try mapToKeyedValues(map, at: codingPath)
}

func mapToKeyedValues(_ map: [CBOR: CBOR], at: [CodingKey]) throws -> [String: CBOR] {
    return try Dictionary(
        map.compactMap { key, value in
            switch key.untagged {
            case .utf8String(let str): return (str, value)
            case .unsignedInt(let uint): return (String(uint), value)
            case .negativeInt(let nint): return (String(-1 - Int(nint)), value)
            default: return nil
            }
        },
        uniquingKeysWith: { _, _ in
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: at, debugDescription: "Map contains duplicate keys"))
        }
    )
}

/// A marker protocol used to determine whether a value is a `String`-keyed `Dictionary`
/// containing `Decodable` values (in which case it should be exempt from key conversion strategies).
///
/// The marker protocol also provides access to the type of the `Decodable` values,
/// which is needed for the implementation of the key conversion strategy exemption.
///
fileprivate protocol _CBORStringDictionaryDecodableMarker {
  static var elementType: Decodable.Type { get }
}

extension Dictionary : _CBORStringDictionaryDecodableMarker where Key == String, Value: Decodable {
  static var elementType: Decodable.Type { return Value.self }
}
