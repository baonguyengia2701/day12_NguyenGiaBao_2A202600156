# Deployment Information

**Student:** Nguyễn Gia Bảo — 2A202600156

---

## Public URL

```
https://ai-agent-production-5g0u.onrender.com/
```

Đã deploy thành công trên Render bằng Blueprint.

## Platform

Render

---

## Cách deploy (Render Blueprint)

```bash
# 1. Push repository lên GitHub
# 2. Render Dashboard -> New -> Blueprint
# 3. Chọn branch: main
# 4. Blueprint Path: 06-lab-complete/render.yaml
# 5. Set secrets: OPENAI_API_KEY, AGENT_API_KEY
# 6. Deploy và nhận URL *.onrender.com
```

---

## Environment Variables đã set trên cloud

| Variable | Value |
|----------|-------|
| `PORT` | Tự inject bởi Render |
| `OPENAI_API_KEY` | *(secret — không hiển thị)* |
| `AGENT_API_KEY` | *(secret — không hiển thị)* |
| `ENVIRONMENT` | `production` |
| `APP_VERSION` | `1.0.0` |
| `RATE_LIMIT_PER_MINUTE` | `20` |
| `DAILY_BUDGET_USD` | `5.0` |
| `JWT_SECRET` | `generateValue: true` |

---

## Test Commands

### 1. Health Check
```bash
curl https://ai-agent-production-5g0u.onrender.com/health
```
**Expected response:**
```json
{"status":"ok","version":"1.0.0","environment":"production","uptime_seconds":42.1,...}
```

### 2. Authentication required (no key → 401)
```bash
curl -X POST https://ai-agent-production-5g0u.onrender.com/ask \
  -H "Content-Type: application/json" \
  -d '{"question": "Hello"}'
```
**Expected response:**
```json
{"detail":"Invalid or missing API key. Include header: X-API-Key: <key>"}
```
HTTP Status: `401 Unauthorized`

### 3. With API key → 200
```bash
curl -X POST https://ai-agent-production-5g0u.onrender.com/ask \
  -H "X-API-Key: YOUR_AGENT_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"question": "Hello, what is Docker?"}'
```
**Expected response:**
```json
{
  "question": "Hello, what is Docker?",
  "answer": "Container là cách đóng gói app để chạy ở mọi nơi. Build once, run anywhere!",
  "model": "gpt-4o-mini",
  "timestamp": "2026-04-17T..."
}
```

### 4. Rate limiting → 429
```bash
for i in $(seq 1 15); do
  curl -s -o /dev/null -w "Request $i: %{http_code}\n" \
    -X POST https://ai-agent-production-5g0u.onrender.com/ask \
    -H "X-API-Key: YOUR_AGENT_API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"question": "test"}'
done
```
**Expected:** Request trong hạn mức trả `200`, vượt hạn mức trả `429 Too Many Requests`.

---

## Screenshots

- `screenshots/render-dashboard.png` — Render project dashboard
- `screenshots/service-running.png` — Service đang chạy (healthy)
- `screenshots/test-health.png` — Kết quả curl /health
- `screenshots/test-auth.png` — Test 401 và 200
- `screenshots/test-rate-limit.png` — Test 429

---

## Local Development (Docker Compose)

```bash
cd 06-lab-complete

# Copy env file và điền key
cp .env.example .env.local
# Sửa AGENT_API_KEY trong .env.local

# Build và chạy với 3 agent instances + Nginx
docker compose up --build --scale agent=3

# Test qua Nginx (port 80)
curl http://localhost/health
curl -X POST http://localhost/ask \
  -H "X-API-Key: dev-key-change-me-in-production" \
  -H "Content-Type: application/json" \
  -d '{"question": "Hello"}'
```
