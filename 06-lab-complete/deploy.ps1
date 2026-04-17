# deploy.ps1 — Chạy script này để deploy lên Railway
# Yêu cầu: Node.js, Railway CLI (npm i -g @railway/cli)

Write-Host "=== Day 12 Lab - Railway Deploy ===" -ForegroundColor Cyan

# Step 1: Login (mở browser)
Write-Host "`n[1/5] Logging in to Railway..." -ForegroundColor Yellow
railway login

# Step 2: Init project
Write-Host "`n[2/5] Initializing Railway project..." -ForegroundColor Yellow
railway init

# Step 3: Set environment variables
Write-Host "`n[3/5] Setting environment variables..." -ForegroundColor Yellow
$apiKey = Read-Host "Enter a strong AGENT_API_KEY (e.g. lab12-$(Get-Random -Minimum 10000 -Maximum 99999))"
railway variables set AGENT_API_KEY=$apiKey
railway variables set ENVIRONMENT=production
railway variables set LOG_LEVEL=INFO
railway variables set RATE_LIMIT_PER_MINUTE=10
railway variables set DAILY_BUDGET_USD=5.0

# Step 4: Deploy
Write-Host "`n[4/5] Deploying to Railway..." -ForegroundColor Yellow
railway up

# Step 5: Get domain
Write-Host "`n[5/5] Getting public domain..." -ForegroundColor Yellow
railway domain

Write-Host "`n=== Deploy complete! ===" -ForegroundColor Green
Write-Host "Your AGENT_API_KEY: $apiKey" -ForegroundColor Cyan
Write-Host "Save it — you need it to call /ask endpoint" -ForegroundColor Cyan
