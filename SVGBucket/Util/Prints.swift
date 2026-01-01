
import Foundation
import UIKit

// 提取公共逻辑到私有函数
private func _printWithTime(_ items: [Any],
                            separator: String = " ",
                            terminator: String = "\n")
{
    let time = Date().format(format: "yyyy-MM-dd HH:mm:ss.SSS")
    let threadInfo = Thread.current.queueName

    // 优化字符串转换逻辑
    var message = ""
    for item in items {
        if let stringItem = item as? String {
            message.append(separator)
            message.append(stringItem)
        }
        // 如果是 Encodable 对象但不是基础数据类型，转换为 JSON 字符串
        else if let code = item as? Encodable,
                !_isBasicType(item)
        {
            message.append(terminator)
            message.append(code.toJsonString())
        } else {
            // 其他类型直接转换为字符串
            message.append(separator)
            message.append(String(describing: item))
        }
    }
    print(time, threadInfo, message, separator: separator, terminator: terminator)
}

// 检查是否为不需要转JSON的基础数据类型
private func _isBasicType(_ item: Any) -> Bool {
    return item is Int || item is Int8 || item is Int16 || item is Int32 || item is Int64 ||
        item is UInt || item is UInt8 || item is UInt16 || item is UInt32 || item is UInt64 ||
        item is Double || item is Float || item is Float32 || item is Float64 ||
        item is Bool || item is String || item is Character || item is Data ||
        item is Date || item is URL
}

public func printWithTime(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    // 如果传入的是单个数组，直接使用该数组
    if items.count == 1, let array = items.first as? [Any] {
        _printWithTime(array, separator: separator, terminator: terminator)
    } else {
        _printWithTime(items, separator: separator, terminator: terminator)
    }
}
