# 📅 OttiCalendar 后端接口对接手册 (V2.0 最新版)

此文档包含所有已实现的日程管理逻辑，请后端开发人员严格按照此规范进行接口开发与数据库变更。

## 1. 核心变更说明
*   **新增字段**: `isImportant` (Boolean)。用于标识日程是否为“重要”状态。
*   **字段名对齐**: 主键统一使用 `scheduleId` (String/UUID)。
*   **数据嵌套**: 所有响应体需统一包裹在 `ApiResponse` 中，列表数据放在 `data` 字段下。

---

## 2. 数据库变更建议
请在 `schedules` 表中新增以下字段：
*   `is_important` (或 `isImportant`): `TINYINT(1)` / `BOOLEAN`，默认值 `0` (False)。

---

## 3. 接口详细定义

### 3.1 创建日程 (Create)
*   **URL**: `POST /api/schedules`
*   **请求体 (Body)**:
```json
{
  "title": "项目复盘会议",
  "scheduleDate": "2026-01-14",
  "startTime": "14:30",
  "endTime": null,
  "location": "301会议室",
  "category": "工作", 
  "isAllDay": false,
  "isImportant": true, 
  "isAiGenerated": false
}
```
*   **分类枚举**: `工作`, `学习`, `个人`, `生活`, `健康`, `运动`, `社交`, `家庭`, `差旅`, `其他`

### 3.2 获取日程列表 (Read)
*   **URL**: `GET /api/schedules`
*   **参数**: `date=2026-01-14` (格式: YYYY-MM-DD)
*   **响应 (200)**:
```json
{
  "code": 200,
  "message": "获取成功",
  "data": [
    {
      "scheduleId": "uuid-12345",
      "title": "项目复盘会议",
      "scheduleDate": "2026-01-14",
      "startTime": "14:30",
      "location": "301会议室",
      "category": "工作",
      "isImportant": true,
      "isAllDay": false
    }
  ]
}
```

### 3.3 修改日程 (Update)
*   **URL**: `PUT /api/schedules/{scheduleId}`
*   **说明**: 请求体与 POST 一致，必须包含 `scheduleId`。
*   **请求体**:
```json
{
  "scheduleId": "uuid-12345",
  "title": "修改后的标题",
  "isImportant": false,
  "..." : "..."
}
```

### 3.4 删除日程 (Delete)
*   **URL**: `DELETE /api/schedules/{scheduleId}`
*   **响应 (200)**:
```json
{
  "code": 200,
  "message": "删除成功",
  "data": null
}
```

---

## 4. 身份认证 (Auth)
除登录注册外，所有请求头需携带：
`Authorization: Bearer {JWT_TOKEN}`

---

## 5. 前端逻辑提示 (给后端看)
1.  **右对齐显示**: 前端详情页所有内容已改为右对齐。
2.  **操作反馈**: 前端在接收到 `PUT` 或 `DELETE` 的 200 响应后，会弹出半透明提示框并自动刷新主页列表。
3.  **时间格式**: 前端会发送 `HH:mm` 格式的时间，请后端在返回时也保持此格式（或 `HH:mm:ss`，前端已做兼容）。
