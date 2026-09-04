# Hướng Dẫn Sửa Lỗi Deploy LibreChat

## Các Lỗi Đã Sửa

### 1. ✅ Code Environments Lifecycle Race Condition
**Lỗi:** `Cannot call codeenvironments.updateMany() before initial connection is complete`

**Sửa:** Thêm xử lý lỗi để bỏ qua race condition khi khởi động trong `packages/api/src/code/lifecycle.ts`

```typescript
.catch((error) => {
  // Suppress connection race errors during startup
  if (error?.message?.includes('before initial connection is complete')) {
    return;
  }
  logger.error('[code-environments] lifecycle reconciliation failed:', error);
})
```

### 2. ✅ Test Files Loading Error
**Lỗi:** `jest is not defined` khi load `*.spec.js` files

**Sửa:** Bỏ qua test files trong `api/server/services/start/tools.js`

```javascript
// Skip test files and non-JS files
if (!file.endsWith('.js') || file.endsWith('.spec.js') || file.endsWith('.test.js') || ...) {
  continue;
}
```

### 3. ✅ Config File Version
**Lỗi:** `Outdated Config version: undefined`

**Sửa:** Cập nhật `librechat.yaml` từ version 1.1.5 lên 1.3.15

### 4. ⚠️ Scheduler Not Started (CẦN CẤU HÌNH)
**Lỗi:** `scheduler NOT started: this process cannot see other replicas' generations`

**Giải pháp:** Thêm biến môi trường sau vào Render:

## Cấu Hình Biến Môi Trường Render

Truy cập Render Dashboard → Your Service → Environment → Add Environment Variables:

### Bắt Buộc - Sửa Lỗi Scheduler

```bash
# Xác nhận deployment chạy single replica (không có Redis)
SCHEDULES_SINGLE_PROCESS=true
```

### Khuyến Nghị - Production Credentials

```bash
# Tạo credentials ngẫu nhiên an toàn (thay thế credentials tạm)
CREDS_KEY=<random-32-char-hex>
CREDS_IV=<random-32-char-hex>
JWT_SECRET=<random-256-char-string>
JWT_REFRESH_SECRET=<random-256-char-string>
```

**Tạo credentials ngẫu nhiên:**

```bash
# CREDS_KEY và CREDS_IV (32 hex chars)
openssl rand -hex 16

# JWT_SECRET và JWT_REFRESH_SECRET (256 chars)
openssl rand -base64 192
```

### Tùy Chọn - Tắt Warnings

```bash
# Tắt RAG API warning (nếu không dùng file uploads)
RAG_API_URL=disabled

# Enable social logins (nếu cần)
ALLOW_SOCIAL_LOGIN=false
```

## Các Lỗi Còn Lại (Không Nghiêm Trọng)

### 1. ⚠️ Credentials Warning
```
Active fingerprints do not match the database credential record
```

**Tác động:** Temporary credentials đang được dùng, không an toàn cho production.

**Giải pháp:** Thêm các biến CREDS_KEY, CREDS_IV, JWT_SECRET, JWT_REFRESH_SECRET như trên.

### 2. ℹ️ RAG API Warning
```
RAG API is either not running or not reachable at undefined
```

**Tác động:** File uploads có thể gặp lỗi.

**Giải pháp:** 
- Nếu không cần: Bỏ qua hoặc set `RAG_API_URL=disabled`
- Nếu cần: Deploy RAG API service riêng và cấu hình URL

## Kiểm Tra Sau Khi Deploy

1. **Service đã live:** ✅ `https://chat.nhanlee.dev`

2. **Kiểm tra logs không còn lỗi nghiêm trọng:**
```bash
# Trên Render Dashboard → Logs tab
# Không còn thấy:
# - "scheduler NOT started"
# - "jest is not defined"
# - "before initial connection is complete"
```

3. **Test chức năng:**
- Đăng nhập/đăng ký
- Tạo conversation
- Upload files (nếu dùng)
- Agent scheduling (nếu enable)

## Deployment Checklist

- [x] Sửa code environments race condition
- [x] Loại bỏ test files khỏi tool loading
- [x] Cập nhật config version
- [ ] **Set `SCHEDULES_SINGLE_PROCESS=true` trên Render**
- [ ] Set production credentials (CREDS_KEY, JWT_SECRET, etc.)
- [ ] Verify service hoạt động bình thường

## Notes

- Service đang chạy ở **single replica mode** - không scale horizontal được cho đến khi enable Redis
- Scheduler writes bị tắt (503) cho đến khi set `SCHEDULES_SINGLE_PROCESS=true`
- Social logins disabled - cần set `ALLOW_SOCIAL_LOGIN=true` nếu muốn enable

## Links Hữu Ích

- [LibreChat Docs](https://www.librechat.ai/docs)
- [Configuration Guide](https://www.librechat.ai/docs/configuration/librechat_yaml)
- [Environment Variables](https://www.librechat.ai/docs/configuration/dotenv)
