#!/bin/bash
API_KEY="emqx_api_key:emqx_secret_key_12345"

curl -s -u "$API_KEY" -H "Content-Type: application/json" "http://localhost:18083/api/v5/message_queues/queues"

SUB_TOICS=""

for i in $(seq 1 10); do
    SUB_TOICS="$SUB_TOICS -t \$q/q/$i/#"
done

mqttx sub $SUB_TOICS -p 1883