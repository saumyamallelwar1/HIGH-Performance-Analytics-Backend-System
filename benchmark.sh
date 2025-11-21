#!/bin/bash

# Performance Benchmark Script
# Tests the throughput and latency of the ingestion API

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

INGESTION_URL="http://localhost:3001"
SITE_ID="benchmark-test"
TOTAL_REQUESTS=1000
CONCURRENT=50

echo "================================================"
echo -e "${BLUE}⚡ Performance Benchmark${NC}"
echo "================================================"
echo ""
echo "Configuration:"
echo "- Total Requests: ${TOTAL_REQUESTS}"
echo "- Concurrent Requests: ${CONCURRENT}"
echo "- Target: ${INGESTION_URL}"
echo ""

# Check if Apache Bench is installed
if ! command -v ab &> /dev/null; then
    echo -e "${YELLOW}⚠ Apache Bench (ab) not found${NC}"
    echo "Install it with:"
    echo "  macOS: brew install apache-bench"
    echo "  Ubuntu: sudo apt-get install apache2-utils"
    echo ""
    echo "Falling back to curl-based test..."
    echo ""
    
    # Fallback: Simple curl test
    echo -e "${BLUE}Running simple throughput test...${NC}"
    START=$(date +%s)
    
    for i in $(seq 1 ${TOTAL_REQUESTS}); do
        curl -s -X POST "${INGESTION_URL}/event" \
          -H "Content-Type: application/json" \
          -d "{
            \"site_id\": \"${SITE_ID}\",
            \"event_type\": \"page_view\",
            \"path\": \"/test\",
            \"user_id\": \"user-$i\",
            \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"
          }" > /dev/null &
        
        # Limit concurrent requests
        if [ $((i % CONCURRENT)) -eq 0 ]; then
            wait
        fi
        
        # Progress
        if [ $((i % 100)) -eq 0 ]; then
            echo -n "."
        fi
    done
    
    wait
    END=$(date +%s)
    DURATION=$((END - START))
    RPS=$((TOTAL_REQUESTS / DURATION))
    
    echo ""
    echo ""
    echo "Results:"
    echo "- Total Requests: ${TOTAL_REQUESTS}"
    echo "- Duration: ${DURATION} seconds"
    echo "- Requests/Second: ${RPS}"
    
else
    # Use Apache Bench
    echo -e "${BLUE}Running Apache Bench test...${NC}"
    echo ""
    
    # Create POST data file
    cat > /tmp/event-payload.json << EOF
{
  "site_id": "${SITE_ID}",
  "event_type": "page_view",
  "path": "/benchmark",
  "user_id": "bench-user",
  "timestamp": "2025-11-12T19:30:01Z"
}
EOF
    
    # Run Apache Bench
    ab -n ${TOTAL_REQUESTS} -c ${CONCURRENT} \
       -p /tmp/event-payload.json \
       -T "application/json" \
       "${INGESTION_URL}/event"
    
    # Cleanup
    rm /tmp/event-payload.json
fi

echo ""
echo "================================================"
echo -e "${GREEN}✓ Benchmark Complete${NC}"
echo "================================================"
echo ""