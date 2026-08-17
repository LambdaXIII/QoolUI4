# QoolFile 模块规范

Qool.File（URI: `Qool.File`）是特化的文件处理模块：文件信息读取（缓存）与展示、多选文件列表（多层插拔）、文件图标、拖放接入。

在 QoolFile 模块内工作时，除本文件外还必须遵循根级 [AGENTS.md](../../AGENTS.md)。

## 模块定位

- 特化文件处理能力，是 Qool 的独立子模块
- 数据层（Model/DB）与展示层（View/Delegate/Display）分离
- 文件信息与文件图标数据均可经插件接口扩展（FileInfoProvider / fileiconprovider）

## 多层插拔落地（设计哲学见根 AGENTS.md「QML 组件规范」节）

```
FileInfoListModel ──配套──▶ FileInfoListView ──配套──▶ FileInfoDelegate ──配套──▶ BasicFileInfoDisplay
      (数据层)                 (View 层)                (行为层)                    (Display 层, 纯样式)
```

| 层 | 文件 | 替换接口 |
|---|---|---|
| Model | `FileInfoListModel`（C++：QAbstractListModel，单线程契约，13 个 Role） | 用户可自行实现 View 配 Model；Model 亦可用其他 QAbstractListModel |
| View | `FileInfoListView.qml` | `delegate`（默认 `FileInfoDelegate`）；`fileInfoDisplay` 属性透传给 delegate |
| Delegate | `FileInfoDelegate.qml` | `fileInfoDisplay`（默认 `BasicFileInfoDisplay`）；行为层（多选/拖放排序/插入）在 Delegate 内，换 Display 不丢行为 |
| Display | `BasicFileInfoDisplay.qml` | 契约：`checked: bool` + `fileInfo: fileinfo` 属性；内部全部取 `root.Style.*` |
| 组合入口 | `FileInfoListControl.qml`（FileDropper 容器 + View + ToolBar + 空状态提示） | 成品组件，直接可用 |

关键规则：

- **Display 契约**：自定义 Display 必须实现 `checked` 与 `fileInfo` 两个属性（Delegate 经 Loader + Binding 注入）
- **行为归属**：选择、拖放排序、插入属于 Delegate 层，不下放到 Display；View 层不绕过 Delegate 直接操作模型
- 默认 Display 值在 View 与 Delegate 两处各有一份（`BasicFileInfoDisplay {}`），修改默认实现时需同步

## C++ 设施

- `FileInfoListModel`：单线程列表模型（遵循 Qt 模型线程规范，跨线程访问经 Queued 转发）；insert/append/remove/take/move/sort/removeDuplicates 全套操作；`fileInfos` 可写属性；move 支持多行
- `FileInfoDB`（进程级 C++ 单例）：QCache 缓存文件信息（QUrl→QVariantMap）；`getFileInfo(url/path)`；经 `FileInfoProvider` 插件接口扩展提供者（autoInstallProviders）。不暴露 QML——QML 面走 `FileInfoHQ`（QML 单例，每 engine 独立实例，转发 getFileInfo 命中共享缓存）
- `FileIconDB`（进程级 C++ 单例）+ 图标 ImageProvider：文件图标体系，可经 fileiconprovider 插件扩展；QML 面走 `FileIconHQ`（iconUrl）
- `UrlChecker`：URL 校验
- `fileinfo`（FileInfo）：文件信息值类型（QML 可见，链式 API）

## 已知陷阱

- 拖放排序走 Delegate 内 DropArea + `FileInfoListModel.move`，不要绕过模型直接改列表
