#!/bin/bash

# --- NeutronAPI One-Click Runner (Linux/macOS) ---
# Project: https://github.com/NeutronAPI Team/neutronapi

# Màu sắc cho nó xịn xò
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}"
echo "    _   __              __                       ___     ____  ____"
echo "   / | / /__  __  __   / /__________  ____      /   |   / __ \/  _/"
echo "  /  |/ / _ \/ / / /  / __/ ___/ __ \/ __ \    / /| |  / /_/ // /  "
echo " / /|  /  __/ /_/ /  / /_/ /  / /_/ / / / /   / ___ | / ____// /   "
echo "/_/ |_/\___/\__,_/   \__/_/   \____/_/ /_/   /_/  |_|/_/    /___/  "
echo -e "${NC}"
echo -e "${GREEN}>>> NeutronAPI is initializing...${NC}"

# 1. Kiểm tra Go
if ! command -v go &> /dev/null; then
    echo -e "${RED}Error: Go is not installed. Please install Go from https://golang.org/dl/${NC}"
    exit 1
fi

# 2. Tạo config nếu chưa có
if [ ! -f "config.json" ]; then
    echo -e "${YELLOW}>>> config.json not found, creating from example...${NC}"
    cp config.example.json config.json
fi

if [ ! -f ".env" ]; then
    echo -e "${YELLOW}>>> .env not found, generating a secure one...${NC}"
    cp .env.example .env
    # Sinh ngẫu nhiên Admin Key nếu vẫn là 'change-me'
    RANDOM_KEY=$(LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 32 | head -n 1)
    sed -i "s/NEUTRON_ADMIN_KEY=change-me/NEUTRON_ADMIN_KEY=$RANDOM_KEY/" .env
    echo -e "${GREEN}>>> Generated NEUTRON_ADMIN_KEY: $RANDOM_KEY${NC}"
fi

# 3. Build dự án
echo -e "${CYAN}>>> Building NeutronAPI binary...${NC}"
go build -o neutronapi ./cmd/neutronapi
if [ $? -ne 0 ]; then
    echo -e "${RED}Build failed! Please check your Go environment.${NC}"
    exit 1
fi

# 4. Chạy Server
echo -e "${GREEN}>>> NeutronAPI is up and running!${NC}"
echo -e "${CYAN}Admin Panel: http://localhost:5001/admin${NC}"
echo -e "${YELLOW}Tip: Press Ctrl+C to stop the server.${NC}"
echo "----------------------------------------------------"

./neutronapi
