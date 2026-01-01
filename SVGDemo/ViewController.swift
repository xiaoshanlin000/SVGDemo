//
//  ViewController.swift
//  SVGDemo
//
//  Created by xiaoshanlin on 2026/1/1.
//

import UIKit
import SVGBucket

class ViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK: - Properties
    private var imageNames: [String] = []
    private let cellSize = CGSize(width: 50, height: 50)
    private var imageCache: [String: UIImage] = [:]
    private var cacheOrder: [String] = [] // 记录缓存顺序
    private let maxCacheCount = 100 // 最多缓存100张图片
    private let imageLoadQueue = DispatchQueue(label: "com.svgbucket.imageLoad", attributes: .concurrent)
    private var loadingIndexPaths: Set<IndexPath> = [] // 记录正在加载的 indexPath
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        loadImageNames()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        clearCache() // 收到内存警告时清空缓存
    }
    
    // MARK: - Setup
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // 注册自定义 cell
        collectionView.register(ImageCollectionViewCell.self, forCellWithReuseIdentifier: "ImageCell")
        
        // 配置布局
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = cellSize
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        collectionView.collectionViewLayout = layout
    }
    
    private func loadImageNames() {
        // 直接从 ImageiconSVGBReader 获取所有图片名称
        imageNames = ImageiconSVGBReader.shared.getAllImageNames()
        printWithTime("加载了 \(imageNames.count) 个图片名称")
        collectionView.reloadData()
    }
    
    // MARK: - Cache Management
    private func cacheImage(_ image: UIImage, for key: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 如果已经存在，更新位置到最新
            if let index = self.cacheOrder.firstIndex(of: key) {
                self.cacheOrder.remove(at: index)
            }
            
            // 缓存图片
            self.imageCache[key] = image
            self.cacheOrder.append(key)
            
            // 如果超过限制，移除最旧的（第一个）
            if self.cacheOrder.count > self.maxCacheCount {
                let oldestKey = self.cacheOrder.removeFirst()
                self.imageCache.removeValue(forKey: oldestKey)
                
                #if DEBUG
                //print("移除缓存: \(oldestKey), 当前缓存数量: \(self.cacheOrder.count)")
                #endif
            }
            
            #if DEBUG
            //print("缓存图片: \(key), 当前缓存数量: \(self.cacheOrder.count)")
            #endif
        }
    }
    
    private func getCachedImage(for key: String) -> UIImage? {
        // 如果找到，更新缓存顺序
        if let image = imageCache[key] {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                if let index = self.cacheOrder.firstIndex(of: key) {
                    // 移到数组末尾表示最新使用
                    self.cacheOrder.remove(at: index)
                    self.cacheOrder.append(key)
                }
            }
            return image
        }
        return nil
    }
    
    private func clearCache() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.imageCache.removeAll()
            self.cacheOrder.removeAll()
            self.loadingIndexPaths.removeAll()
            //print("缓存已清空")
        }
    }
    
    // MARK: - Image Loading
    private func loadImageAsync(for name: String, indexPath: IndexPath) {
        // 检查缓存
        if let cachedImage = getCachedImage(for: name) {
            // 直接更新 cell，不需要异步
            DispatchQueue.main.async {
                if indexPath.item < self.imageNames.count && self.imageNames[indexPath.item] == name {
                    self.updateCell(with: cachedImage, at: indexPath)
                }
            }
            return
        }
        
        // 标记该 indexPath 正在加载
        loadingIndexPaths.insert(indexPath)
        
        // 异步加载图片
        imageLoadQueue.async { [weak self] in
            guard let self = self else { return }
            
            // 加载图片
            let image = ImageiconSVGBReader.shared.image(named: name, width: self.cellSize.width, height: self.cellSize.width)
            
            // 缓存图片
            if let image = image {
                self.cacheImage(image, for: name)
            }
            
            // 回到主线程更新UI
            DispatchQueue.main.async {
                // 移除加载标记
                self.loadingIndexPaths.remove(indexPath)
                
                // 验证当前 indexPath 是否仍然有效
                if indexPath.item < self.imageNames.count &&
                   self.imageNames[indexPath.item] == name {
                    
                    // 检查 cell 是否可见
                    if let cell = self.collectionView.cellForItem(at: indexPath) as? ImageCollectionViewCell {
                        cell.imageView.image = image ?? UIImage()
                    }
                }
            }
        }
    }
    
    private func updateCell(with image: UIImage?, at indexPath: IndexPath) {
        // 直接获取 cell，如果 cell 可见则更新
        if let cell = collectionView.cellForItem(at: indexPath) as? ImageCollectionViewCell {
            cell.imageView.image = image ?? UIImage()
        }
    }
}

// MARK: - UICollectionViewDataSource
extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageNames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCollectionViewCell
        
        let name = imageNames[indexPath.item]
        
        // 首先检查缓存中是否有图片
        if let cachedImage = getCachedImage(for: name) {
            // 如果有缓存，直接设置图片
            cell.imageView.image = cachedImage
        } else {
            // 没有缓存，设置占位符
            cell.imageView.image = UIImage()
            
            // 如果该 indexPath 没有正在加载，则启动异步加载
            if !loadingIndexPaths.contains(indexPath) {
                loadImageAsync(for: name, indexPath: indexPath)
            }
        }
        
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return cellSize
    }
    
    // 添加此方法：当 cell 即将显示时，确保图片加载
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let name = imageNames[indexPath.item]
        guard let cell = cell as? ImageCollectionViewCell else { return }
        
        // 如果 cell 的 imageView 没有图片，重新加载
        if cell.imageView.image == nil || cell.imageView.image == UIImage() {
            // 检查缓存
            if let cachedImage = getCachedImage(for: name) {
                cell.imageView.image = cachedImage
            } else if !loadingIndexPaths.contains(indexPath) {
                // 没有缓存且不在加载中，则重新加载
                loadImageAsync(for: name, indexPath: indexPath)
            }
        }
    }
}

// MARK: - 自定义 UICollectionViewCell
class ImageCollectionViewCell: UICollectionViewCell {
    let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.backgroundColor = .clear
        iv.layer.cornerRadius = 8
        iv.tintColor = .lightGray
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // 这里可以不清空 image，因为在 cellForItemAt 中会重新设置
    }
    
    private func setupUI() {
        contentView.addSubview(imageView)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        // 简单约束：imageView 填充整个 cell
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
}
