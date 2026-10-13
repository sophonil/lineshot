# Lineshot

**本地预览版，尚未发布。** 当前图标为占位，收到正式图标后再发布。

把截图、复制的文本和待办记事本挂在屏幕顶部，随用随取。

这是 sophonil 基于 Alejandro Buján 的 [Tendedero](https://github.com/alejandrobujan/tendedero) 制作的独立 Fork，保留原项目历史与交互风格。不是原作者的官方版本，也不代表原作者认可。本版使用独立名称和新图标。

[English](../../README.md) · [发布版本](https://github.com/sophonil/lineshot/releases)

## 新增功能

- **文本剪贴板**：在菜单中开启「悬挂复制的文本」，复制的纯文本即可上绳。单击复制完整原文，保留换行、缩进和 Unicode。默认关闭，跳过带隐私/临时标记的剪贴板、空白文本和超过 1 MiB 的文本。
- **固定待办与随手记**：点击第一张卡片即可添加、编辑、勾选、删除待办，下方可以写多行备注。输入后按回车添加待办；已添加的任务和备注自动保存，重启后恢复。
- **整体居中**：只有待办时居中；增加截图和文本后，整组向两侧展开，待办始终排在第一张。超出容量时，其余卡片可以滚动。

原来的夹子、玻璃相框、截图操作和自动收起行为保留。「全部取下」只清空截图和文本，不影响待办。App 自己目录中的文件会移到废纸篓，其他位置的文件仅从绳子上移除；没有内容可取下时，该菜单变灰。

## 安装与数据

支持 macOS 14 及以后，构建包兼容 Apple 芯片和 Intel Mac。

先退出旧 App，再解压发布 ZIP，将 **Lineshot.app** 拖入「应用程序」。本地构建默认使用 ad hoc 签名，未经 Apple 公证；有 Developer ID 时可自行签名。

新版使用独立 Bundle ID `io.github.sophonil.Lineshot`，截图保存在 `~/Library/Application Support/Lineshot/Screenshots`。第一次启动时，会复制之前个人开发版里已有的待办与随手记，不修改旧数据。截图接管、剪贴板开关和旧卡片路径不会迁移，需要时请在菜单重新开启。不要同时运行两份会接管截图的 App。

不新增账号、分析统计或内容上传。文本保存为本地 UTF-8 文件，创建时仅当前用户可读写；待办和备注使用本地偏好存储。「检查更新」打开此 Fork 的 GitHub 发布页。

## 从源码构建

```sh
git clone https://github.com/sophonil/lineshot.git
cd lineshot
git switch feature/customizations
scripts/build-app.sh
open build/Lineshot.app
```

需要 Swift 工具链。内部模块及源码目录保留 `Tendedero` 名称，方便与上游比较。检查命令：

```sh
swift test
swift scripts/check-strings.swift
```

`scripts/make-dmg.sh` 可生成 DMG，不自动进行公证。

## 作者与许可

原作：Alejandro Buján。新增功能与独立记事本图标：sophonil。

保留原作者版权声明与 [LICENSE](../../LICENSE)。原项目名称、图标不属于其 MIT 源码授权范围，发布修改版需要独立名称和图标；本版遵守此要求。
