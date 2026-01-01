# SVGBucket

iOS SVG图标资源库，兼容iOS 11+。集成6260个SVG图标，打包到ImageIcon.bundle中（4MB）。

## 图标来源

- https://github.com/dmhendricks/file-icon-vectors
- https://icons.getbootstrap.com/
- https://remixicon.com/

总共 6260 个图标。

## 依赖

SVG 绘制使用到了 https://github.com/sammycage/lunasvg 这个库。

## 使用方法

```swift
import SVGBucket

Resource.initResource()
```

特性
支持iOS 11及以上版本

集成6260个SVG图标

图标资源打包为ImageIcon.bundle（4MB）

基于LunaSVG的高性能渲染

## 详情

详情见Demo。

## 结果

```
2026-01-01 14:48:02.300 com.apple.main-thread  [init resource] use -> 11.1 ms
2026-01-01 14:48:02.379 com.apple.main-thread  [load svg] use -> 388.5 μs
2026-01-01 14:48:02.379 com.apple.main-thread  total file: 6260
```