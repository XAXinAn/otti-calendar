# 📅 OttiCalendar 后端接口对接手册 (V2.0 完整版)

此文档汇总了当前前端已实现的所有 Service 层接口逻辑，请后端开发人员严格对齐。

## 1. 全局规范
*   **Base URL**: `http://192.168.43.227:8080` (暂定)
*   **认证**: 除登录/注册外，所有请求需携带 `Authorization: Bearer {Token}`
*   **响应格式**:
```json
{
  "code": 200,      // 成功为 200，失败为 500 或其他
  "message": "描述",
  "data": { ... }   // 实际数据
}
```

---

## 2. 用户与认证 (AuthService)

### 2.1 登录
*   **POST** `/api/auth/login`
*   **Body**: `{"phone": "...", "password": "..."}`

### 2.2 注册
*   **POST** `/api/auth/register`
*   **Body**: `{"phone": "...", "password": "..."}`

### 2.3 更新个人信息
*   **PUT** `/api/auth/profile`
*   **Body**: `{"username": "...", "nickname": "...", "avatar": "..."}`

---

## 3. 日程管理 (ScheduleService)

### 3.1 创建日程
*   **POST** `/api/schedules`
*   **Body**:
```json
{
  "title": "会议",
  "scheduleDate": "2024-11-20",
  "startTime": "14:30",
  "endTime": "15:30",
  "location": "A302",
  "category": "工作",
  "isAllDay": false,
  "isImportant": true,
  "groupId": "uuid-xxx" (可选，归属群组)
}
```

### 3.2 按日查询日程
*   **GET** `/api/schedules?date=2024-11-20`
*   **逻辑说明**: 需返回用户个人的日程以及其加入的群组中同步到该日期的日程。

### 3.3 修改/删除日程
*   **PUT** `/api/schedules/{scheduleId}`
*   **DELETE** `/api/schedules/{scheduleId}`

---

## 4. 群组协作 (GroupService)

### 4.1 创建群组
*   **POST** `/api/groups`
*   **Body**: `{"name": "群名称", "description": "描述"}`
*   **返回**: 包含 `inviteCode` (6位邀请码)

### 4.2 加入群组
*   **POST** `/api/groups/join`
*   **Body**: `{"inviteCode": "邀请码"}`

### 4.3 群组列表
*   **GET** `/api/groups/created` (我创建的)
*   **GET** `/api/groups/joined` (我加入的)

### 4.4 成员管理
*   **GET** `/api/groups/{groupId}/members` (获取成员列表)
*   **DELETE** `/api/groups/{groupId}/members` (Body: `{"userIds": []}`, 踢出成员)
*   **PUT** `/api/groups/{groupId}/members/{userId}/role` (Body: `{"role": "ADMIN"}`, 修改权限)

### 4.5 退出/解散
*   **POST** `/api/groups/{groupId}/quit` (成员退出)
*   **DELETE** `/api/groups/{groupId}` (群主解散)

---

## 5. 语音与 OCR (原生插件/OCRService)

### 5.1 OCR 文字识别 (PaddleOCR)
*   **说明**: 前端通过原生插件调用，识别完成后会将文字作为字符串填入“一键记录”输入框。
*   **后端配合**: 若未来改为后端识别，接口为 `POST /api/ocr/recognize`，接收图片文件。

---

## 6. 数据统计 (StatisticsPage - 规划中接口)

### 6.1 范围日程查询 (待实现)
*   **GET** `/api/schedules/range?startDate=...&endDate=...`
*   **用途**: 用于渲染统计图表（饼图、趋势图）。
