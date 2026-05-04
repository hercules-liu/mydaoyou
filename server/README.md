# 游伴服务器端

基于Node.js + Express的轻量级服务器，为游伴APP提供所有业务逻辑处理。

## 技术栈

- **Web框架**: Express.js
- **数据库**: MySQL 8.0
- **缓存**: Redis
- **实时通信**: Socket.IO
- **AI服务**: 阿里云图像识别、TTS、讯飞ASR、通义千问

## 快速开始

### 1. 安装依赖

```bash
cd server
npm install
```

### 2. 配置环境变量

```bash
cp .env.example .env
```

编辑`.env`文件，填入你的API密钥。

### 3. 初始化数据库

```bash
npm run init-db
```

### 4. 启动服务器

```bash
# 开发模式
npm run dev

# 生产模式
npm start
```

服务器将在 `http://localhost:8080` 启动。

## API接口

### 认证

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /api/auth/register | 注册 |
| POST | /api/auth/login | 登录 |
| POST | /api/auth/verify-code | 发送验证码 |

### 用户

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/user/profile | 获取个人信息 |
| PUT | /api/user/profile | 更新信息 |
| GET | /api/user/friends | 获取好友列表 |
| POST | /api/user/friends/add | 添加好友 |
| DELETE | /api/user/friends/:id | 删除好友 |

### 景点

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/spots/nearby | 附近景点 |
| GET | /api/spots/:id | 景点详情 |
| GET | /api/spots/search | 搜索景点 |

### 位置

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /api/location/update | 更新位置 |
| GET | /api/location/friends | 获取好友位置 |

### 对话

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /api/chat | 发送消息 |
| POST | /api/chat/asr | 语音识别 |
| GET | /api/chat/history | 获取历史 |

### 点评

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/comments/:spotId | 获取点评 |
| POST | /api/comments | 发布点评 |
| POST | /api/comments/:id/like | 点赞 |

### 路线

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/route/plan | 规划路线 |

## WebSocket事件

### 客户端 → 服务器

| 事件 | 说明 | 数据 |
|------|------|------|
| location_update | 上报位置 | `{lat, lng, timestamp}` |

### 服务器 → 客户端

| 事件 | 说明 | 数据 |
|------|------|------|
| spot_enter | 进入景点 | `{spotId, name, description}` |
| friend_location | 好友位置 | `{friendId, lat, lng}` |
| audio_play | 播放指令 | `{audio_url, text}` |

## 测试

```bash
npm test
```