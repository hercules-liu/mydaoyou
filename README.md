# 游伴 - 智能语音导游APP

## 开发环境要求

### 必需环境

| 工具 | 版本 | 说明 |
|------|------|------|
| Flutter | ≥3.0 | 跨平台APP框架 |
| Dart | ≥3.0 | Flutter语言 |
| Android SDK | ≥21 | Android构建 |
| Xcode | ≥14 | iOS构建(仅Mac) |
| Node.js | ≥18 | 后端服务 |

### 可选云服务API

| 服务 | 用途 | 申请地址 |
|------|------|----------|
| 高德地图 | 定位服务 | https://lbs.amap.com |
| 阿里云 | 图像识别+TTS | https://aliyun.com |
| 讯飞/百度 | 语音识别 | https://xfyun.cn |

## 快速开始

### 1. 安装Flutter

```bash
# Linux/macOS
git clone https://github.com/flutter/flutter.git
export PATH="$PATH:`pwd`/flutter/bin"

# Windows: 下载安装包
# https://docs.flutter.dev/get-started/install
```

### 2. 创建项目

```bash
cd /home/user/projects/mydaoyou
flutter create --org com.yooban --project-name youban .
```

### 3. 安装依赖

```bash
flutter pub get
```

### 4. 配置API Key

复制 `.env.example` 为 `.env`，填入你的API密钥

### 5. 运行项目

```bash
flutter run
```

## 项目结构

```
youban/
├── lib/
│   ├── main.dart              # 入口
│   ├── pages/                 # 页面
│   │   ├── home_page.dart     # 首页
│   │   ├── camera_page.dart   # 拍照讲解
│   │   ├── chat_page.dart     # 问答
│   │   └── footprint_page.dart# 足迹
│   ├── services/              # 服务
│   │   ├── location_service.dart
│   │   ├── tts_service.dart
│   │   ├── stt_service.dart
│   │   └── image_service.dart
│   ├── models/                # 数据模型
│   └── utils/                 # 工具
├── android/                   # Android原生
├── ios/                       # iOS原生
└── .env                       # API配置
```

## 开发状态

- [x] 需求分析
- [x] 设计文档
- [ ] 环境配置
- [ ] 项目初始化
- [ ] 核心功能开发