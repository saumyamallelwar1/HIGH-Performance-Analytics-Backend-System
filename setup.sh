#!/bin/bash

# Analytics Backend - Quick Setup Script
# This script sets up the entire project structure and creates all necessary files

set -e  # Exit on error

echo "================================================"
echo "🚀 Analytics Backend - Quick Setup"
echo "================================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create directory structure
echo -e "${BLUE}Creating directory structure...${NC}"
mkdir -p services/ingestion/src/{routes,middleware,queue}
mkdir -p services/processor/src/{queue,database}
mkdir -p services/reporting/src/{routes,database}
mkdir -p database

echo -e "${GREEN}✓ Directory structure created${NC}"

# Create .env files from examples
echo -e "${BLUE}Creating environment files...${NC}"

# Ingestion .env
cat > services/ingestion/.env << EOF
NODE_ENV=development
PORT=3001
REDIS_HOST=localhost
REDIS_PORT=6379
EOF

# Processor .env
cat > services/processor/.env << EOF
NODE_ENV=development
REDIS_HOST=localhost
REDIS_PORT=6379
DB_HOST=localhost
DB_PORT=5432
DB_NAME=analytics
DB_USER=analytics_user
DB_PASSWORD=analytics_pass
EOF

# Reporting .env
cat > services/reporting/.env << EOF
NODE_ENV=development
PORT=3002
DB_HOST=localhost
DB_PORT=5432
DB_NAME=analytics
DB_USER=analytics_user
DB_PASSWORD=analytics_pass
EOF

echo -e "${GREEN}✓ Environment files created${NC}"

# Install dependencies
echo -e "${BLUE}Installing dependencies...${NC}"

cd services/ingestion && npm install && cd ../..
cd services/processor && npm install && cd ../..
cd services/reporting && npm install && cd ../..

echo -e "${GREEN}✓ Dependencies installed${NC}"

echo ""
echo "================================================"
echo -e "${GREEN}✓ Setup Complete!${NC}"
echo "================================================"
echo ""
echo "Next steps:"
echo "1. Start Docker services: docker-compose up --build"
echo "2. Or manually start services in separate terminals:"
echo "   Terminal 1: cd services/ingestion && npm start"
echo "   Terminal 2: cd services/processor && npm start"
echo "   Terminal 3: cd services/reporting && npm start"
echo ""
echo "Test the system:"
echo "  curl -X POST http://localhost:3001/event \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"site_id\":\"test\",\"event_type\":\"page_view\",\"path\":\"/\",\"user_id\":\"user1\",\"timestamp\":\"2025-11-12T19:30:01Z\"}'"
echo ""
echo "  curl 'http://localhost:3002/stats?site_id=test'"
echo ""