// SVGBucket.cpp
#include "SVGBucket.hpp"
#include <algorithm>
#include <cstring>
#include <filesystem>
#include <sstream>

SVGBucket::SVGBucket(const std::string &filePath) :
    m_filePath(filePath) {}

SVGBucket::~SVGBucket() = default;

SVGBucket::SVGBucket(SVGBucket &&other) noexcept :
    m_filePath(std::move(other.m_filePath)),
    m_fileInfos(std::move(other.m_fileInfos)),
    m_dataBuffer(std::move(other.m_dataBuffer)),
    m_dataSize(other.m_dataSize),
    m_ready(other.m_ready) {
    other.m_ready = false;
    other.m_dataSize = 0;
}

SVGBucket &SVGBucket::operator=(SVGBucket &&other) noexcept {
    if (this != &other) {
        m_filePath = std::move(other.m_filePath);
        m_fileInfos = std::move(other.m_fileInfos);
        m_dataBuffer = std::move(other.m_dataBuffer);
        m_dataSize = other.m_dataSize;
        m_ready = other.m_ready;

        other.m_ready = false;
        other.m_dataSize = 0;
    }
    return *this;
}

bool SVGBucket::setup() {
    if (m_ready) {
        return true;
    }

    if (!loadAllDataToMemory()) {
        return false;
    }

    m_ready = true;
    return true;
}

bool SVGBucket::loadAllDataToMemory() {
    std::ifstream fileStream(m_filePath, std::ios::binary | std::ios::ate);
    if (!fileStream.is_open()) {
        return false;
    }

    // 获取文件大小
    std::streamsize fileSize = fileStream.tellg();
    fileStream.seekg(0, std::ios::beg);

    // 一次性读取整个文件到临时缓冲区
    std::unique_ptr<uint8_t[]> entireFile(new uint8_t[fileSize]);
    fileStream.read(reinterpret_cast<char*>(entireFile.get()), fileSize);
    fileStream.close();

    if (!fileStream) {
        return false;
    }

    // 验证魔数 "SVGB"
    if (fileSize < 10 || std::string(entireFile.get(), entireFile.get() + 4) != "SVGB") {
        return false;
    }

    // 解析文件数量 (跳过魔数4字节和版本2字节)
    const uint8_t* dataPtr = entireFile.get() + 6;
    uint32_t fileCount = 0;
    std::memcpy(&fileCount, dataPtr, 4);
    dataPtr += 4;

    // 解析文件索引表
    std::vector<std::pair<std::string, FileInfo>> tempInfos;
    tempInfos.reserve(fileCount);

    const uint8_t* indexTableEnd = entireFile.get() + 10; // 初始偏移
    for (uint32_t i = 0; i < fileCount; ++i) {
        // 读取文件名长度
        uint16_t nameLength = 0;
        std::memcpy(&nameLength, dataPtr, 2);
        dataPtr += 2;
        indexTableEnd += 2;

        // 读取文件名
        std::string filename(reinterpret_cast<const char*>(dataPtr), nameLength);
        dataPtr += nameLength;
        indexTableEnd += nameLength;

        // 读取文件偏移和大小
        uint32_t fileOffset = 0;
        uint32_t fileSize = 0;
        std::memcpy(&fileOffset, dataPtr, 4);
        std::memcpy(&fileSize, dataPtr + 4, 4);
        dataPtr += 8;
        indexTableEnd += 8;

        tempInfos.emplace_back(filename, FileInfo{fileOffset, fileSize});
    }

    // 计算索引表实际结束位置和总数据大小
    uint32_t indexTableSize = static_cast<uint32_t>(indexTableEnd - entireFile.get());
    uint32_t maxOffset = 0;
    uint32_t maxSize = 0;

    for (const auto& info : tempInfos) {
        uint32_t endPos = info.second.offset + info.second.size;
        if (endPos > maxOffset) {
            maxOffset = endPos;
        }
    }

    m_dataSize = maxOffset;

    // 分配连续内存块
    m_dataBuffer.reset(new uint8_t[m_dataSize]);

    // 复制所有SVG数据到连续内存块
    for (const auto& info : tempInfos) {
        const uint8_t* srcData = entireFile.get() + indexTableSize + info.second.offset;

        // 确保数据在文件范围内
        uint32_t actualSize = info.second.size;
        if (indexTableSize + info.second.offset + actualSize > static_cast<uint32_t>(fileSize)) {
            // 数据越界，调整大小
            actualSize = static_cast<uint32_t>(fileSize) - (indexTableSize + info.second.offset);
        }

        if (actualSize == 0 || info.second.offset + actualSize > m_dataSize) {
            continue;
        }

        std::memcpy(m_dataBuffer.get() + info.second.offset, srcData, actualSize);

        // 存储调整后的文件信息
        m_fileInfos[info.first] = FileInfo{info.second.offset, actualSize};
    }

    return true;
}

std::string SVGBucket::normalizeImageName(const std::string &name) const {
    std::string normalized = name;
    if (normalized.size() < 4 || normalized.substr(normalized.size() - 4) != ".svg") {
        normalized += ".svg";
    }
    return normalized;
}

std::vector<uint8_t> SVGBucket::copyDataFromMemory(uint32_t offset, uint32_t size) const {
    std::vector<uint8_t> data;

    if (!m_dataBuffer || offset >= m_dataSize || offset + size > m_dataSize) {
        return data;
    }

    data.resize(size);
    std::memcpy(data.data(), m_dataBuffer.get() + offset, size);
    return data;
}

std::vector<uint8_t> SVGBucket::getSVGData(const std::string &name) const {
    if (!m_ready || !m_dataBuffer) {
        return {};
    }

    std::string normalizedName = normalizeImageName(name);

    auto it = m_fileInfos.find(normalizedName);
    if (it == m_fileInfos.end()) {
        // 尝试其他变体
        std::vector<std::string> candidates = {normalizedName, name + ".svg", name};

        for (const auto &candidate: candidates) {
            it = m_fileInfos.find(candidate);
            if (it != m_fileInfos.end()) {
                break;
            }
        }

        if (it == m_fileInfos.end()) {
            return {};
        }
    }

    const auto &info = it->second;
    return copyDataFromMemory(info.offset, info.size);
}

SVGBucket::ImageInfoPtr SVGBucket::getImageInfo(const std::string &name, uint32_t width, uint32_t height,
                                                bool rgba) {
    auto svgData = getSVGData(name);
    if (svgData.empty()) {
        return nullptr;
    }

    std::string svgString(svgData.begin(), svgData.end());
    auto document = lunasvg::Document::loadFromData(svgString);
    if (!document) {
        return nullptr;
    }

    // 渲染为位图
    auto bitmap = document->renderToBitmap(width > 0 ? static_cast<int>(width) : -1,
                                           height > 0 ? static_cast<int>(height) : -1, 0x00000000);

    if (bitmap.isNull()) {
        return nullptr;
    }
    if (rgba) {
        bitmap.convertToRGBA();
    }
    return std::make_shared<lunasvg::Bitmap>(std::move(bitmap));
}

std::vector<std::string> SVGBucket::getAllImageNames() const {
    std::vector<std::string> names;
    names.reserve(m_fileInfos.size());

    for (const auto &[filename, _]: m_fileInfos) {
        // 移除 .svg 后缀
        size_t dotPos = filename.find_last_of('.');
        if (dotPos != std::string::npos && filename.substr(dotPos) == ".svg") {
            std::string name = filename.substr(0, dotPos);
            if (std::find(names.begin(), names.end(), name) == names.end()) {
                names.push_back(std::move(name));
            }
        }
    }

    std::sort(names.begin(), names.end());
    return names;
}

std::vector<std::string> SVGBucket::getAllFileNames() const {
    std::vector<std::string> filenames;
    filenames.reserve(m_fileInfos.size());

    for (const auto &[filename, _]: m_fileInfos) {
        filenames.push_back(filename);
    }

    std::sort(filenames.begin(), filenames.end());
    return filenames;
}

bool SVGBucket::hasImage(const std::string &name) const {
    std::string normalizedName = normalizeImageName(name);
    return m_fileInfos.find(normalizedName) != m_fileInfos.end() ||
           m_fileInfos.find(name + ".svg") != m_fileInfos.end() ||
           m_fileInfos.find(name) != m_fileInfos.end();
}
