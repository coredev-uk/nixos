# Force-kill everything Wine/Proton related, including stuck pressure-vessel containers.
# The pattern also matches this script's own path, so skip our own pid.

# pgrep exits 1 when nothing matches; that is not an error here.
pids=$(pgrep -f -i 'wine|processid|\.exe|pressure-vessel-adverb' || true)

for pid in $pids; do
	[ "$pid" = "$$" ] || kill -9 "$pid" 2>/dev/null || true
done
