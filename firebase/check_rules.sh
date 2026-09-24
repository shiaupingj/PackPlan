#!/usr/bin/env bash
# 以「未登入的 App」身分打 Firestore REST API,確認線上規則是否符合 firestore.rules 的預期。
set -u

BASE='https://firestore.googleapis.com/v1/projects/packplan-86e9d/databases/(default)/documents'
failed=0

check() {
  local label=$1 expected=$2 actual=$3
  if [ "$actual" = "$expected" ]; then
    echo "✓ $label → $actual"
  else
    echo "✗ $label → $actual(預期 $expected)"
    failed=1
  fi
}

code() { curl -s -o /dev/null -w '%{http_code}' "$@"; }

check '讀 gear_weights' 200 "$(code "$BASE/gear_weights")"
# 還沒匯入時文件不存在會回 404,也代表規則放行(被擋會是 403)
meta=$(code "$BASE/meta/gear_weights")
check '讀 meta/gear_weights' "$([ "$meta" = 404 ] && echo 404 || echo 200)" "$meta"
check '寫 gear_weights' 403 "$(code -X POST -H 'Content-Type: application/json' \
  -d '{"fields":{"nameZh":{"stringValue":"rules-test"}}}' \
  "$BASE/gear_weights?documentId=rules-test")"
check '讀其他 collection' 403 "$(code "$BASE/users")"

exit $failed
