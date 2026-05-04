# 游伴服务器端 测试计划

## 1. 测试目标

验证服务器端所有API接口和业务逻辑的正确性，确保手机端与服务器端的交互正常。

## 2. 测试环境要求

- Node.js >= 18
- MySQL 8.0 (或MySQL模拟)
- Redis (或Redis模拟)

## 3. 测试用例

### 3.1 认证模块

| 用例ID | 用例描述 | 输入 | 预期输出 |
|--------|----------|------|----------|
| AUTH-01 | 注册新用户 | phone, code, nickname | 返回token, userId |
| AUTH-02 | 重复注册 | 已存在的phone | 返回错误"手机号已注册" |
| AUTH-03 | 登录成功 | 正确的phone, code | 返回token, userId |
| AUTH-04 | 登录失败 | 错误的phone | 返回错误"用户不存在" |
| AUTH-05 | 发送验证码 | phone | 返回成功，验证码日志输出 |
| AUTH-06 | 无效Token访问 | 伪造的token | 返回401未授权 |
| AUTH-07 | 过期Token访问 | 过期的token | 返回401 Token已过期 |

### 3.2 用户模块

| 用例ID | 用例描述 | 输入 | 预期输出 |
|--------|----------|------|----------|
| USER-01 | 获取个人资料 | 有效token | 返回用户信息 |
| USER-02 | 更新昵称 | 新nickname | 返回success |
| USER-03 | 更新头像 | 新avatar | 返回success |
| USER-04 | 获取好友列表 | 有效token | 返回好友数组(含位置) |
| USER-05 | 添加好友 | friendId | 返回success |
| USER-06 | 添加自己为好友 | 自己的userId | 返回错误"不能添加自己" |
| USER-07 | 删除好友 | friendId | 返回success |

### 3.3 景点模块

| 用例ID | 用例描述 | 输入 | 预期输出 |
|--------|----------|------|----------|
| SPOT-01 | 获取附近景点 | lat, lng, radius | 返回景点数组(含距离) |
| SPOT-02 | 无效坐标 | lat=null, lng=null | 返回400错误 |
| SPOT-03 | 获取景点详情 | spot_id | 返回景点完整信息 |
| SPOT-04 | 景点不存在 | 错误的spot_id | 返回404错误 |
| SPOT-05 | 搜索景点 | q=关键词 | 返回匹配的景点列表 |
| SPOT-06 | 距离排序 | lat, lng | 按距离升序排列 |

### 3.4 位置模块

| 用例ID | 用例描述 | 输入 | 预期输出 |
|--------|----------|------|----------|
| LOC-01 | 更新位置 | lat, lng | 返回success，存入数据库和Redis |
| LOC-02 | 无效坐标更新 | lat=null | 返回400错误 |
| LOC-03 | 获取好友位置 | 有效token | 返回好友位置数组 |

### 3.5 对话模块

| 用例ID | 用例描述 | 输入 | 预期输出 |
|--------|----------|------|----------|
| CHAT-01 | 发送消息 | message, context | 返回reply和audioUrl |
| CHAT-02 | 空消息发送 | message=null | 返回400错误 |
| CHAT-03 | 带景点上下文 | message+spotId | reply包含景点信息 |
| CHAT-04 | 语音识别 | audio_data | 返回识别文本 |
| CHAT-05 | 获取聊天历史 | spotId | 返回历史消息数组 |

### 3.6 点评模块

| 用例ID | 用例描述 | 输入 | 预期输出 |
|--------|----------|------|----------|
| CMNT-01 | 获取景点点评 | spot_id | 返回点评数组(含用户信息) |
| CMNT-02 | 发布点评 | content, rating, spotId | 返回commentId |
| CMNT-03 | 缺少必填字段 | rating=null | 返回400错误 |
| CMNT-04 | 点赞点评 | comment_id | success，like_count+1 |
| CMNT-05 | 取消点赞 | 已点赞的comment_id | success，like_count-1 |
| CMNT-06 | 重复点赞 | 已点赞的comment_id | 取消点赞 |

### 3.7 路线规划模块

| 用例ID | 用例描述 | 输入 | 预期输出 |
|--------|----------|------|----------|
| ROUTE-01 | 规划路线 | lat, lng | 返回路线节点数组+汇总 |
| ROUTE-02 | 无效坐标 | lat=null | 返回400错误 |
| ROUTE-03 | 限制数量 | limit=3 | 返回最多3个景点 |
| ROUTE-04 | 计算总距离 | lat, lng | 汇总包含totalDistance |
| ROUTE-05 | 计算总时间 | lat, lng | 汇总包含totalTimeMinutes |

### 3.8 WebSocket模块

| 用例ID | 用例描述 | 输入 | 预期输出 |
|--------|----------|------|----------|
| WS-01 | 有效Token连接 | 正确的token | 连接成功 |
| WS-02 | 无效Token连接 | 错误的token | 连接失败 |
| WS-03 | 位置更新 | location_update事件 | 存入数据库和Redis |
| WS-04 | 景点进入检测 | 进入景点范围内 | 触发spot_enter事件 |
| WS-05 | 断开连接 | disconnect事件 | 连接关闭 |

### 3.9 图像识别模块

| 用例ID | 用例描述 | 输入 | 预期输出 |
|--------|----------|------|----------|
| IMG-01 | 识别景点 | image_base64 | 返回spotId和置信度 |
| IMG-02 | 识别失败 | 无法匹配的图像 | 返回null或兜底结果 |

### 3.10 TTS语音合成模块

| 用例ID | 用例描述 | 输入 | 预期输出 |
|--------|----------|------|----------|
| TTS-01 | 文字转语音 | text | 返回audioUrl |
| TTS-02 | 空文本 | text=null | 返回错误或空结果 |

## 4. 测试执行顺序

1. 认证模块 (AUTH-*)
2. 用户模块 (USER-*)
3. 景点模块 (SPOT-*)
4. 位置模块 (LOC-*)
5. 对话模块 (CHAT-*)
6. 点评模块 (CMNT-*)
7. 路线模块 (ROUTE-*)
8. WebSocket (WS-*)
9. 图像识别 (IMG-*)
10. 语音合成 (TTS-*)

## 5. 通过标准

- 所有测试用例通过
- 无未捕获的异常
- 响应状态码正确
- 返回数据格式正确