#!/bin/sh
set -ex

echo "=== Proxy entrypoint starting ==="

# Redirect all outbound HTTP/HTTPS to squid (transparent mode)
# Only affects traffic from other containers sharing this network namespace
echo "Setting up iptables rules..."
iptables -t nat -A OUTPUT -p tcp --dport 80 -m owner ! --uid-owner squid -j REDIRECT --to-port 3129
iptables -t nat -A OUTPUT -p tcp --dport 443 -m owner ! --uid-owner squid -j REDIRECT --to-port 3130

echo "iptables rules installed for transparent proxy"

# Verify squid config
echo "Verifying squid config..."
squid -k parse -f /etc/squid/squid.conf

# Remove stale PID file if exists
rm -f /var/run/squid.pid

echo "Starting squid..."

# Start squid in foreground (-N) with cache creation (-z on first run is automatic)
exec squid -N -d 1 -f /etc/squid/squid.conf
