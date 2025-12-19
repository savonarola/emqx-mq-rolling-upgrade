#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

WAIT_TIME=10
API_PORTS=(18083 18084 18085)
NODES=(1 2 3)
API_KEY="emqx_api_key:emqx_secret_key_12345"

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

smoke_test() {
    local node_num=$1
    local api_port=${API_PORTS[$((node_num-1))]}
    local max_retries=30
    local retry_count=0

    print_info "Running smoke test for node $node_num (API port: $api_port)..."

    while [ $retry_count -lt $max_retries ]; do
        if curl -s -u "$API_KEY" "http://localhost:${api_port}/api/v5/status" > /dev/null 2>&1; then
            local response=$(curl -s -u "$API_KEY" "http://localhost:${api_port}/api/v5/status")
            print_info "Node $node_num API Response: $response"

            # Check if node is running
            if echo "$response" | grep -q "running"; then
                print_info "✓ Node $node_num is running and healthy"
                return 0
            fi
        fi

        retry_count=$((retry_count+1))
        if [ $retry_count -lt $max_retries ]; then
            echo -n "."
            sleep 2
        fi
    done

    print_error "✗ Node $node_num failed smoke test after $max_retries retries"
    return 1
}

check_cluster_status() {
    print_info "Checking cluster status..."

    for node_num in "${NODES[@]}"; do
        local api_port=${API_PORTS[$((node_num-1))]}
        if curl -s -u "$API_KEY" "http://localhost:${api_port}/api/v5/cluster" > /dev/null 2>&1; then
            local cluster_status=$(curl -s -u "$API_KEY" "http://localhost:${api_port}/api/v5/cluster")
            print_info "Cluster status from node $node_num: $cluster_status"
        fi
    done
}

upgrade_node() {
    local node_num=$1
    local old_container="emqx${node_num}-old"
    local new_container="emqx${node_num}-new"

    print_info "=========================================="
    print_info "Upgrading Node $node_num"
    print_info "=========================================="

    print_info "Stopping $old_container..."
    docker compose stop $old_container

    print_info "Waiting for graceful shutdown..."
    sleep 3

    print_info "Starting $new_container..."
    docker compose --profile upgrade up -d $new_container

    print_info "Waiting ${WAIT_TIME} seconds for node to stabilize..."
    sleep $WAIT_TIME

    if smoke_test $node_num; then
        print_info "✓ Node $node_num upgrade successful"
    else
        print_error "✗ Node $node_num upgrade failed smoke test"
        print_error "Rolling back..."
        docker compose stop $new_container
        docker compose up -d $old_container
        exit 1
    fi

    echo ""
}

main() {
    print_info "Starting EMQX Rolling Upgrade"
    print_info "From: emqx-enterprise:6.0.0"
    print_info "To: emqx-enterprise:6.1.0-alpha.2"
    echo ""

    print_info "Checking if old cluster is running..."
    if ! docker compose ps | grep -q "emqx1-old"; then
        print_error "Old cluster is not running. Please start it first with: docker compose up -d"
        exit 1
    fi

    print_info "Initial cluster status:"
    check_cluster_status
    echo ""

    for node_num in "${NODES[@]}"; do
        upgrade_node $node_num
    done

    print_info "=========================================="
    print_info "Rolling Upgrade Complete"
    print_info "=========================================="

    print_info "Final cluster status:"
    check_cluster_status

    print_info ""
    print_info "All nodes have been upgraded successfully!"
    print_info "Old containers are stopped but not removed."
    print_info "To remove old containers, run: docker compose rm emqx1-old emqx2-old emqx3-old"
}

main
