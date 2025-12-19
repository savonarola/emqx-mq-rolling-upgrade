#!/bin/bash
API_KEY="emqx_api_key:emqx_secret_key_12345"

for q in $(seq 1 10); do
    curl -s -u "$API_KEY" -X POST -H "Content-Type: application/json" http://localhost:18083/api/v5/message_queues/queues -d '{"topic_filter": "q/'$q'/#"}' | jq
done

PORTS=(1883 1884 1885)

for q in $(seq 1 10); do
    PORT=${PORTS[$RANDOM % ${#PORTS[@]}]}
    mqttx pub -t "q/$q/1" -m "test" -p $PORT
done