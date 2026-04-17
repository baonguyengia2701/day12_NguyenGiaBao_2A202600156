# Day 12 Lab - Mission Answers

**Student Name:** Nguyễn Gia Bảo  
**Student ID:** 2A202600156  
**Date:** 17/04/2026

---

## Part 1: Localhost vs Production

### Exercise 1.1: Anti-patterns found in `01-localhost-vs-production/develop/app.py`

1. **API key hardcode trong code** (dòng 17-18): `OPENAI_API_KEY = "sk-hardcoded-fake-key-never-do-this"` và `DATABASE_URL = "postgresql://admin:password123@localhost/mydb"`. Nếu push lên GitHub, key bị lộ ngay lập tức cho bất kỳ ai xem repo.

2. **Port cố định — không đọc từ environment** (dòng 48-49): `port=8000` được viết thẳng thay vì `int(os.getenv("PORT", 8000))`. Railway/Render inject PORT qua env var, nếu cứng port app sẽ không nhận được traffic.

3. **Debug mode bật trong production** (dòng 50): `reload=True` khiến uvicorn tự reload khi code thay đổi — rủi ro bảo mật và hiệu năng kém trong production.

4. **Không có health check endpoint**: Không có `/health`. Platform cloud không biết container còn sống hay đã crash, dẫn đến không tự động restart.

5. **Print thay vì proper logging** (dòng 33-35): Dùng `print()` ra stdout với nội dung bao gồm cả `OPENAI_API_KEY`. Không có log level, không có structured format, không thể filter hay parse.

6. **Binding trên `localhost`** (dòng 47): `host="localhost"` khiến app chỉ nhận kết nối từ bên trong máy, không nhận được traffic từ bên ngoài container.

### Exercise 1.3: So sánh Develop vs Production

| Feature | Develop (`develop/app.py`) | Production (`production/app.py`) | Tại sao quan trọng? |
|---------|--------------------------|----------------------------------|---------------------|
| Config | Hardcode trong code | Đọc từ env vars qua `config.py` / `Settings` | Tránh lộ secret, dễ thay đổi giữa môi trường không cần sửa code |
| Health check | Không có | `/health` (liveness) + `/ready` (readiness) | Platform cloud dùng để biết khi nào restart container hoặc dừng route traffic |
| Logging | `print()` — in cả secret ra stdout | JSON structured logging với `logging` module | Dễ parse bởi log aggregator (Datadog, Loki), có log level, không lộ secret |
| Shutdown | Đột ngột (SIGTERM kill ngay) | Graceful — `lifespan` đợi request hiện tại xong, đóng connection | Request đang xử lý không bị cắt đứt giữa chừng |
| Host binding | `localhost` — chỉ trong máy | `0.0.0.0` — nhận từ bên ngoài container | Container cần bind 0.0.0.0 để nhận traffic từ Nginx / Internet |
| Port | Cứng `8000` | Đọc từ `PORT` env var | Railway/Render inject PORT động, app cần đọc từ env để nhận được traffic |
| Debug mode | `reload=True` luôn | `reload=settings.debug` — chỉ bật khi DEBUG=true | Reload trong production tốn tài nguyên và là rủi ro bảo mật |

---

## Part 2: Docker

### Exercise 2.1: Câu hỏi về `02-docker/develop/Dockerfile`

1. **Base image là gì?**  
   `python:3.11` — full Python distribution (~1 GB). Bao gồm toàn bộ Python runtime, pip, và các công cụ hệ thống.

2. **Working directory là gì?**  
   `/app` — được đặt bằng lệnh `WORKDIR /app`. Tất cả lệnh `COPY`, `RUN` sau đó đều thực thi trong thư mục này.

3. **Tại sao COPY requirements.txt trước?**  
   Docker build theo từng layer. Nếu `requirements.txt` không thay đổi, Docker dùng cache layer cài dependencies mà không cần chạy lại `pip install`. Chỉ khi code thay đổi (COPY . .) layer đó mới rebuild — giảm thời gian build đáng kể.

4. **CMD vs ENTRYPOINT khác nhau thế nào?**  
   - `CMD` là lệnh mặc định nhưng có thể bị override khi `docker run <image> <other-command>`  
   - `ENTRYPOINT` là lệnh cố định không bị override, `CMD` trở thành argument cho ENTRYPOINT  
   - Ví dụ: `ENTRYPOINT ["python"]` + `CMD ["app.py"]` → `docker run image script.py` sẽ chạy `python script.py`

### Exercise 2.3: So sánh image size

| Image | Build type | Size (ước tính) |
|-------|-----------|----------------|
| `my-agent:develop` | Single-stage (`python:3.11`) | ~1.1 GB |
| `my-agent:production` | Multi-stage (`python:3.11-slim`) | ~200–300 MB |
| Chênh lệch | | ~70–75% nhỏ hơn |

**Lý do image production nhỏ hơn:**
- Stage 1 (builder) dùng `python:3.11-slim` + cài dependencies với `--user` vào `/root/.local`
- Stage 2 (runtime) dùng `python:3.11-slim` fresh, chỉ copy `/root/.local` (packages) và source code
- Không copy gcc, build tools, apt cache sang runtime → image sạch và nhỏ

### Exercise 2.4: Docker Compose architecture (`02-docker/production/docker-compose.yml`)

Services được start:
- **agent** — FastAPI AI agent, 2 workers, không expose port ra ngoài trực tiếp
- **redis** — Cache cho session, rate limiting, healthcheck bằng `redis-cli ping`
- **qdrant** — Vector database cho RAG, healthcheck qua HTTP
- **nginx** — Reverse proxy + load balancer, expose port 80 và 443 ra ngoài

Cách các services communicate:
- Tất cả cùng network `internal` (bridge)
- Nginx nhận request từ Internet (port 80/443), forward đến `agent:8000`
- Agent connect đến `redis:6379` và `qdrant:6333` bằng DNS name của container
- Redis và Qdrant không expose port ra ngoài — chỉ agent mới truy cập được

---

## Part 3: Cloud Deployment

### Exercise 3.1: Railway deployment

- **URL:** *(điền sau khi deploy — xem DEPLOYMENT.md)*
- **Screenshot:** xem `screenshots/railway-dashboard.png`

**Steps thực hiện:**
```bash
npm i -g @railway/cli
railway login
railway init
railway variables set AGENT_API_KEY=<strong-random-key>
railway variables set ENVIRONMENT=production
railway up
railway domain
```

### Exercise 3.2: So sánh `render.yaml` vs `railway.toml`

| Điểm khác nhau | `railway.toml` | `render.yaml` |
|----------------|----------------|---------------|
| Format | TOML | YAML |
| Redis | Phải add service riêng trong dashboard | Khai báo inline trong cùng file (`type: redis`) |
| AGENT_API_KEY | Set qua CLI `railway variables set` | `generateValue: true` — Render tự sinh key |
| Build | `builder = "DOCKERFILE"` | `buildCommand: pip install -r requirements.txt` |
| Env vars từ service khác | Phải link thủ công | `fromService` — tự lấy connection string của Redis |

---

## Part 4: API Security

### Exercise 4.1: API Key authentication (`04-api-gateway/develop/app.py`)

- **API key được check ở đâu?** Trong dependency function `verify_api_key()` (dòng 42–52), được inject vào endpoint `/ask` qua `Depends(verify_api_key)`.
- **Điều gì xảy ra nếu sai key?** Raise `HTTPException(status_code=403, detail="Invalid API key.")`. Nếu thiếu key hoàn toàn → `HTTPException(401)`.
- **Làm sao rotate key?** Thay đổi giá trị env var `AGENT_API_KEY` và restart container. Không cần sửa code.

**Test output:**
```
# Không có key → 401
$ curl http://localhost:8000/ask -X POST -H "Content-Type: application/json" -d '{"question":"Hello"}'
{"detail":"Missing API key. Include header: X-API-Key: <your-key>"}

# Có key → 200
$ curl http://localhost:8000/ask -X POST -H "X-API-Key: demo-key-change-in-production" -H "Content-Type: application/json" -d '{"question":"Hello"}'
{"question":"Hello","answer":"Agent đang hoạt động tốt! (mock response) Hỏi thêm câu hỏi đi nhé."}
```

### Exercise 4.2: JWT flow (`04-api-gateway/production/auth.py`)

1. User POST `/auth/token` với username/password → server verify → trả về JWT token (HS256, hết hạn 60 phút)
2. User gửi request đến `/ask` với header `Authorization: Bearer <token>`
3. `verify_token()` decode JWT, kiểm tra signature và expiry → trả về payload (username, role)
4. Nếu token sai/hết hạn → 401

### Exercise 4.3: Rate limiting (`04-api-gateway/production/rate_limiter.py`)

- **Algorithm:** Sliding window (dùng Redis sorted set — `zremrangebyscore`, `zcard`, `zadd`)
- **Limit:** 10 requests/minute cho user thường, 100 req/min cho admin
- **Bypass cho admin:** Role `admin` dùng `rate_limiter_admin` instance với limit cao hơn

**Test output (sau khi gọi quá 10 lần):**
```
{"detail":"Rate limit exceeded. Try again in 60 seconds.","headers":{"Retry-After":"60"}}
HTTP 429 Too Many Requests
```

### Exercise 4.4: Cost guard implementation

Logic đã implement (xem `04-api-gateway/production/cost_guard.py` và `06-lab-complete/app/main.py`):

```python
def check_budget(user_id: str, estimated_cost: float) -> bool:
    month_key = datetime.now().strftime("%Y-%m")
    key = f"budget:{user_id}:{month_key}"
    current = float(r.get(key) or 0)
    if current + estimated_cost > 10:
        return False
    r.incrbyfloat(key, estimated_cost)
    r.expire(key, 32 * 24 * 3600)  # 32 ngày
    return True
```

Approach: Dùng Redis key `budget:<user_id>:<YYYY-MM>` để track chi tiêu theo tháng. Key tự expire sau 32 ngày → tự động reset đầu tháng tiếp. Cost ước tính dựa trên số token input/output.

---

## Part 5: Scaling & Reliability

### Exercise 5.1: Health checks

```python
@app.get("/health")
def health():
    """Liveness probe — container còn sống không?"""
    return {"status": "ok", "uptime_seconds": round(time.time() - START_TIME, 1)}

@app.get("/ready")
def ready():
    """Readiness probe — sẵn sàng nhận traffic không?"""
    if not _is_ready:
        raise HTTPException(503, "Not ready")
    return {"ready": True}
```

**Phân biệt liveness vs readiness:**
- `/health` (liveness): "Container còn sống không?" — platform restart nếu fail
- `/ready` (readiness): "Sẵn sàng nhận traffic chưa?" — load balancer dừng route nếu fail (ví dụ: đang khởi động, đang shutdown)

### Exercise 5.2: Graceful shutdown

```python
@asynccontextmanager
async def lifespan(app: FastAPI):
    global _is_ready
    _is_ready = True
    yield
    # Shutdown phase: đánh dấu not ready, đợi request xong
    _is_ready = False
    logger.info("Graceful shutdown initiated — finishing in-flight requests")

signal.signal(signal.SIGTERM, lambda s, f: logger.info(f"SIGTERM received: {s}"))
```

Khi nhận SIGTERM: uvicorn bắt signal → trigger lifespan shutdown → `_is_ready = False` → load balancer ngừng route request mới → các request đang xử lý hoàn thành → container thoát sạch.

### Exercise 5.3: Stateless design

**Anti-pattern (state trong memory):**
```python
conversation_history = {}  # bị mất khi restart, không chia sẻ giữa instances

@app.post("/ask")
def ask(user_id: str, question: str):
    history = conversation_history.get(user_id, [])
```

**Correct (state trong Redis):**
```python
@app.post("/chat")
async def chat(body: ChatRequest):
    session_id = body.session_id or str(uuid.uuid4())
    history = load_session(session_id)  # đọc từ Redis
    answer = ask(body.question)
    append_to_history(session_id, "assistant", answer)  # lưu vào Redis
```

**Tại sao stateless quan trọng khi scale:** Khi chạy 3 instances, request 1 có thể đến Instance A, request 2 có thể đến Instance B. Nếu history trong memory của A thì B không biết → session bị vỡ. Redis là shared storage cho mọi instance.

### Exercise 5.4: Load balancing với Nginx

Chạy `docker compose up --scale agent=3`:
- Docker Compose start 3 container agent với tên `agent-1`, `agent-2`, `agent-3`
- Nginx upstream `agent_cluster` dùng round-robin phân tán request
- Mỗi request được ghi log `served_by: instance-<id>` khác nhau
- Nếu 1 instance fail health check → Nginx tự loại khỏi pool, chuyển sang 2 instance còn lại

### Exercise 5.5: Test stateless

`test_stateless.py` kiểm chứng:
1. Tạo conversation với instance đầu tiên (session_id được trả về)
2. Kill instance đó (`docker stop agent-1`)
3. Gửi request tiếp theo với cùng session_id → instance khác nhận
4. Conversation history vẫn còn (đọc từ Redis) → stateless design hoạt động đúng
