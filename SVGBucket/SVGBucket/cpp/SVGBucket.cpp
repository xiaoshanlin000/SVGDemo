// SVGBucket.cpp
#include "SVGBucket.hpp"
#include <algorithm>
#include <cstring>
#include <filesystem>
#include <sstream>

// PNG 写入回调函数
struct PNGWriteData {
    std::shared_ptr<std::vector<uint8_t>> buffer; // 指向 vector 的指针
    std::ofstream *file;
};

static void pngWriteCallback(void *closure, void *data, int size) {
    auto *writeData = static_cast<PNGWriteData *>(closure);
    if (writeData->buffer) {
        uint8_t *bytes = static_cast<uint8_t *>(data);
        writeData->buffer->insert(writeData->buffer->end(), bytes, bytes + size);
    }
    if (writeData->file && writeData->file->is_open()) {
        writeData->file->write(static_cast<const char *>(data), size);
    }
}

SVGBucket::SVGBucket(const std::string &filePath) :
    m_filePath(filePath), m_fileStream(std::make_unique<std::ifstream>()) {}

SVGBucket::~SVGBucket() = default;

SVGBucket::SVGBucket(SVGBucket &&other) noexcept :
    m_filePath(std::move(other.m_filePath)), m_fileInfos(std::move(other.m_fileInfos)),
    m_fileStream(std::move(other.m_fileStream)), m_indexTableSize(other.m_indexTableSize), m_ready(other.m_ready) {
    other.m_ready = false;
    other.m_indexTableSize = 0;
}

SVGBucket &SVGBucket::operator=(SVGBucket &&other) noexcept {
    if (this != &other) {
        m_filePath = std::move(other.m_filePath);
        m_fileInfos = std::move(other.m_fileInfos);
        m_fileStream = std::move(other.m_fileStream);
        m_indexTableSize = other.m_indexTableSize;
        m_ready = other.m_ready;

        other.m_ready = false;
        other.m_indexTableSize = 0;
    }
    return *this;
}

bool SVGBucket::readBytes(std::vector<uint8_t> &buffer, size_t count) {
    buffer.resize(count);
    m_fileStream->read(reinterpret_cast<char *>(buffer.data()), count);
    return m_fileStream->gcount() == static_cast<std::streamsize>(count);
}

bool SVGBucket::seekToOffset(uint32_t offset) {
    m_fileStream->seekg(offset, std::ios::beg);
    return m_fileStream->good();
}

bool SVGBucket::setup() {
    if (m_ready) {
        return true;
    }

    m_fileStream->open(m_filePath, std::ios::binary);
    if (!m_fileStream->is_open()) {
        return false;
    }

    // 验证魔数 "SVGB"
    std::vector<uint8_t> magic(4);
    if (!readBytes(magic, 4) || std::string(magic.begin(), magic.end()) != "SVGB") {
        m_fileStream->close();
        return false;
    }

    // 跳过版本号 (2字节)
    std::vector<uint8_t> version(2);
    if (!readBytes(version, 2)) {
        m_fileStream->close();
        return false;
    }

    // 读取文件数量
    std::vector<uint8_t> countData(4);
    if (!readBytes(countData, 4)) {
        m_fileStream->close();
        return false;
    }

    uint32_t fileCount = 0;
    std::memcpy(&fileCount, countData.data(), 4);

    // 读取文件索引表
    uint32_t currentIndexSize = 10; // 魔数4 + 版本2 + 文件数量4

    for (uint32_t i = 0; i < fileCount; ++i) {
        // 读取文件名长度
        std::vector<uint8_t> nameLengthData(2);
        if (!readBytes(nameLengthData, 2)) {
            m_fileStream->close();
            return false;
        }
        currentIndexSize += 2;

        uint16_t nameLength = 0;
        std::memcpy(&nameLength, nameLengthData.data(), 2);

        // 读取文件名
        std::vector<uint8_t> nameData(nameLength);
        if (!readBytes(nameData, nameLength)) {
            m_fileStream->close();
            return false;
        }
        currentIndexSize += nameLength;

        std::string filename(nameData.begin(), nameData.end());

        // 读取文件偏移和大小
        std::vector<uint8_t> offsetData(4);
        std::vector<uint8_t> sizeData(4);
        if (!readBytes(offsetData, 4) || !readBytes(sizeData, 4)) {
            m_fileStream->close();
            return false;
        }
        currentIndexSize += 8;

        uint32_t fileOffset = 0;
        uint32_t fileSize = 0;
        std::memcpy(&fileOffset, offsetData.data(), 4);
        std::memcpy(&fileSize, sizeData.data(), 4);

        m_fileInfos[filename] = {fileOffset, fileSize};
    }

    m_indexTableSize = currentIndexSize;
    m_ready = true;
    return true;
}

std::string SVGBucket::normalizeImageName(const std::string &name) const {
    std::string normalized = name;
    if (normalized.size() < 4 || normalized.substr(normalized.size() - 4) != ".svg") {
        normalized += ".svg";
    }
    return normalized;
}

std::shared_ptr<std::vector<uint8_t>> SVGBucket::loadSVGData(const std::string &name) {
    if (!m_ready || !m_fileStream) {
        return nullptr;
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
            return nullptr;
        }
    }

    const auto &info = it->second;
    uint32_t actualOffset = m_indexTableSize + info.offset;

    if (!seekToOffset(actualOffset)) {
        return nullptr;
    }

    auto svgData = std::make_shared<std::vector<uint8_t>>(info.size);
    m_fileStream->read(reinterpret_cast<char *>(svgData->data()), info.size);

    if (m_fileStream->gcount() != static_cast<std::streamsize>(info.size)) {
        return nullptr;
    }

    return svgData;
}

SVGBucket::ImageInfoPtr SVGBucket::getImageInfo(const std::string &name, uint32_t width, uint32_t height,
                                                uint32_t backgroundColor) {
    auto svgData = loadSVGData(name);
    if (!svgData || svgData->empty()) {
        return nullptr;
    }

    std::string svgString(svgData->begin(), svgData->end());
    auto document = lunasvg::Document::loadFromData(svgString);
    if (!document) {
        return nullptr;
    }

    // 渲染为位图
    auto bitmap = document->renderToBitmap(width > 0 ? static_cast<int>(width) : -1,
                                           height > 0 ? static_cast<int>(height) : -1, backgroundColor);

    if (bitmap.isNull()) {
        return nullptr;
    }
    bitmap.convertToRGBA();
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
           m_fileInfos.find(name + ".svg") != m_fileInfos.end() || m_fileInfos.find(name) != m_fileInfos.end();
}
