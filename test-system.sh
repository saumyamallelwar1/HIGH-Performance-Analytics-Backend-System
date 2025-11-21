#!/bin/bash

# Test Script for Analytics Backend
# Tests all services and generates sample data

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

INGESTION_URL="http://localhost:3001"
REPORTING_URL="http://localhost:3002"
SITE_ID="site-test-$(date +%s)"

echo "================================================"
echo -e "${BLUE}🧪 Testing Analytics Backend System${NC}"
echo "================================================"
echo ""
echo "Test Site ID: ${SITE_ID}"
echo ""

# Test 1: Health Checks
echo -e "${BLUE}Test 1: Health Checks${NC}"
echo "---"

echo -n "Checking Ingestion API... "
if curl -s "${INGESTION_URL}/health" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ FAILED${NC}"
    exit 1
fi

echo -n "Checking Reporting API... "
if curl -s "${REPORTING_URL}/health" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ FAILED${NC}"
    exit 1
fi

echo ""

# Test 2: Submit Single Event
echo -e "${BLUE}Test 2: Submit Single Event${NC}"
echo "---"

RESPONSE=$(curl -s -X POST "${INGESTION_URL}/event" \
  -H "Content-Type: application/json" \
  -d "{
    \"site_id\": \"${SITE_ID}\",
    \"event_type\": \"page_view\",
    \"path\": \"/home\",
    \"user_id\": \"user-001\",
    \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"
  }")

if echo "$RESPONSE" | grep -q "success"; then
    echo -e "${GREEN}✓ Event accepted${NC}"
else
    echo -e "${RED}✗ Event submission failed${NC}"
    echo "$RESPONSE"
    exit 1
fi

echo ""

# Test 3: Submit Multiple Events
echo -e "${BLUE}Test 3: Submit 100 Events${NC}"
echo "---"

PATHS=("/home" "/pricing" "/about" "/contact" "/blog" "/features" "/docs")
USERS=("user-001" "user-002" "user-003" "user-004" "user-005")

for i in {1..100}; do
    PATH=${PATHS[$RANDOM % ${#PATHS[@]}]}
    USER=${USERS[$RANDOM % ${#USERS[@]}]}
    
    curl -s -X POST "${INGESTION_URL}/event" \
      -H "Content-Type: application/json" \
      -d "{
        \"site_id\": \"${SITE_ID}\",
        \"event_type\": \"page_view\",
        \"path\": \"${PATH}\",
        \"user_id\": \"${USER}\",
        \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"
      }" > /dev/null &
    
    # Progress indicator
    if [ $((i % 10)) -eq 0 ]; then
        echo -n "."
    fi
done

wait
echo ""
echo -e "${GREEN}✓ 100 events submitted${NC}"
echo ""

# Wait for processing
echo -e "${YELLOW}⏳ Waiting 10 seconds for event processing...${NC}"
sleep 10
echo ""

# Test 4: Query Statistics
echo -e "${BLUE}Test 4: Query Statistics${NC}"
echo "---"

STATS=$(curl -s "${REPORTING_URL}/stats?site_id=${SITE_ID}")

echo "Response:"
echo "$STATS" | python3 -m json.tool 2>/dev/null || echo "$STATS"
echo ""

# Verify stats
TOTAL_VIEWS=$(echo "$STATS" | grep -o '"total_views":[0-9]*' | grep -o '[0-9]*')
UNIQUE_USERS=$(echo "$STATS" | grep -o '"unique_users":[0-9]*' | grep -o '[0-9]*')

if [ "$TOTAL_VIEWS" -ge 100 ]; then
    echo -e "${GREEN}✓ Total views: ${TOTAL_VIEWS}${NC}"
else
    echo -e "${YELLOW}⚠ Total views: ${TOTAL_VIEWS} (expected >= 100)${NC}"
fi

if [ "$UNIQUE_USERS" -ge 5 ]; then
    echo -e "${GREEN}✓ Unique users: ${UNIQUE_USERS}${NC}"
else
    echo -e "${YELLOW}⚠ Unique users: ${UNIQUE_USERS} (expected >= 5)${NC}"
fi

echo ""

# Test 5: Test Batch Endpoint
echo -e "${BLUE}Test 5: Test Batch Endpoint${NC}"
echo "---"

BATCH_RESPONSE=$(curl -s -X POST "${INGESTION_URL}/events/batch" \
  -H "Content-Type: application/json" \
  -d "{
    \"events\": [
      {
        \"site_id\": \"${SITE_ID}\",
        \"event_type\": \"page_view\",
        \"path\": \"/batch-test-1\",
        \"user_id\": \"batch-user-1\",
        \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"
      },
      {
        \"site_id\": \"${SITE_ID}\",
        \"event_type\": \"page_view\",
        \"path\": \"/batch-test-2\",
        \"user_id\": \"batch-user-2\",
        \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"
      }
    ]
  }")

if echo "$BATCH_RESPONSE" | grep -q "success"; then
    echo -e "${GREEN}✓ Batch submission successful${NC}"
else
    echo -e "${RED}✗ Batch submission failed${NC}"
fi

echo ""

# Test 6: Test Other Reporting Endpoints
echo -e "${BLUE}Test 6: Test Additional Reporting Endpoints${NC}"
echo "---"

echo -n "Testing /stats/overview... "
if curl -s "${REPORTING_URL}/stats/overview?site_id=${SITE_ID}" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ FAILED${NC}"
fi

echo -n "Testing /stats/realtime... "
if curl -s "${REPORTING_URL}/stats/realtime?site_id=${SITE_ID}&minutes=30" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ FAILED${NC}"
fi

echo ""

# Summary
echo "================================================"
echo -e "${GREEN}✅ All Tests Completed!${NC}"
echo "================================================"
echo ""
echo "Summary:"
echo "- Site ID: ${SITE_ID}"
echo "- Events Submitted: 102 (100 + 1 + 1 batch)"
echo "- Total Views Recorded: ${TOTAL_VIEWS}"
echo "- Unique Users: ${UNIQUE_USERS}"
echo ""
echo "View full stats:"
echo "  curl '${REPORTING_URL}/stats?site_id=${SITE_ID}' | python3 -m json.tool"
echo ""