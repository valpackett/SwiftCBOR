final class Util {

	// https://stackoverflow.com/questions/24465475/how-can-i-create-a-string-from-utf8-in-swift
	static func decodeUtf8(_ bytes: ArraySlice<UInt8>) throws -> String {
		var result = ""
		var decoder = UTF8()
		var generator = bytes.makeIterator()
		var finished = false
		repeat {
			let decodingResult = decoder.decode(&generator)
			switch decodingResult {
			case .scalarValue(let char):
				result.append(String(char))
			case .emptyInput:
				finished = true
			case .error:
				throw CBORError.incorrectUTF8String
			}
		} while (!finished)
		return result
	}

	static func djb2Hash(_ array: [Int]) -> Int {
		return array.reduce(5381, { hash, elem in ((hash << 5) &+ hash) &+ Int(elem) })
	}

}
