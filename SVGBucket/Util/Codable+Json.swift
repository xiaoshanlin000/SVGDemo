import Foundation

// MARK: - Encodable 扩展

public extension Encodable {
    func toJsonString() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(self)
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            printWithTime("Error encoding to JSON string: \(error)")
            return ""
        }
    }

    func toJsonData() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            return try encoder.encode(self)
        } catch {
            printWithTime("Error encoding to JSON data: \(error)")
            return nil
        }
    }

    // 保存到文件
    func saveToFile(at url: URL) -> Bool {
        guard let data = toJsonData() else { return false }
        do {
            // 确保目录存在
            let directory = url.deletingLastPathComponent()
            if !FileManager.default.fileExists(atPath: directory.path) {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            }
            try data.write(to: url)
            return true
        } catch {
            printWithTime("Error saving to file: \(error)")
            return false
        }
    }
}

// MARK: - Decodable 扩展

public extension Decodable {
    static func fromJson(_ json: Data) -> Self? {
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(Self.self, from: json)
        } catch {
            printWithTime("Error decoding from JSON data: \(error)")
            return nil
        }
    }

    static func fromJsonString(_ json: String) -> Self? {
        guard let data = json.data(using: .utf8) else { return nil }
        return fromJson(data)
    }

    static func loadFromFile(at url: URL) -> Self? {
        do {
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            return fromJson(data)
        } catch {
            printWithTime("Error loading from file: \(error)")
            return nil
        }
    }
}

// MARK: - 全局函数

public func fromJson<T: Decodable>(json: Data, type: T.Type) -> T? {
    type.fromJson(json)
}

public func fromJsonString<T: Decodable>(json: String, type: T.Type) -> T? {
    type.fromJsonString(json)
}
