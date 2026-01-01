import Foundation

public extension Thread {
    var threadName: String {
        if isMainThread {
            return "main"
        } else if let name = name, !name.isEmpty {
            return name
        } else {
            // 从description中提取更有意义的信息
            let description = self.description
            if let range = description.range(of: "number = \\d+", options: .regularExpression) {
                return String(description[range])
            }
            return "unnamed"
        }
    }

    var queueName: String {
        // 1. 首先尝试获取当前dispatch queue的名称
        if let dispatchQueueName = String(validatingUTF8: __dispatch_queue_get_label(nil)),
           !dispatchQueueName.isEmpty
        {
            return dispatchQueueName
        }

        // 2. 检查OperationQueue
        if let operationQueue = OperationQueue.current {
            if let name = operationQueue.name, !name.isEmpty {
                return name
            }
            if let underlyingQueueName = operationQueue.underlyingQueue?.label,
               !underlyingQueueName.isEmpty
            {
                return underlyingQueueName
            }
        }

        // 3. 对于主线程，返回主队列名称
        if isMainThread {
            return "com.apple.main-thread"
        }

        // 4. 最后回退选项
        return "unknown"
    }
}
