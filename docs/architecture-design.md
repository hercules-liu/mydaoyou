# 游伴APP 架构设计文档

## 1. 架构概述

采用**轻客户端 + 重服务端**架构，手机端专注于数据采集和语音输出，所有业务逻辑集中在服务器端处理。

```
┌─────────────────┐                    ┌─────────────────┐
│                 │                    │                 │
│   手机端APP     │ ◄────REST API────► │   服务器端      │
│                 │                    │                 │
│  ┌───────────┐  │     ◄────WS────►  │  ┌───────────┐  │
│  │ 数据采集  │  │                    │  │ 业务逻辑   │  │
│  │ - GPS     │  │                    │  │ - 图像识别 │  │
│  │ - 摄像头  │  │                    │  │ - NLP/NLU  │  │
│  │ - 麦克风  │  │                    │  │ - 对话管理 │  │
│  └───────────┘  │                    │  │ - 路线规划 │  │
│                 │                    │  └───────────┘  │
│  ┌───────────┐  │                    │                 │
│  │ 语音输出  │  │                    │  ┌───────────┐  │
│  │ - TTS     │  │                    │  │ 数据存储   │  │
│  │ - 播放控制│  │                    │  │ - MySQL    │  │
│  └───────────┘  │                    │  │ - Redis    │  │
│                 │                    │  └───────────┘  │
└─────────────────┘                    └─────────────────┘
```

## 2. 功能划分

### 2.1 手机端职责（轻量级）

| 功能模块 | 职责 | 说明 |
|---------|------|------|
| 定位采集 | GPS数据采集、上传 | 每5秒上报一次位置 |
| 图像采集 | 拍照、视频流推送 | 按需拍摄，不持续录像 |
| 语音采集 | 麦克风音频流 | 语音问答时采集 |
| 语音播放 | TTS音频播放 | 接收服务器返回的音频URL |
| 本地缓存 | 景点数据缓存 | 减少网络请求 |
| UI交互 | 页面展示、用户操作 | 纯展示层 |

### 2.2 服务器端职责（重量级）

| 功能模块 | 职责 | 说明 |
|---------|------|------|
| 用户管理 | 注册、登录、好友关系 | 用户体系 |
| 景点管理 | 景点数据CRUD、搜索 | 景点数据库 |
| 定位服务 | 景点进入检测、地理围栏 | 判断用户是否进入景点 |
| 图像识别 | 景点识别、特征匹配 | 调用阿里云图像分析 |
| 语音识别(ASR) | 语音转文字 | 调用讯飞/百度ASR |
| 自然语言理解(NLU) | 意图识别、实体提取 | 解析用户query |
| 对话管理 | 多轮对话状态管理 | 维护对话上下文 |
| 回答生成 | LLM生成回复 | 调用通义千问/GPT |
| 语音合成(TTS) | 文字转语音 | 调用阿里云TTS |
| 路线规划 | 最优路径计算 | 基于当前位置推荐 |
| 同伴位置 | 位置同步、实时推送 | WebSocket推送 |
| 点评管理 | 点评CRUD、点赞 | 好友点评 |

## 3. 通信接口设计

### 3.1 REST API

#### 用户相关

| 方法 | 路径 | 说明 | 请求体 | 响应 |
|------|------|------|--------|------|
| POST | /api/auth/register | 注册 | `{phone, code, nickname}` | `{token, user_id}` |
| POST | /api/auth/login | 登录 | `{phone, code}` | `{token, user_id}` |
| GET | /api/user/profile | 获取个人信息 | - | `{user_id, nickname, avatar}` |
| PUT | /api/user/profile | 更新信息 | `{nickname, avatar}` | `{success}` |
| GET | /api/friends | 获取好友列表 | - | `[{friend_id, name, location, last_update}]` |
| POST | /api/friends/add | 添加好友 | `{friend_id}` | `{success}` |
| DELETE | /api/friends/{id} | 删除好友 | - | `{success}` |

#### 景点相关

| 方法 | 路径 | 说明 | 请求体 | 响应 |
|------|------|------|--------|------|
| GET | /api/spots/nearby | 附近景点 | `?lat=&lng=&radius=` | `[{spot_id, name, distance}]` |
| GET | /api/spots/{id} | 景点详情 | - | `{name, description, images, tags}` |
| GET | /api/spots/search | 搜索景点 | `?q=` | `[{spot_id, name}]` |

#### 位置相关

| 方法 | 路径 | 说明 | 请求体 | 响应 |
|------|------|------|--------|------|
| POST | /api/location/update | 更新位置 | `{lat, lng, timestamp}` | `{success}` |
| GET | /api/location/friends | 获取好友位置 | - | `[{friend_id, lat, lng, timestamp}]` |

#### 图像识别

| 方法 | 路径 | 说明 | 请求体 | 响应 |
|------|------|------|--------|------|
| POST | /api/recognize | 识别景点 | `{image_base64}` | `{spot_id, name, confidence}` |
| POST | /api/image/upload | 上传图片 | `{image_data}` | `{image_url}` |

#### 对话相关

| 方法 | 路径 | 说明 | 请求体 | 响应 |
|------|------|------|--------|------|
| POST | /api/chat | 发送消息 | `{message, context}` | `{reply_text, audio_url}` |
| POST | /api/asr | 语音识别 | `{audio_data, format}` | `{text}` |
| GET | /api/tts/{text_id} | 获取TTS音频 | - | `{audio_url}` |

#### 点评相关

| 方法 | 路径 | 说明 | 请求体 | 响应 |
|------|------|------|--------|------|
| GET | /api/comments/{spot_id} | 获取点评 | - | `[{comment_id, content, rating}]` |
| POST | /api/comments | 发布点评 | `{spot_id, content, rating, images}` | `{comment_id}` |
| POST | /api/comments/{id}/like | 点赞 | - | `{success}` |

#### 路线相关

| 方法 | 路径 | 说明 | 请求体 | 响应 |
|------|------|------|--------|------|
| GET | /api/route/plan | 规划路线 | `?lat=&lng=` | `[{order, spot_id, distance, time}]` |

### 3.2 WebSocket 实时通信

| 事件 | 方向 | 说明 | 数据格式 |
|------|------|------|----------|
| `location_update` | Client→Server | 上报位置 | `{lat, lng, timestamp}` |
| `friend_location` | Server→Client | 推送好友位置 | `{friend_id, lat, lng}` |
| `spot_enter` | Server→Client | 进入景点通知 | `{spot_id, name}` |
| `audio_play` | Server→Client | 播放语音指令 | `{audio_url, text}` |

### 3.3 通信流程

#### 语音问答流程

```
手机                           服务器
  │                              │
  │ ────── 语音音频 ────────────► │
  │                              │
  │    ASR: 语音→文字            │
  │                              │
  │    NLU: 意图识别             │
  │                              │
  │    对话管理: 上下文          │
  │                              │
  │    LLM: 生成回复             │
  │                              │
  │    TTS: 文字→语音            │
  │                              │
  │ ◄──── 音频URL ─────────────  │
  │                              │
  │  播放音频                     │
```

#### 定位讲解流程

```
手机                           服务器
  │                              │
  │ ────── GPS位置(5s间隔) ────► │
  │                              │
  │    检测进入景点范围           │
  │                              │
  │ ◄──── 景点信息 ───────────── │
  │                              │
  │    拉取景点讲解               │
  │                              │
  │ ◄──── 讲解文本+音频URL ──── │
  │                              │
  │  自动播放讲解                 │
```

## 4. 数据模型

### 4.1 数据库设计

```sql
-- 用户表
CREATE TABLE users (
    id VARCHAR(32) PRIMARY KEY,
    phone VARCHAR(20) UNIQUE NOT NULL,
    nickname VARCHAR(50),
    avatar VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 好友关系表
CREATE TABLE friendships (
    user_id VARCHAR(32),
    friend_id VARCHAR(32),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, friend_id)
);

-- 用户位置表
CREATE TABLE user_locations (
    user_id VARCHAR(32),
    latitude DOUBLE NOT NULL,
    longitude DOUBLE NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id)
);

-- 景点表
CREATE TABLE spots (
    id VARCHAR(32) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    latitude DOUBLE NOT NULL,
    longitude DOUBLE NOT NULL,
    radius INT DEFAULT 100,
    tags JSON,
    suggested_duration INT DEFAULT 3600,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 点评表
CREATE TABLE comments (
    id VARCHAR(32) PRIMARY KEY,
    spot_id VARCHAR(32),
    user_id VARCHAR(32),
    content TEXT NOT NULL,
    rating DECIMAL(2,1) NOT NULL,
    images JSON,
    like_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (spot_id) REFERENCES spots(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- 点评点赞表
CREATE TABLE comment_likes (
    user_id VARCHAR(32),
    comment_id VARCHAR(32),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, comment_id)
);

-- 足迹表
CREATE TABLE footprints (
    user_id VARCHAR(32),
    spot_id VARCHAR(32),
    visited_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    has_played BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (user_id, spot_id)
);

-- 对话历史表
CREATE TABLE chat_history (
    id VARCHAR(32) PRIMARY KEY,
    user_id VARCHAR(32),
    spot_id VARCHAR(32),
    role ENUM('user', 'assistant'),
    content TEXT,
    audio_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 4.2 Redis缓存设计

| Key | 类型 | 说明 | TTL |
|-----|------|------|-----|
| `user:{id}:token` | String | 用户Token | 7天 |
| `user:{id}:location` | Hash | 用户位置 | 5分钟 |
| `spot:{id}:info` | Hash | 景点信息 | 1小时 |
| `friends:{id}:locations` | Hash | 好友位置 | 1分钟 |
| `session:{id}:context` | Hash | 对话上下文 | 30分钟 |

## 5. 服务器技术栈

| 组件 | 技术选型 | 说明 |
|------|----------|------|
| Web框架 | Node.js + Express | 高并发、低延迟 |
| 数据库 | MySQL 8.0 | 关系数据存储 |
| 缓存 | Redis | 会话缓存、实时数据 |
| AI服务 | 阿里云 | 图像识别、TTS |
| ASR/NLU | 讯飞/百度 | 语音识别、意图理解 |
| LLM | 通义千问 | 对话生成 |
| WebSocket | Socket.IO | 实时通信 |
| 部署 | Docker | 容器化部署 |

## 6. 安全设计

| 安全措施 | 说明 |
|---------|------|
| Token认证 | JWT token，7天有效期 |
| HTTPS | 全链路加密 |
| 请求签名 | 防止篡改 |
| 限流 | 防止DDoS |
| 数据脱敏 | 敏感信息保护 |

## 7. 性能优化

| 优化策略 | 说明 |
|---------|------|
| 本地缓存 | 手机端缓存热门景点数据 |
| 请求合并 | 批量获取好友位置 |
| CDN加速 | 静态资源、图片、音频 |
| 数据库索引 | 位置查询加索引 |
| WebSocket压缩 | 减少传输量 |