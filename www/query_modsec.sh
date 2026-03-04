#!/bin/bash

LOG="/var/log/apache2/modsec_audit.log"

jq -r '
  select(.transaction.messages != null) |
  "IP: \(.transaction.client_ip)\nREQUEST: \(.transaction.request.method) \(.transaction.request.uri)\nALERT: \(.transaction.messages[].message)\n---"
' "$LOG"
