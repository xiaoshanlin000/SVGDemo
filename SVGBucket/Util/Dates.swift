import Foundation

public func currentTimeMillis() -> Int64 {
    Date().timeMillis()
}

public extension Date {
    func timeMillis() -> Int64 {
        Int64(timeIntervalSince1970 * 1000)
    }

    func format(format: String = "yyyy-MM-dd HH:mm:ss") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}

// MARK: - 日期相关

public extension String {
    /// 将日期字符串转换为 Date 对象
    func toDate(format: String = "yyyy-MM-dd HH:mm:ss") -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.current
        return dateFormatter.date(from: self)
    }

    /// 将日期字符串转换为 Date 对象（支持多种格式）
    func toDate(with formats: [String]) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.current

        for format in formats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: self) {
                return date
            }
        }
        return nil
    }

    func toTimeMillis(format: String = "yyyy-MM-dd HH:mm:ss") -> Int64 {
        guard let date = toDate(format: format) else { return 0 }
        return date.timeMillis()
    }
}

public extension Int64 {
    func toDate() -> Date {
        Date(timeIntervalSince1970: Double(self) / 1000.0)
    }

    func toDateString(format: String = "yyyy-MM-dd HH:mm:ss") -> String {
        toDate().format(format: format)
    }
}
