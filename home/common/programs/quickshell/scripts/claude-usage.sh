# Claude plan usage for the bar's Claude meter (config/services/ClaudeUsage.qml). Prints one JSON
# object:
#
#   {
#     "status": "ok" | "expired" | "rejected" | "limited" | "unreachable" | "failed" | "signed-out",
#     "fetched_at": <epoch seconds the usage below was read> | null,
#     "usage": {
#       "limits": [{ "id", "kind", "label", "percent", "severity", "resets_at", "active",
#                    "allowance" }],   # allowance: share of the weekly limit, for a model's own one
#       "breakdown": [{ "name", "percent" }],   # where this week's usage went
#       "extra": { "used", "limit", "currency", "decimals" } | null   # extra usage, when enabled
#     } | null,
#     "history": [[<epoch seconds>, <percent>], …]   # this week's readings of the weekly limit
#   }
#
# The sign-in is omp's (its Anthropic OAuth credential in ~/.omp/agent/agent.db), read only and
# never refreshed: omp rotates the refresh token when it refreshes, so a second refresher would
# sign it out. While that access token has expired ("expired") the last good reading is printed
# again; omp refreshes it the next time it runs. The token goes to curl on stdin, not argv.
#
# The history is the shell's own readings (kept when the weekly figure changes) together with
# omp's, which it records whenever it reads usage itself.

db="${OMP_AGENT_DB:-$HOME/.omp/agent/agent.db}"
state="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell-claude-usage"
last="$state/last.json"
log="$state/history.jsonl"
mkdir -p "$state"
now=$(date +%s)

# The API's limits, normalised: ISO times to epoch seconds, a label per limit, and a model limit's
# share of the weekly allowance beside it.
normalise='
  def epoch: if . == null then null else (sub("\\.[0-9]+"; "") | sub("(\\+00:00|Z)$"; "Z") | try fromdateiso8601 catch null) end;
  . as $u
  | ($u.weekly_scoped_shares // []) as $shares
  | [($u.limits // []) | to_entries[] | .key as $i | .value
      | {
          id: (.kind + (if .scope.model.display_name then ":" + .scope.model.display_name else "" end)),
          kind,
          label: (if .kind == "weekly_all" then "This week"
                  elif .scope.model.display_name then .scope.model.display_name
                  elif .group == "session" then "This session"
                  else (.kind | gsub("_"; " ") | (.[:1] | ascii_upcase) + .[1:]) end),
          percent: (.percent // 0),
          severity: (.severity // "normal"),
          resets_at: (.resets_at | epoch),
          active: (.is_active // false),
          allowance: (first($shares[] | select(.limit_index == $i) | .allowance_percent_of_weekly) // null)
        }] as $limits
  | {
      fetched_at: $now,
      usage: {
        limits: ($limits
          + (if $u.five_hour != null and ($limits | all(.kind == "weekly_all" or .kind == "weekly_scoped"))
             then [{ id: "five_hour", kind: "five_hour", label: "This session",
                     percent: ($u.five_hour.utilization // 0), severity: "normal",
                     resets_at: ($u.five_hour.resets_at | epoch), active: true, allowance: null }]
             else [] end)),
        breakdown: [($u.seven_day_breakdown.rows // [])[] | { name: .display_name, percent: (.percent // 0) }],
        extra: (if $u.extra_usage.is_enabled then {
                   used: $u.extra_usage.used_credits, limit: $u.extra_usage.monthly_limit,
                   currency: $u.extra_usage.currency, decimals: ($u.extra_usage.decimal_places // 2)
                 } else null end)
      }
    }'

status=signed-out
credential=""
if [[ -r "$db" ]]; then
  credential=$(sqlite3 -readonly "$db" "select data from auth_credentials where provider = 'anthropic' and credential_type = 'oauth' and disabled_cause is null order by updated_at desc limit 1" 2>/dev/null || true)
fi

if [[ -n "$credential" ]]; then
  token=$(jq -r '.access // empty' <<<"$credential")
  expires=$(jq -r '(.expires // 0) / 1000 | floor' <<<"$credential")
  if [[ -z "$token" ]]; then
    status=signed-out
  elif ((expires <= now + 60)); then
    status=expired
  else
    body=$(mktemp)
    trap 'rm -f "$body"' EXIT
    code=$(printf 'Authorization: Bearer %s\nanthropic-beta: oauth-2025-04-20\n' "$token" |
      curl -sS -m 10 -H @- -o "$body" -w '%{http_code}' https://api.anthropic.com/api/oauth/usage 2>/dev/null) || code=000
    case "$code" in
    200)
      if jq --argjson now "$now" "$normalise" "$body" >"$last.tmp" 2>/dev/null; then
        mv "$last.tmp" "$last"
        status=ok
        # Keep a reading when the weekly figure moved (or a new week began).
        reading=$(jq -c '.usage.limits[] | select(.kind == "weekly_all") | { t: $now, p: .percent, r: .resets_at }' --argjson now "$now" "$last")
        if [[ -n "$reading" ]]; then
          previous=$(tail -n 1 "$log" 2>/dev/null || true)
          if [[ -z "$previous" ]] || ! jq -e --argjson next "$reading" '.p == $next.p and .r == $next.r' <<<"$previous" >/dev/null 2>&1; then
            printf '%s\n' "$reading" >>"$log"
          fi
        fi
      else
        rm -f "$last.tmp"
        status=failed
      fi
      ;;
    401 | 403) status=rejected ;;
    429) status=limited ;;
    000) status=unreachable ;;
    *) status=failed ;;
    esac
  fi
fi

# Readings older than two weeks are no use to this week's chart.
if [[ -f "$log" ]] && (($(wc -l <"$log") > 2000)); then
  jq -c --argjson since "$((now - 14 * 86400))" 'select(.t >= $since)' "$log" >"$log.tmp" && mv "$log.tmp" "$log"
fi

current='null'
[[ -f "$last" ]] && current=$(cat "$last")
resets=$(jq -r '[.usage.limits[]? | select(.kind == "weekly_all") | .resets_at][0] // empty' <<<"$current")

omp='[]'
if [[ -n "$resets" && -r "$db" ]]; then
  omp=$(sqlite3 -readonly -json "$db" "select recorded_at / 1000 as t, round(used_fraction * 100) as p from usage_history where limit_id = 'anthropic:7d' and used_fraction is not null and resets_at / 1000 between $((resets - 3600)) and $((resets + 3600))" 2>/dev/null || true)
  [[ -n "$omp" ]] || omp='[]'
fi

own='[]'
if [[ -n "$resets" && -f "$log" ]]; then
  own=$(jq -s -c --argjson r "$resets" '[.[] | select(.r != null and ((.r - $r) | fabs) < 3600) | { t, p }]' "$log" 2>/dev/null || echo '[]')
fi

jq -n -c \
  --arg status "$status" \
  --argjson current "$current" \
  --argjson omp "$omp" \
  --argjson own "$own" \
  '{
    status: $status,
    fetched_at: ($current.fetched_at // null),
    usage: ($current.usage // null),
    history: ([$omp[], $own[]] | sort_by(.t) | map([.t, .p]))
  }'
