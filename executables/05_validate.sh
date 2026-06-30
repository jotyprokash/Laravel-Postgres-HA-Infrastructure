#!/bin/bash
# 05_validate.sh
# Run from any machine to validate the deployment end-to-end.
set -e

APP_URL="http://163.61.156.56"
PRIMARY_IP="163.61.156.98"
STANDBY_IP="163.61.156.112"

echo "=== 1. Application Health ==="
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$APP_URL")
if [ "$HTTP_CODE" -eq 200 ]; then
    echo "PASS: Application responding (HTTP $HTTP_CODE)"
else
    echo "FAIL: Application returned HTTP $HTTP_CODE"
fi

echo ""
echo "=== 2. Registration Endpoint ==="
RESULT=$(curl -s -w "\n%{http_code}" -X POST "$APP_URL/api/register" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"username":"testuser","email":"test@example.com","name":"Test","phone":"0123456789"}')
CODE=$(echo "$RESULT" | tail -1)
BODY=$(echo "$RESULT" | head -1)
if [ "$CODE" -eq 201 ]; then
    echo "PASS: Registration endpoint working"
else
    echo "FAIL: Registration returned $CODE - $BODY"
fi

echo ""
echo "=== 3. Replication Status ==="
ssh root@$PRIMARY_IP "sudo -u postgres psql -c \"SELECT client_addr, state, sent_lsn, replay_lsn FROM pg_stat_replication;\""

echo ""
echo "=== 4. Repmgr Cluster Status ==="
ssh root@$PRIMARY_IP "sudo -u postgres repmgr -f /etc/repmgr.conf cluster show"

echo ""
echo "=== 5. Data Consistency Check ==="
PRIMARY_COUNT=$(ssh root@$PRIMARY_IP "sudo -u postgres psql -t -d laravel_app -c 'SELECT count(*) FROM registrations;'" | tr -d ' ')
STANDBY_COUNT=$(ssh root@$STANDBY_IP "sudo -u postgres psql -t -d laravel_app -c 'SELECT count(*) FROM registrations;'" | tr -d ' ')
echo "Primary: $PRIMARY_COUNT rows | Standby: $STANDBY_COUNT rows"
if [ "$PRIMARY_COUNT" -eq "$STANDBY_COUNT" ]; then
    echo "PASS: Data is consistent across nodes"
else
    echo "WARN: Replication lag detected (async replication expected)"
fi

echo ""
echo "Validation complete."
