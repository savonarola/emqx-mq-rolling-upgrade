# Scenario: Upgrade from 6.0.0 to 6.1.0-alpha.2

## 1. Start the old cluster

```bash
docker compose up -d
```

## 2. Check memory

```
./check-memory.sh
...
Active Nodes: 3/3
Total Cluster Memory: 1147.00MB
```

## 3. Create queues

```bash
./create-queues.sh
```

## 4. Check memory

```
Active Nodes: 3/3
Total Cluster Memory: 1155.70MB
```

## 5. Rolling upgrade to 6.1.0-alpha.2 with queues disabled

```bash
./rolling-upgrade.sh
```

## 6. Remove the old cluster

```bash
docker compose rm emqx1-old emqx2-old emqx3-old
```

## 7. Check memory (mqs disabled)


```bash
Active Nodes: 3/3
Total Cluster Memory: 1043.50MB
```

## 8. Check queues disabled

```bash
curl -s -u emqx_api_key:emqx_secret_key_12345 "http://localhost:18084/api/v5/message_queues/config" |jq
{
  ...
  "enable": false,
  ...
}
```

## Enable queues & check queues enabled

```bash
./enable-queues.sh
```

```bash
curl -s -u emqx_api_key:emqx_secret_key_12345 "http://localhost:18084/api/v5/message_queues/config" |jq
{
  ...
  "enable": true,
  ...
}
```

## 9. Check queues are working

```bash
./check-queues.sh
```

## 10. Check memory (mqs enabled)

```bash
Active Nodes: 3/3
Total Cluster Memory: 1188.40MB
```

## 11. Cleanup

```bash
docker compose --profile upgrade down
docker compose down -v
```

