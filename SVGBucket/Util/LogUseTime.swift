
import Foundation

public class LogUseTime {
    private var startTime: UInt64
    private let identifier: String?

    /// 时间单位枚举
    public enum TimeUnit {
        case nanoseconds
        case microseconds
        case milliseconds
        case seconds

        var description: String {
            switch self {
            case .nanoseconds: return "ns"
            case .microseconds: return "μs"
            case .milliseconds: return "ms"
            case .seconds: return "s"
            }
        }
    }

    /// 初始化计时器
    /// - Parameters:
    ///   - startTime: 开始时间，默认为当前时间（纳秒）
    ///   - identifier: 标识符，用于区分不同的计时器
    public init(startTime: UInt64 = currentTimeNanos(), identifier: String? = nil) {
        self.startTime = startTime
        self.identifier = identifier
    }

    /// 重置开始时间
    public func reset() {
        startTime = currentTimeNanos()
    }

    /// 获取经过的时间（纳秒）
    public var elapsedTimeNanos: UInt64 {
        return currentTimeNanos() - startTime
    }

    /// 获取经过的时间（微秒）
    public var elapsedTimeMicros: Double {
        return Double(elapsedTimeNanos) / 1000.0
    }

    /// 获取经过的时间（毫秒）
    public var elapsedTimeMillis: Double {
        return Double(elapsedTimeNanos) / 1_000_000.0
    }

    /// 获取经过的时间（秒）
    public var elapsedTimeSeconds: Double {
        return Double(elapsedTimeNanos) / 1_000_000_000.0
    }

    /// 自动选择合适的单位打印
    public func print(_ message: String) {
        let logMessage = formatLogMessageAuto(message)
        printWithTime(logMessage)
    }

    /// 指定单位打印
    public func print(_ message: String, unit: TimeUnit) {
        let logMessage = formatLogMessage(message, unit: unit)
        printWithTime(logMessage)
    }

    /// 静默测量并自动选择单位
    @discardableResult
    public func measure(_ message: String) -> (time: Double, unit: TimeUnit) {
        let (formattedMessage, time, unit) = getFormattedMessageWithAutoUnit(message)
        printWithTime(formattedMessage)
        return (time, unit)
    }

    /// 静默测量并指定单位
    @discardableResult
    public func measure(_ message: String, unit: TimeUnit) -> Double {
        let time = getTimeInUnit(unit)
        let logMessage = formatLogMessage(message, unit: unit)
        printWithTime(logMessage)
        return time
    }

    /// 获取所有单位的测量结果
    public func measureAllUnits(_ message: String) -> (nanos: UInt64, micros: Double, millis: Double, seconds: Double) {
        let nanos = elapsedTimeNanos
        let micros = elapsedTimeMicros
        let millis = elapsedTimeMillis
        let seconds = elapsedTimeSeconds

        let logMessage = formatLogMessageAllUnits(message)
        printWithTime(logMessage)

        return (nanos, micros, millis, seconds)
    }

    // MARK: - Private Methods

    private func getFormattedMessageWithAutoUnit(_ message: String) -> (String, Double, TimeUnit) {
        let nanos = elapsedTimeNanos

        if nanos < 1000 {
            // 小于1微秒，用纳秒
            return (formatLogMessage(message, time: Double(nanos), unit: .nanoseconds), Double(nanos), .nanoseconds)
        } else if nanos < 1_000_000 {
            // 小于1毫秒，用微秒
            return (formatLogMessage(message, time: Double(nanos) / 1000.0, unit: .microseconds), Double(nanos) / 1000.0, .microseconds)
        } else if nanos < 1_000_000_000 {
            // 小于1秒，用毫秒
            return (formatLogMessage(message, time: Double(nanos) / 1_000_000.0, unit: .milliseconds), Double(nanos) / 1_000_000.0, .milliseconds)
        } else {
            // 大于等于1秒，用秒
            return (formatLogMessage(message, time: Double(nanos) / 1_000_000_000.0, unit: .seconds), Double(nanos) / 1_000_000_000.0, .seconds)
        }
    }

    private func formatLogMessageAuto(_ message: String) -> String {
        let (formattedMessage, _, _) = getFormattedMessageWithAutoUnit(message)
        return formattedMessage
    }

    private func formatLogMessage(_ message: String, unit: TimeUnit) -> String {
        let time = getTimeInUnit(unit)
        return formatLogMessage(message, time: time, unit: unit)
    }

    private func formatLogMessage(_ message: String, time: Double, unit: TimeUnit) -> String {
        var components = [String]()

        if let identifier = identifier {
            components.append("[\(identifier)]")
        }

        components.append(message)

        // 根据时间值选择合适的格式化方式
        let timeString: String
        if unit == .nanoseconds {
            timeString = "\(Int64(time))"
        } else if time < 0.001 {
            timeString = String(format: "%.6f", time)
        } else if time < 1.0 {
            timeString = String(format: "%.3f", time)
        } else if time < 10.0 {
            timeString = String(format: "%.2f", time)
        } else {
            timeString = String(format: "%.1f", time)
        }

        components.append("-> \(timeString) \(unit.description)")

        return components.joined(separator: " ")
    }

    private func formatLogMessageAllUnits(_ message: String) -> String {
        var components = [String]()

        if let identifier = identifier {
            components.append("[\(identifier)]")
        }

        components.append(message)
        components.append("->")
        components.append("\(elapsedTimeNanos) ns")
        components.append("(\(String(format: "%.2f", elapsedTimeMicros)) μs)")
        components.append("(\(String(format: "%.3f", elapsedTimeMillis)) ms)")
        components.append("(\(String(format: "%.6f", elapsedTimeSeconds)) s)")

        return components.joined(separator: " ")
    }

    private func getTimeInUnit(_ unit: TimeUnit) -> Double {
        switch unit {
        case .nanoseconds:
            return Double(elapsedTimeNanos)
        case .microseconds:
            return elapsedTimeMicros
        case .milliseconds:
            return elapsedTimeMillis
        case .seconds:
            return elapsedTimeSeconds
        }
    }
}

// MARK: - 时间获取函数

/// 获取当前时间的纳秒数
public func currentTimeNanos() -> UInt64 {
    return DispatchTime.now().uptimeNanoseconds
}

// MARK: - 使用示例扩展

public extension LogUseTime {
    /// 快速测量代码块执行时间（自动选择单位）
    @discardableResult
    static func measure<T>(_ identifier: String? = nil, _ message: String = "Execution time", _ block: () throws -> T) rethrows -> T {
        let timer = LogUseTime(identifier: identifier)
        let result = try block()
        timer.print(message)
        return result
    }

    /// 快速测量代码块执行时间（指定单位）
    @discardableResult
    static func measure<T>(unit: TimeUnit, identifier: String? = nil, _ message: String = "Execution time", _ block: () throws -> T) rethrows -> T {
        let timer = LogUseTime(identifier: identifier)
        let result = try block()
        timer.print(message, unit: unit)
        return result
    }
}

// MARK: - 便捷方法

public extension LogUseTime {
    /// 快速测量代码块执行时间
    static func measure<T>(_ identifier: String? = nil, _ operation: () throws -> T) rethrows -> T {
        let timer = LogUseTime(identifier: identifier)
        defer {
            timer.print("use")
        }
        return try operation()
    }

    /// 快速测量异步代码块执行时间
    static func measure<T>(_ identifier: String? = nil, _ operation: () async throws -> T) async rethrows -> T {
        let timer = LogUseTime(identifier: identifier)
        defer {
            timer.print("use")
        }
        return try await operation()
    }
}
