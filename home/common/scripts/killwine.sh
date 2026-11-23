# Force-kill Wine/Proton processes, including stuck pressure-vessel containers.
# The pattern also matches this script's own path, so skip our pid.

# pgrep exits 1 on no match; not an error here.
pids=$(pgrep -f -i 'wine|processid|\.exe|pressure-vessel-adverb' || true)

for pid in $pids; do
	[ "$pid" = "$$" ] || kill -9 "$pid" 2>/dev/null || true
done
