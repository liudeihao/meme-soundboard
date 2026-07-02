<p align="center">
  <img src="docs/images/logo.jpg" alt="梗音效 Logo" width="320" style="border-radius: 24px;" />
</p>

<h1 align="center">🔊 梗音效 (meme_soundboard)</h1>

<p align="center">
  基于 Flutter 的本地梗音效板 — 分类浏览、收藏、搜索、主题切换，以及自定义 <code>.msb</code> 音效包的导入与导出 🎵
</p>

<p align="center">
  <a href="https://github.com/liudeihao/meme-soundboard"><img src="https://img.shields.io/badge/Flutter-跨平台-02569B?logo=flutter&logoColor=white" alt="Flutter"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg" alt="MIT License"></a>
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Windows%20%7C%20macOS%20%7C%20Linux%20%7C%20Web-blue" alt="Platforms">
  <img src="https://img.shields.io/badge/Dart-%5E3.10-0175C2?logo=dart&logoColor=white" alt="Dart SDK">
</p>

<p align="center">
  <a href="https://www.youtube.com/shorts/IPzSDJNfb8I">
    <img src="https://img.youtube.com/vi/IPzSDJNfb8I/hqdefault.jpg" alt="应用演示视频" width="720" style="border-radius: 16px;" />
  </a>
</p>

<p align="center"><sub>🎬 点击上方缩略图播放演示视频 · <a href="https://www.youtube.com/shorts/IPzSDJNfb8I">YouTube 链接</a></sub></p>

## 📱 Android 下载

侧载安装（无需 Google Play）：

<p align="center">
  <a href="https://github.com/liudeihao/meme-soundboard/releases/latest"><img src="https://img.shields.io/github/v/release/liudeihao/meme-soundboard?label=Latest%20Release&color=brightgreen" alt="Latest Release"></a>
</p>

1. 打开 [Releases 页面](https://github.com/liudeihao/meme-soundboard/releases/latest) 下载 `meme-soundboard-v*-android.apk`
2. 在手机上允许「安装未知应用」
3. 点击 APK 完成安装；升级时下载新版本直接覆盖安装即可

## 🛠️ 技术栈

| 类别 | 技术 | 用途 |
|------|------|------|
| 🦋 框架 | [Flutter](https://flutter.dev) | 跨平台 UI 与业务逻辑 |
| 💾 本地存储 | [SQFlite](https://pub.dev/packages/sqflite) + [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi) | 音效元数据持久化（桌面端通过 FFI） |
| 🔊 音频播放 | [audioplayers](https://pub.dev/packages/audioplayers) | 音效播放与时长探测 |
| ✂️ 音频处理 | [FFmpeg Kit](https://pub.dev/packages/ffmpeg_kit_flutter_new_audio) | 移动端 / macOS 内置片段截取（导出 M4A） |
| 🖥️ 系统 FFmpeg | 用户自行安装 | Windows / Linux 片段截取（需加入 PATH） |
| 📁 文件与设置 | file_picker、shared_preferences、path_provider | 选文件、偏好设置、应用目录 |
| 📦 自定义格式 | `.msb` 音效包 | 单包导入导出、备份与预览 |

## ✨ 功能概览

- 🎛️ **音效板**：网格展示音效，支持触觉反馈与「正在播放」高亮。
- ⭐ **分类与收藏**：系统分类（全部、收藏、默认）与自定义分类；可调整分类顺序。
- 🎧 **音频**：可选「同时播放」——开启后新点击的音效不会打断当前正在播放的音效（依赖系统混音能力）。
- ➕ **添加音效**：支持本地文件与链接；新增时可截取片段（导出为 M4A，详见下方平台差异表）。
- 📤 **导入 / 导出**：`.msb` 音效包与完整备份；任意导入路径（菜单选文件、系统「打开方式」、导出管理页）在继续操作前都会先显示统一的导入预览（类型、大小、导出时间、音效列表等）。
- 🗂️ **导出文件管理**：可查看与导入已导出的包；文件详情与导入预览同样展示包内音效列表。列表中的示例音效包为内置资源副本，界面标明不可删除。

## 🌐 跨平台兼容性

各平台能力以 Flutter 与插件实现为准，下表便于快速对号入座 👇

| 能力 | Android | iOS | Windows | macOS | Linux | Web |
|------|:-------:|:---:|:-------:|:-----:|:-----:|:---:|
| 音效播放 / 分类 / 收藏 / 搜索 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 音频片段截取 | ✅ 内置 FFmpeg Kit | ✅ 内置 FFmpeg Kit | ✅ 需系统 [FFmpeg](https://ffmpeg.org)（PATH） | ✅ 内置 FFmpeg Kit | ✅ 需系统 FFmpeg（如 `apt install ffmpeg`） | ❌ 不支持 |
| `.msb` 导入 / 导出 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 外部应用打开 `.msb`（打开方式 / 分享） | ✅ Android Intent | — | — | — | — | — |
| 打开系统文件管理器（导出目录） | ✅ | — | ✅ Explorer | ✅ Finder | ✅ xdg-open | — |

> 💡 **说明**：表格中「—」表示当前未实现或未专门适配，不代表完全不可用；Web 端主要限制在音频截取与部分原生集成能力。

## 📋 环境要求

- ✅ 已安装 [Flutter](https://docs.flutter.dev/get-started/install)（需满足 `pubspec.yaml` 中的 Dart SDK 约束，当前为 `^3.10`）。
- ⚙️ **Windows / Linux** 若需使用「截取片段」，请预先安装 FFmpeg 并确保命令行可执行 `ffmpeg`。
- 📥 克隆仓库后在项目根目录执行依赖安装与（可选）资源生成命令。

## 🚀 快速开始

```shell
flutter pub get
flutter run
```

### 🎨 可选：生成应用图标

若修改了 `pubspec.yaml` 中的 `flutter_launcher_icons` 配置，可执行：

```shell
dart run flutter_launcher_icons
```

## 📁 项目结构（简要）

| 路径 | 说明 |
|------|------|
| `lib/main.dart` | 🚪 入口：主题、竖屏、Windows 窗口尺寸等 |
| `lib/screens/` | 📱 主界面、设置、导出管理 |
| `lib/services/` | ⚙️ 数据库、音频、导入导出、设置持久化 |
| `lib/widgets/` | 🧩 音效按钮、搜索栏、`.msb` 导入预览/详情、弹窗等 |
| `assets/samples/` | 🎁 预制示例 `.msb` 音效包 |
| `docs/images/` | 🖼️ README 用 Logo 等资源 |

## 📄 许可证

本项目采用 [MIT License](LICENSE) 开源 📜

Copyright (c) 2026 刘德昊

您可以自由使用、修改与分发本软件，但须在副本中保留版权声明与许可全文。详见仓库根目录 [`LICENSE`](LICENSE) 文件。
