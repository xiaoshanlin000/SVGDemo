// SVGBucketLoader.h
//
//  SVGBucketLoader.h
//  CommonSdkCore
//
//  Created by xiaoshanlin on 2026/1/1.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// SVG 桶加载器
@interface SVGBucketLoader : NSObject

/// 初始化加载器
/// @param filePath 文件完整路径
- (nullable instancetype)initWithFilePath:(NSString *)filePath NS_DESIGNATED_INITIALIZER;

/// 不可用
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/// 设置并初始化读取器
/// @return 是否成功
- (BOOL)setup;

/// 检查是否已准备好
@property (nonatomic, readonly) BOOL isReady;
 

/// 获取 SVG 图片并渲染为 UIImage
/// @param name 图片名称（不需要 .svg 后缀）
/// @param width 目标宽度（0 表示使用 SVG 原始宽度）
/// @param height 目标高度（0 表示使用 SVG 原始高度）
/// @return UIImage 对象，失败返回 nil
- (nullable UIImage *)getImageWithName:(NSString *)name
                                 width:(uint32_t)width
                                height:(uint32_t)height;


/// 获取图片尺寸
/// @param name 图片名称
/// @return 图片尺寸，失败返回 (0, 0)
- (CGSize)getImageSizeWithName:(NSString *)name;

/// 获取所有可用的图片名称（不带 .svg 后缀）
/// @return 图片名称列表
- (NSArray<NSString *> *)getAllImageNames;

/// 获取所有文件名（带 .svg 后缀）
/// @return 文件名列表
- (NSArray<NSString *> *)getAllFileNames;

/// 检查图片是否存在
/// @param name 图片名称
/// @return 是否存在
- (BOOL)hasImageWithName:(NSString *)name;

/// 获取文件数量
@property (nonatomic, readonly) NSUInteger fileCount;

@end

NS_ASSUME_NONNULL_END
