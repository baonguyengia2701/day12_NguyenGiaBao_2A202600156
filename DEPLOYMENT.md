# Deployment Information

**Student:** Nguyễn Gia Bảo — 2A202600156

---

## Public URL

```
https://<your-app>.railway.app
```

*(Điền URL thật sau khi deploy — xem hướng dẫn bên dưới)*

## Platform

Railway

---

## Cách deploy (Railway)

```bash
# 1. Cài Railway CLI
npm i -g @railway/cli

# 2. Đăng nhập
railway login

# 3. Khởi tạo project (chạy từ thư mục 06-lab-complete)
cd 06-lab-complete
railway init

# 4. Set environment variables
railway variables set AGENT_API_KEY=<strong-random-key-here>
railway variables set ENVIRONMENT=production
railway variables set LOG_LEVEL=INFO
railway variables set RATE_LIMIT_PER_MINUTE=10

# 5. Deploy
railway up

# 6. Lấy domain
railway domain
```

---

## Environment Variables đã set trên cloud

| Variable | Value |
|----------|-------|
| `PORT` | Tự inject bởi Railway |
| `AGENT_API_KEY` | *(secret — không hiển thị)* |
| `ENVIRONMENT` | `production` |
| `LOG_LEVEL` | `INFO` |
| `RATE_LIMIT_PER_MINUTE` | `10` |
| `DAILY_BUDGET_USD` | `5.0` |

---

## Test Commands

### 1. Health Check
```bash
curl https://<your-app>.railway.app/health
```
**Expected response:**
```json
{"status":"ok","version":"1.0.0","environment":"production","uptime_seconds":42.1,...}
```

### 2. Authentication required (no key → 401)
```bash
curl -X POST https://<your-app>.railway.app/ask \
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
curl -X POST https://<your-app>.railway.app/ask \
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
    -X POST https://<your-app>.railway.app/ask \
    -H "X-API-Key: YOUR_AGENT_API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"question": "test"}'
done
```
**Expected:** Requests 1–10 trả `200`, từ request 11 trở đi trả `429 Too Many Requests`

---

## Screenshots

- `screenshots/railway-dashboard.png` — Railway project dashboard
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
