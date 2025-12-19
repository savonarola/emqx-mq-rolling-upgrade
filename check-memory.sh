#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

NODES=(1 2 3)

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

get_docker_memory() {
    local container_name=$1

    if ! docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        return 1
    fi

    local stats=$(docker stats --no-stream --format "{{.MemUsage}}" "$container_name" 2>/dev/null)
    echo "$stats"
    return 0
}

get_docker_memory_mb() {
    local container_name=$1

    if ! docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        echo "0"
        return 1
    fi

    local mem=$(docker stats --no-stream --format "{{.MemUsage}}" "$container_name" 2>/dev/null | awk '{print $1}' | sed 's/MiB//' | sed 's/GiB/*1024/')

    if [[ "$mem" == *"*"* ]]; then
        mem=$(echo "$mem" | bc 2>/dev/null)
    fi

    echo "${mem:-0}"
    return 0
}

display_cluster_memory() {
    print_header "EMQX Cluster Memory Consumption"
    echo ""

    local total_memory=0
    local node_count=0

    for node_num in "${NODES[@]}"; do
        local container_name=""
        local version=""
        local is_running=false

        if docker ps --format '{{.Names}}' | grep -q "^emqx${node_num}-new$"; then
            container_name="emqx${node_num}-new"
            version="6.1.0-alpha.2"
            is_running=true
        elif docker ps --format '{{.Names}}' | grep -q "^emqx${node_num}-old$"; then
            container_name="emqx${node_num}-old"
            version="6.0.0"
            is_running=true
        fi

        if [ "$is_running" = true ]; then
            echo -e "${CYAN}Node ${node_num} [${version}]:${NC}"

            echo -n "  Container Memory: "
            local docker_mem=$(get_docker_memory "$container_name")
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}${docker_mem}${NC}"

                local mem_mb=$(get_docker_memory_mb "$container_name")
                if command -v bc &> /dev/null && [[ "$mem_mb" =~ ^[0-9.]+$ ]]; then
                    total_memory=$(echo "$total_memory + $mem_mb" | bc)
                fi
                node_count=$((node_count + 1))
            else
                echo -e "${YELLOW}N/A${NC}"
            fi

            echo ""
        fi
    done

    echo -e "${BLUE}----------------------------------------${NC}"
    echo -e "${GREEN}Active Nodes: ${node_count}/3${NC}"

    if command -v bc &> /dev/null && [[ "$total_memory" =~ ^[0-9.]+$ ]]; then
        total_memory=$(echo "scale=2; $total_memory / 1" | bc)
        echo -e "${GREEN}Total Cluster Memory: ${total_memory}MB${NC}"
    else
        print_info "Install 'bc' for total memory calculation"
    fi
}

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]
EOF
}

main() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    display_cluster_memory
}

main "$@"
