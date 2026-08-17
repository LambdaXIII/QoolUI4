# Qool.File 模块

文件域：文件信息列表（多层插拔）、图标解析与 URL 检查工具。

Qool.File 提供文件浏览与工具组件面：

- 多层插拔（View / Delegate / Display 三层配套）：`FileInfoListView`（特化
  视图，配 `FileInfoListModel`）、`FileInfoDelegate`（默认委托）、
  `BasicFileInfoDisplay`（可替换的显示组件——`fileInfoDisplay` 属性）。
- 模型与工具：`FileInfoListModel`（文件信息列表模型，单线程契约）、
  `UrlChecker`（URL 合法性与类型检查）。
- 单例查询面：`FileIconHQ`（文件图标查询，QML 单例）、`FileInfoHQ`
  （文件信息查询，QML 单例）、`FileIconImageProvider`（图标 image provider）。

## 组件参考

- [BasicFileInfoDisplay](BasicFileInfoDisplay.md)
- [FileIconHQ](FileIconHQ.md)
- [FileIconImageProvider](FileIconImageProvider.md)
- [FileInfoDelegate](FileInfoDelegate.md)
- [FileInfoHQ](FileInfoHQ.md)
- [FileInfoListModel](FileInfoListModel.md)
- [FileInfoListView](FileInfoListView.md)
- [UrlChecker](UrlChecker.md)
