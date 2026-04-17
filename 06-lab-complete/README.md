# Lab 12 — Complete Production Agent

Kết hợp TẤT CẢ những gì đã học trong 1 project hoàn chỉnh.

## Checklist Deliverable

- [x] Dockerfile (multi-stage, < 500 MB)
- [x] docker-compose.yml (agent + redis + nginx load balancer)
- [x] .dockerignore
- [x] Health check endpoint (`GET /health`)
- [x] Readiness endpoint (`GET /ready`)
- [x] API Key authentication
- [x] Rate limiting
- [x] Cost guard
- [x] Config từ environment variables
- [x] Structured logging
- [x] Graceful shutdown
- [x] Public URL ready (Railway / Render config)

---

## Cấu Trúc

```
06-lab-complete/
├── app/
│   ├── main.py         # Entry point — auth, rate limit, cost guard, health
│   └── config.py       # 12-factor config (env vars)
├── utils/
│   └── mock_llm.py     # Mock LLM (không cần API key thật)
├── Dockerfile          # Multi-stage, non-root, < 500 MB
├── docker-compose.yml  # agent (x3) + redis + nginx
├── nginx.conf          # Load balancer config
├── railway.toml        # Deploy Railway
├── render.yaml         # Deploy Render
├── .env.example        # Template — copy thành .env.local
├── .dockerignore
└── requirements.txt
```

---

## Chạy Local

```bash
# 1. Setup env file
cp .env.example .env.local
# Sửa AGENT_API_KEY trong .env.local thành giá trị bạn muốn

# 2. Chạy với Docker Compose (3 agent instances + nginx + redis)
docker compose up --build --scale agent=3

# 3. Test qua Nginx (port 80)
curl http://localhost/health

# 4. Test endpoint với API key
curl -H "X-API-Key: dev-key-change-me-in-production" \
     -X POST http://localhost/ask \
     -H "Content-Type: application/json" \
     -d '{"question": "What is deployment?"}'

# 5. Test rate limiting (gọi >10 lần → 429)
for i in $(seq 1 15); do
  curl -s -o /dev/null -w "Request $i: %{http_code}\n" \
    -X POST http://localhost/ask \
    -H "X-API-Key: dev-key-change-me-in-production" \
    -H "Content-Type: application/json" \
    -d '{"question": "test"}'
done
```

---

## Deploy Railway (< 5 phút)

```bash
# Cài Railway CLI
npm i -g @railway/cli

# Login và deploy
railway login
railway init
railway variables set OPENAI_API_KEY=sk-...
railway variables set AGENT_API_KEY=your-secret-key
railway up

# Nhận public URL!
railway domain
```

---

## Deploy Render

1. Push repo lên GitHub
2. Render Dashboard → New → Blueprint
3. Connect repo → Render đọc `render.yaml`
4. Set secrets: `OPENAI_API_KEY`, `AGENT_API_KEY`
5. Deploy → Nhận URL!

---

## Kiểm Tra Production Readiness

```bash
python check_production_ready.py
```

Script này kiểm tra tất cả items trong checklist và báo cáo những gì còn thiếu.
