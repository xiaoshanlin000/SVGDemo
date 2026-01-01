// SVGBucket.hpp
#pragma once

#include <string>
#include <vector>
#include <unordered_map>
#include <memory>
#include <fstream>

#ifdef __APPLE__
    #include "TargetConditionals.h"
    #if TARGET_OS_IOS
        #include <lunasvg/lunasvg/lunasvg.h>
    #else
        #include <lunasvg/lunasvg.h>
    #endif
#else
    // 非 Apple 平台
    #include <lunasvg/lunasvg.h>
#endif
class SVGBucket {
public:

    /**
     * @brief 智能指针包装的图片信息
     */
    using ImageInfoPtr = std::shared_ptr<lunasvg::Bitmap>;

    /**
     * @brief 构造函数
     * @param filePath 完整的文件路径（包含文件名）
     */
    explicit SVGBucket(const std::string& filePath);

    /**
     * @brief 析构函数
     */
    ~SVGBucket();

    // 禁止拷贝
    SVGBucket(const SVGBucket&) = delete;
    SVGBucket& operator=(const SVGBucket&) = delete;

    // 允许移动
    SVGBucket(SVGBucket&& other) noexcept;
    SVGBucket& operator=(SVGBucket&& other) noexcept;

    /**
     * @brief 设置和初始化读取器
     * @return true 成功，false 失败
     */
    bool setup();

    /**
     * @brief 检查是否已初始化
     */
    bool isReady() const { return m_ready; }

    /**
     * @brief 获取 SVG 图片的完整信息
     * @param name 图片名称
     * @param width 目标宽度
     * @param height 目标高度
     * @param backgroundColor 背景颜色
     * @return 图片信息智能指针，失败返回空指针
     */
    ImageInfoPtr getImageInfo(const std::string& name,
                              uint32_t width = 0,
                              uint32_t height = 0,
                              uint32_t backgroundColor = 0x00000000);

    /**
     * @brief 获取所有可用的图片名称（不带 .svg 后缀）
     * @return 图片名称列表
     */
    std::vector<std::string> getAllImageNames() const;

    /**
     * @brief 获取所有文件名（带 .svg 后缀）
     * @return 文件名列表
     */
    std::vector<std::string> getAllFileNames() const;

    /**
     * @brief 检查图片是否存在
     * @param name 图片名称
     * @return true 存在，false 不存在
     */
    bool hasImage(const std::string& name) const;

    /**
     * @brief 获取文件数量
     */
    size_t getFileCount() const { return m_fileInfos.size(); }

private:
    struct FileInfo {
        uint32_t offset;
        uint32_t size;
    };

    std::string m_filePath;
    std::unordered_map<std::string, FileInfo> m_fileInfos;
    std::unique_ptr<std::ifstream> m_fileStream;
    uint32_t m_indexTableSize = 0;
    bool m_ready = false;

    // 内部辅助方法
    bool readBytes(std::vector<uint8_t>& buffer, size_t count);
    bool seekToOffset(uint32_t offset);
    std::shared_ptr<std::vector<uint8_t>> loadSVGData(const std::string& name);
    std::string normalizeImageName(const std::string& name) const;
};
