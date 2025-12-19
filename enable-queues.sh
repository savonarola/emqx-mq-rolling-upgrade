#!/bin/bash
API_KEY="emqx_api_key:emqx_secret_key_12345"

curl -s -u "$API_KEY" -X PUT -H "Content-Type: application/json" http://localhost:18083/api/v5/message_queues/config \
-d '{"enable": true}' | jq
