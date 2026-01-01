import UIKit

// MARK: - Storyboard 管理器

public enum Storyboard {
    case main
    case custom(String)

    var name: String {
        switch self {
        case .main:
            return "Main"
        case let .custom(storyboardName):
            return storyboardName
        }
    }
}

// MARK: - Storyboard 扩展

public extension Storyboard {
    /// 获取 Storyboard 实例
    var instance: UIStoryboard {
        return UIStoryboard(name: name, bundle: Bundle.main)
    }

    // MARK: - 通过 Storyboard ID 获取

    /// 通过 Storyboard ID 获取 ViewController（类型安全）
    func instantiateViewController<T: UIViewController>(withIdentifier identifier: String) -> T {
        guard let viewController = instance.instantiateViewController(withIdentifier: identifier) as? T else {
            fatalError("❌ Storyboard 错误: 无法在 \(name).storyboard 中找到 ID 为 '\(identifier)' 的 \(T.self) 类型")
        }
        return viewController
    }

    /// 通过类名获取 ViewController（自动使用类名作为ID）
    func instantiateViewController<T: UIViewController>(_ type: T.Type) -> T {
        let identifier = String(describing: type)
        return instantiateViewController(withIdentifier: identifier)
    }

    // MARK: - 通过 Initial ViewController 获取

    /// 获取 Initial ViewController
    func instantiateInitialViewController<T: UIViewController>() -> T {
        guard let viewController = instance.instantiateInitialViewController() as? T else {
            fatalError("❌ Storyboard 错误: \(name).storyboard 的 Initial ViewController 不是 \(T.self) 类型")
        }
        return viewController
    }

    /// 获取 Initial NavigationController
    func instantiateInitialNavigationController() -> UINavigationController {
        guard let navigationController = instance.instantiateInitialViewController() as? UINavigationController else {
            fatalError("❌ Storyboard 错误: \(name).storyboard 的 Initial ViewController 不是 UINavigationController")
        }
        return navigationController
    }

    /// 获取 Initial TabBarController
    func instantiateInitialTabBarController() -> UITabBarController {
        guard let tabBarController = instance.instantiateInitialViewController() as? UITabBarController else {
            fatalError("❌ Storyboard 错误: \(name).storyboard 的 Initial ViewController 不是 UITabBarController")
        }
        return tabBarController
    }
}

// MARK: - UIStoryboard 便捷扩展

public extension UIStoryboard {
    // MARK: - 通过 Storyboard ID 获取（默认 Main）

    /// 从 Storyboard 实例化 ViewController（默认 Main）
    static func instantiateViewController<T: UIViewController>(
        _ type: T.Type,
        from storyboard: Storyboard = .main
    ) -> T {
        return storyboard.instantiateViewController(type)
    }

    /// 从 Storyboard 实例化 ViewController（指定 Storyboard ID）
    static func instantiateViewController<T: UIViewController>(
        withIdentifier identifier: String,
        from storyboard: Storyboard = .main
    ) -> T {
        return storyboard.instantiateViewController(withIdentifier: identifier)
    }

    // MARK: - 通过 Initial ViewController 获取（默认 Main）

    /// 从 Storyboard 获取 Initial ViewController（默认 Main）
    static func instantiateInitialViewController<T: UIViewController>(
        from storyboard: Storyboard = .main
    ) -> T {
        return storyboard.instantiateInitialViewController()
    }

    /// 从 Storyboard 获取 Initial NavigationController（默认 Main）
    static func instantiateInitialNavigationController(
        from storyboard: Storyboard = .main
    ) -> UINavigationController {
        return storyboard.instantiateInitialNavigationController()
    }

    /// 从 Storyboard 获取 Initial TabBarController（默认 Main）
    static func instantiateInitialTabBarController(
        from storyboard: Storyboard = .main
    ) -> UITabBarController {
        return storyboard.instantiateInitialTabBarController()
    }
}

// MARK: - UIViewController 便捷扩展

public extension UIViewController {
    // MARK: - 通过 Storyboard ID 获取

    /// 从 Storyboard 加载 ViewController（使用类名作为ID）
    /// 避免与系统方法冲突，使用 loadFromStoryboard 作为方法名
    static func loadFromStoryboard(from storyboard: Storyboard = .main) -> Self {
        return UIStoryboard.instantiateViewController(self, from: storyboard)
    }

    /// 从 Storyboard 加载 ViewController（指定 Storyboard ID）
    static func loadFromStoryboard(
        withIdentifier identifier: String,
        from storyboard: Storyboard = .main
    ) -> Self {
        return UIStoryboard.instantiateViewController(withIdentifier: identifier, from: storyboard)
    }

    // MARK: - 通过 Initial ViewController 获取

    /// 从 Storyboard 加载 Initial ViewController
    static func loadInitialFromStoryboard(from storyboard: Storyboard = .main) -> Self {
        return UIStoryboard.instantiateInitialViewController(from: storyboard)
    }

    // MARK: - 快速创建方法

    /// 从指定的 storyboard 文件加载 ViewController
    static func fromStoryboard(_ name: String, identifier: String? = nil) -> Self {
        let storyboard = Storyboard.custom(name)

        if let identifier = identifier {
            return storyboard.instantiateViewController(withIdentifier: identifier)
        } else {
            return storyboard.instantiateViewController(self)
        }
    }
}

// MARK: - Array 批量加载扩展

public extension Array where Element == UIViewController.Type {
    /// 批量从 Storyboard 加载 ViewControllers
    func loadAllFromStoryboard(from storyboard: Storyboard = .main) -> [UIViewController] {
        return map { type in
            let identifier = String(describing: type)
            return storyboard.instance.instantiateViewController(withIdentifier: identifier)
        }
    }

    /// 批量从 Storyboard 加载指定类型的 ViewControllers（类型安全）
    func loadAllFromStoryboard<T: UIViewController>(as _: T.Type, from storyboard: Storyboard = .main) -> [T] {
        return compactMap { elementType in
            let identifier = String(describing: elementType)
            return storyboard.instance.instantiateViewController(withIdentifier: identifier) as? T
        }
    }
}

// MARK: - 安全加载扩展（非 fatalError 版本）

public extension Storyboard {
    /// 安全通过 Storyboard ID 获取 ViewController（返回可选值）
    func safeInstantiateViewController<T: UIViewController>(withIdentifier identifier: String) -> T? {
        return instance.instantiateViewController(withIdentifier: identifier) as? T
    }

    /// 安全通过类名获取 ViewController（返回可选值）
    func safeInstantiateViewController<T: UIViewController>(_ type: T.Type) -> T? {
        let identifier = String(describing: type)
        return safeInstantiateViewController(withIdentifier: identifier)
    }

    /// 安全获取 Initial ViewController（返回可选值）
    func safeInstantiateInitialViewController<T: UIViewController>() -> T? {
        return instance.instantiateInitialViewController() as? T
    }
}

public extension UIStoryboard {
    /// 安全从 Storyboard 实例化 ViewController（返回可选值）
    static func safeInstantiateViewController<T: UIViewController>(
        _ type: T.Type,
        from storyboard: Storyboard = .main
    ) -> T? {
        return storyboard.safeInstantiateViewController(type)
    }

    /// 安全从 Storyboard 实例化 ViewController（指定 Storyboard ID，返回可选值）
    static func safeInstantiateViewController<T: UIViewController>(
        withIdentifier identifier: String,
        from storyboard: Storyboard = .main
    ) -> T? {
        return storyboard.safeInstantiateViewController(withIdentifier: identifier)
    }
}

public extension UIViewController {
    /// 安全从 Storyboard 加载 ViewController（返回可选值）
    static func safeLoadFromStoryboard(from storyboard: Storyboard = .main) -> Self? {
        return UIStoryboard.safeInstantiateViewController(self, from: storyboard)
    }

    /// 安全从 Storyboard 加载 ViewController（指定 Storyboard ID，返回可选值）
    static func safeLoadFromStoryboard(
        withIdentifier identifier: String,
        from storyboard: Storyboard = .main
    ) -> Self? {
        return UIStoryboard.safeInstantiateViewController(withIdentifier: identifier, from: storyboard)
    }
}

// MARK: - Bundle 支持扩展

public extension Storyboard {
    /// 从指定 Bundle 获取 Storyboard 实例
    func instance(in bundle: Bundle) -> UIStoryboard {
        return UIStoryboard(name: name, bundle: bundle)
    }

    /// 从指定 Bundle 通过 Storyboard ID 获取 ViewController
    func instantiateViewController<T: UIViewController>(
        withIdentifier identifier: String,
        in bundle: Bundle
    ) -> T {
        guard let viewController = instance(in: bundle).instantiateViewController(withIdentifier: identifier) as? T else {
            fatalError("❌ Storyboard 错误: 无法在 \(name).storyboard 中找到 ID 为 '\(identifier)' 的 \(T.self) 类型")
        }
        return viewController
    }
}

// MARK: - Codable 支持

extension Storyboard: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let name = try container.decode(String.self)
        self = name == "Main" ? .main : .custom(name)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(name)
    }
}

// MARK: - ExpressibleByStringLiteral 支持

extension Storyboard: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = value == "Main" ? .main : .custom(value)
    }
}
