func cborIntegerArgument<T: FixedWidthInteger>(_ value: T) -> UInt64 {
    if value < 0 {
        return UInt64(bitPattern: ~Int64(truncatingIfNeeded: value))
    }
    return UInt64(truncatingIfNeeded: value)
}

func cborArgumentEncodedLength(_ value: UInt64) -> Int {
    if value < 24 { return 1 }
    if value <= UInt64(UInt8.max) { return 2 }
    if value <= UInt64(UInt16.max) { return 3 }
    if value <= UInt64(UInt32.max) { return 5 }
    return 9
}

func cborIntegerEncodedLength<T: FixedWidthInteger>(_ value: T) -> Int {
    if T.self == UInt16.self { return 3 }
    if T.self == UInt32.self { return 5 }
    if T.self == UInt64.self { return 9 }
    return cborArgumentEncodedLength(cborIntegerArgument(value))
}

func writeCBORArgument(
    _ value: UInt64,
    major: UInt8,
    to buffer: UnsafeMutableBufferPointer<UInt8>,
    at offset: inout Int
) {
    if value < 24 {
        buffer[offset] = major | UInt8(value)
        offset += 1
        return
    }

    let width: Int
    let marker: UInt8
    if value <= UInt64(UInt8.max) {
        width = 1
        marker = 24
    } else if value <= UInt64(UInt16.max) {
        width = 2
        marker = 25
    } else if value <= UInt64(UInt32.max) {
        width = 4
        marker = 26
    } else {
        width = 8
        marker = 27
    }

    buffer[offset] = major | marker
    offset += 1
    for shift in stride(from: (width - 1) * 8, through: 0, by: -8) {
        buffer[offset] = UInt8(truncatingIfNeeded: value >> shift)
        offset += 1
    }
}

func writeCBORInteger<T: FixedWidthInteger>(
    _ value: T,
    to buffer: UnsafeMutableBufferPointer<UInt8>,
    at offset: inout Int
) {
    let major: UInt8 = value < 0 ? 0x20 : 0x00

    if T.self == UInt16.self || T.self == UInt32.self || T.self == UInt64.self {
        let marker: UInt8
        if T.self == UInt16.self { marker = 0x19 }
        else if T.self == UInt32.self { marker = 0x1a }
        else { marker = 0x1b }

        let byteCount = MemoryLayout<T>.size
        buffer[offset] = major | marker
        offset += 1
        for shift in stride(from: (byteCount - 1) * 8, through: 0, by: -8) {
            buffer[offset] = UInt8(truncatingIfNeeded: UInt64(truncatingIfNeeded: value) >> shift)
            offset += 1
        }
        return
    }

    writeCBORArgument(cborIntegerArgument(value), major: major, to: buffer, at: &offset)
}

func encodeCBORIntegerArray<T: FixedWidthInteger>(_ array: [T]) -> [UInt8] {
    let length = cborArgumentEncodedLength(UInt64(array.count))
        + array.reduce(0) { $0 + cborIntegerEncodedLength($1) }
    var bytes = [UInt8](repeating: 0, count: length)
    bytes.withUnsafeMutableBufferPointer { buffer in
        var offset = 0
        writeCBORArgument(UInt64(array.count), major: 0x80, to: buffer, at: &offset)
        for value in array {
            writeCBORInteger(value, to: buffer, at: &offset)
        }
        assert(offset == buffer.count)
    }
    return bytes
}

func appendCBORArray<T: CBOREncodable>(
    _ array: [T],
    into output: inout [UInt8],
    options: CBOROptions
) {
    if let array = array as? [Int] {
        output.append(contentsOf: encodeCBORIntegerArray(array))
    } else if let array = array as? [Int8] {
        output.append(contentsOf: encodeCBORIntegerArray(array))
    } else if let array = array as? [Int16] {
        output.append(contentsOf: encodeCBORIntegerArray(array))
    } else if let array = array as? [Int32] {
        output.append(contentsOf: encodeCBORIntegerArray(array))
    } else if let array = array as? [Int64] {
        output.append(contentsOf: encodeCBORIntegerArray(array))
    } else if let array = array as? [UInt] {
        output.append(contentsOf: encodeCBORIntegerArray(array))
    } else if let array = array as? [UInt8] {
        output.append(contentsOf: encodeCBORIntegerArray(array))
    } else if let array = array as? [UInt16] {
        output.append(contentsOf: encodeCBORIntegerArray(array))
    } else if let array = array as? [UInt32] {
        output.append(contentsOf: encodeCBORIntegerArray(array))
    } else if let array = array as? [UInt64] {
        output.append(contentsOf: encodeCBORIntegerArray(array))
    } else {
        appendCBORArgument(UInt64(array.count), major: 0x80, to: &output)
        for element in array {
            element.encode(into: &output, options: options)
        }
    }
}
