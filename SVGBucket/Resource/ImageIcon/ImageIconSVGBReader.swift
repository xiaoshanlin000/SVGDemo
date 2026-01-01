// SVGB格式读取器 - 自动生成
// 文件: ImageIcon.bundle/images.dat
// 包含 6260 个SVG文件
// 生成时间: 2025-12-31T21:01:35.474Z
// 依赖: SVGBucket
// 最低支持: iOS 11.0

import UIKit

@objc public class ImageiconSVGBReader: NSObject {
    public static let shared = ImageiconSVGBReader()

    var svgBucket: SVGBucketLoader?

    override private init() {
        super.init()
    }

    public func setup(bundle: Bundle = .main, filename: String = "images.dat") -> Bool {
        guard let _ = bundle.url(forResource: filename, withExtension: nil) else {
            // print("❌ ImageiconSVGBReader: 找不到文件: \(filename)")
            return false
        }
        guard let path = bundle.path(forResource: filename, ofType: nil) else { return false }
        svgBucket = SVGBucketLoader(filePath: path)
        let setup = svgBucket?.setup()
        return svgBucket != nil && setup != nil && setup!
    }

    /// 获取SVG图片
    /// - Parameters:
    ///   - name: 图片名称（不需要.svg后缀）
    ///   - targetSize: 目标尺寸（默认24x24）
    /// - Returns: UIImage对象或nil
    public func image(named name: String, targetSize: CGSize = CGSize(width: 24, height: 24)) -> UIImage? {
        return svgBucket?.getImageWithName(name, width: UInt32(targetSize.width), height: UInt32(targetSize.height))
    }

    /// 获取SVG图片并指定宽度和高度
    public func image(named name: String, width: CGFloat, height: CGFloat) -> UIImage? {
        return image(named: name, targetSize: CGSize(width: width, height: height))
    }

    /// 获取SVG图片（使用原始尺寸）
    public func image(named name: String) -> UIImage? {
        return image(named: name, targetSize: CGSize.zero)
    }

    /// 获取SVG图片的尺寸
    public func size(forImageNamed name: String) -> CGSize {
        guard let svgBucket = svgBucket else { return CGSize.zero }
        let size = svgBucket.getImageSize(withName: name)
        return size
    }
    
    public func fileCount()->UInt{
        guard let svgBucket = svgBucket else { return 0 }
        return svgBucket.fileCount
    }
}

// UIImage扩展，提供便利方法
public extension UIImage {
    static func imageicon(named name: String, targetSize: CGSize = CGSize(width: 24, height: 24)) -> UIImage? {
        return ImageiconSVGBReader.shared.image(named: name, targetSize: targetSize)
    }

    static func imageicon(named name: String, width: CGFloat, height: CGFloat) -> UIImage? {
        return ImageiconSVGBReader.shared.image(named: name, width: width, height: height)
    }

    static func imageicon(named name: String) -> UIImage? {
        return ImageiconSVGBReader.shared.image(named: name)
    }
}
