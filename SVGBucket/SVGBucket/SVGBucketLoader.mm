// SVGBucketLoader.mm
//
//  SVGBucketLoader.mm
//  CommonSdkCore
//
//  Created by xiaoshanlin on 2026/1/1.
//

#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>

#import "SVGBucketLoader.h"

#include "SVGBucket.hpp"


// RAII包装器用于Core Graphics对象
struct CGDataProviderDeleter {
    void operator()(CGDataProviderRef provider) {
        if (provider) {
            CGDataProviderRelease(provider);
        }
    }
};
using CGDataProviderPtr = std::unique_ptr<typename std::remove_pointer<CGDataProviderRef>::type, CGDataProviderDeleter>;

struct CGColorSpaceDeleter {
    void operator()(CGColorSpaceRef colorSpace) {
        if (colorSpace) {
            CGColorSpaceRelease(colorSpace);
        }
    }
};
using CGColorSpacePtr = std::unique_ptr<typename std::remove_pointer<CGColorSpaceRef>::type, CGColorSpaceDeleter>;

struct CGImageDeleter {
    void operator()(CGImageRef image) {
        if (image) {
            CGImageRelease(image);
        }
    }
};
using CGImagePtr = std::unique_ptr<typename std::remove_pointer<CGImageRef>::type, CGImageDeleter>;

// 释放回调函数
static void releaseDataCallback(void *info, const void *data, size_t size) {
    free((void*)data);
}

@interface SVGBucketLoader () {
    std::unique_ptr<SVGBucket> _bucket;
}

@property (nonatomic, copy) NSString *filePath;

@end

@implementation SVGBucketLoader

- (instancetype)initWithFilePath:(NSString *)filePath {
    self = [super init];
    if (self) {
        _filePath = [filePath copy];
        _bucket = std::make_unique<SVGBucket>(std::string([filePath UTF8String]));
    }
    return self;
}

- (BOOL)setup {
    if (!_bucket) {
        return NO;
    }
    return _bucket->setup();
}

- (BOOL)isReady {
    return _bucket ? _bucket->isReady() : NO;
}

+ (UIImage * _Nullable)imageFromBitmap:(SVGBucket::ImageInfoPtr)bitmap scale:(CGFloat)scale {
    if (!bitmap) {
        //NSLog(@"[SVGLoader] Error: Invalid bitmap");
        return nil;
    }
    
    int width = bitmap->width();
    int height = bitmap->height();
    
    if (width <= 0 || height <= 0) {
        //NSLog(@"[SVGLoader] Error: Invalid bitmap dimensions: %dx%d", width, height);
        return nil;
    }
    
    uint8_t* rgbaBuffer = nullptr;
    
    @try {
        uint8_t* srcData = bitmap->data();
//        int srcStride = bitmap->stride();
        
        if (!srcData) {
            //NSLog(@"[SVGLoader] Error: Bitmap data is null");
            return nil;
        }
        
        size_t bufferSize = width * height * 4;
        rgbaBuffer = (uint8_t*)malloc(bufferSize);
        if (!rgbaBuffer) {
            //NSLog(@"[SVGLoader] Error: Failed to allocate buffer");
            return nil;
        }
        
        std::memcpy(rgbaBuffer, srcData, bufferSize);
    
        CGDataProviderPtr provider(CGDataProviderCreateWithData(
                                                                NULL,                    // info
                                                                rgbaBuffer,              // data
                                                                bufferSize,              // size
                                                                releaseDataCallback      // releaseData callback
                                                                ));
        
        if (!provider) {
            //NSLog(@"[SVGLoader] Error: Failed to create CGDataProvider");
            free(rgbaBuffer);
            return nil;
        }
        
        CGColorSpacePtr colorSpace(CGColorSpaceCreateDeviceRGB());
        if (!colorSpace) {
            //NSLog(@"[SVGLoader] Error: Failed to create CGColorSpace");
            // provider会在析构时释放rgbaBuffer
            return nil;
        }
        
        CGImagePtr imageRef(CGImageCreate(
                                          width,                      // width
                                          height,                     // height
                                          8,                          // bitsPerComponent
                                          32,                         // bitsPerPixel
                                          width * 4,                  // bytesPerRow
                                          colorSpace.get(),           // colorSpace
                                          kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big, // bitmapInfo
                                          provider.get(),             // provider
                                          NULL,                       // decode
                                          NO,                         // shouldInterpolate
                                          kCGRenderingIntentDefault   // intent
                                          ));
        
        if (!imageRef) {
            //NSLog(@"[SVGLoader] Error: Failed to create CGImage");
            // provider和colorSpace会在析构时自动释放
            return nil;
        }
        
        UIImage *image = [UIImage imageWithCGImage:imageRef.get()
                                             scale:scale
                                       orientation:UIImageOrientationUp];
        
        return image;
        
    } @catch (NSException *exception) {
        // 异常情况下确保buffer被释放
        if (rgbaBuffer) {
            free(rgbaBuffer);
        }
        //NSLog(@"[SVGLoader] Exception: %@", exception);
        return nil;
    }
}

// 修改 SVGBucketLoader.mm 中的 getImageWithName 方法：
- (UIImage *)getImageWithName:(NSString *)name
                        width:(uint32_t)width
                       height:(uint32_t)height {
    auto scale = UIScreen.mainScreen.scale;
    auto info = _bucket->getImageInfo(name.UTF8String, width * scale, height * scale);
    return [SVGBucketLoader imageFromBitmap:info scale:scale];
}


- (CGSize)getImageSizeWithName:(NSString *)name {
    if (!_bucket || !_bucket->isReady()) {
        return CGSizeZero;
    }
    
    std::string nameStr = [name UTF8String];
    auto size = _bucket->getImageInfo(nameStr);
    return CGSizeMake(size->width(), size->height());
}

- (NSArray<NSString *> *)getAllImageNames {
    if (!_bucket) {
        return @[];
    }
    
    std::vector<std::string> names = _bucket->getAllImageNames();
    NSMutableArray<NSString *> *result = [NSMutableArray arrayWithCapacity:names.size()];
    
    for (const auto& name : names) {
        [result addObject:[NSString stringWithUTF8String:name.c_str()]];
    }
    
    return [result copy];
}

- (NSArray<NSString *> *)getAllFileNames {
    if (!_bucket) {
        return @[];
    }
    
    std::vector<std::string> names = _bucket->getAllFileNames();
    NSMutableArray<NSString *> *result = [NSMutableArray arrayWithCapacity:names.size()];
    
    for (const auto& name : names) {
        [result addObject:[NSString stringWithUTF8String:name.c_str()]];
    }
    
    return [result copy];
}

- (BOOL)hasImageWithName:(NSString *)name {
    if (!_bucket) {
        return NO;
    }
    
    std::string nameStr = [name UTF8String];
    return _bucket->hasImage(nameStr);
}

- (NSUInteger)fileCount {
    return _bucket ? _bucket->getFileCount() : 0;
}

@end
