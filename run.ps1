# --- NeutronAPI One-Click Runner (Windows) ---
# Project: https://github.com/8w6s/ds2api

$Host.UI.RawUI.WindowTitle = "NeutronAPI - Easy Runner"

# Màu sắc
function Write-Cyan { Write-Host $args -ForegroundColor Cyan }
function Write-Green { Write-Host $args -ForegroundColor Green }
function Write-Yellow { Write-Host $args -ForegroundColor Yellow }
function Write-Red { Write-Host $args -ForegroundColor Red }

Write-Cyan @"
    _   __              __                       ___     ____  ____
   / | / /__  __  __   / /__________  ____      /   |   / __ \/  _/
  /  |/ / _ \/ / / /  / __/ ___/ __ \/ __ \    / /| |  / /_/ // /  
 / /|  /  __/ /_/ /  / /_/ /  / /_/ / / / /   / ___ | / ____// /   
/_/ |_/\___/\__,_/   \__/_/   \____/_/ /_/   /_/  |_|/_/    /___/  
"@

Write-Green ">>> NeutronAPI is initializing..."

# 1. Kiểm tra Go
if (!(Get-Command go -ErrorAction SilentlyContinue)) {
    Write-Red "Error: Go is not installed. Please install Go from https://golang.org/dl/"
    pause
    exit
}

# 2. Tạo config nếu chưa có
if (!(Test-Path "config.json")) {
    Write-Yellow ">>> config.json not found, creating from example..."
    Copy-Item "config.example.json" "config.json"
}

if (!(Test-Path ".env")) {
    Write-Yellow ">>> .env not found, generating a secure one..."
    Copy-Item ".env.example" ".env"
    
    # Sinh ngẫu nhiên Admin Key
    $randomKey = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object {[char]$_})
    $envContent = Get-Content ".env"
    $envContent = $envContent -replace "NEUTRON_ADMIN_KEY=change-me", "NEUTRON_ADMIN_KEY=$randomKey"
    $envContent | Set-Content ".env"
    
    Write-Green ">>> Generated NEUTRON_ADMIN_KEY: $randomKey"
}

# 3. Build dự án
Write-Cyan ">>> Building NeutronAPI binary..."
go build -o neutronapi.exe ./cmd/neutronapi
if ($LASTEXITCODE -ne 0) {
    Write-Red "Build failed! Please check your Go environment."
    pause
    exit
}

# 4. Chạy Server
Write-Green ">>> NeutronAPI is up and running!"
Write-Cyan "Admin Panel: http://localhost:5001/admin"
Write-Yellow "Tip: Keep this window open. Press Ctrl+C to stop."
Write-Host "----------------------------------------------------"

.\neutronapi.exe
