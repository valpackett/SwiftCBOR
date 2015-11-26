final class Util {

	// https://stackoverflow.com/questions/24465475/how-can-i-create-a-string-from-utf8-in-swift
	static func decodeUtf8(bytes: ArraySlice<UInt8>) throws -> String {
		var result = ""
		var decoder = UTF8()
		var generator = bytes.generate()
		var finished = false
		repeat {
			let decodingResult = decoder.decode(&generator)
			switch decodingResult {
			case .Result(let char):
				result.append(char)
			case .EmptyInput:
				finished = true
			case .Error:
				throw CBORError.IncorrectUTF8String
			}
		} while (!finished)
		return result
	}

	static func djb2Hash(array: [Int]) -> Int {
		return array.reduce(5381, combine: { hash, elem in ((hash << 5) &+ hash) &+ Int(elem) })
	}

}