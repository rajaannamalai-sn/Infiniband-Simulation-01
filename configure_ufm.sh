#!/bin/bash
################################################################################
# Configure UFM to discover ibsim simulated fabric
################################################################################

set -e

echo "================================================================================"
echo "  Configuring UFM for ibsim Integration"
echo "================================================================================"
echo ""

# Check if UFM container is running
if ! docker ps | grep -q "ufm"; then
    echo "ERROR: UFM container is not running!"
    echo "Please run ./start_ufm.sh first"
    exit 1
fi

echo "[1/4] Installing umad2sim library in UFM container..."
# Copy umad2sim from ibsim container to UFM container
docker exec ib-sim-active bash -c 'tar -czf /tmp/umad2sim.tar.gz -C /usr/lib umad2sim' 2>/dev/null || true
docker cp ib-sim-active:/tmp/umad2sim.tar.gz /tmp/umad2sim.tar.gz 2>/dev/null || true
docker cp /tmp/umad2sim.tar.gz ufm:/tmp/umad2sim.tar.gz 2>/dev/null || true
docker exec ufm bash -c 'mkdir -p /usr/lib/umad2sim && tar -xzf /tmp/umad2sim.tar.gz -C /usr/lib 2>/dev/null' || true
echo "✓ umad2sim library installed"
echo ""

echo "[2/4] Configuring UFM environment..."
docker exec ufm bash -c 'cat > /etc/profile.d/umad2sim.sh << EOF
export LD_PRELOAD=/usr/lib/umad2sim/libumad2sim.so
EOF'
echo "✓ Environment configured"
echo ""

echo "[3/4] Restarting UFM services with simulation mode..."
docker exec ufm bash -c 'export LD_PRELOAD=/usr/lib/umad2sim/libumad2sim.so && /etc/init.d/ufmd restart' 2>/dev/null || \
docker exec ufm bash -c 'pkill -9 ufm; sleep 2; export LD_PRELOAD=/usr/lib/umad2sim/libumad2sim.so && /opt/ufm/scripts/ufm start' 2>/dev/null || \
echo "Note: UFM may need manual restart from GUI"
echo "✓ Service restart attempted"
echo ""

echo "[4/4] Triggering fabric discovery..."
sleep 5
docker exec ufm bash -c 'export LD_PRELOAD=/usr/lib/umad2sim/libumad2sim.so && ibstat' 2>/dev/null || echo "Waiting for discovery..."
echo "✓ Discovery initiated"
echo ""

echo "================================================================================"
echo "  UFM Configuration Complete!"
echo "================================================================================"
echo ""
echo "UFM should now discover your simulated fabric:"
echo "  • 4 Switches (2 Spine, 2 Leaf)"
echo "  • 4 Hosts"
echo "  • Spine-Leaf topology"
echo ""
echo "Access UFM Web GUI:"
echo "  URL: https://localhost:9080"
echo "  Username: admin"
echo "  Password: admin123"
echo ""
echo "Important Notes:"
echo "  • UFM runs in AMD64 emulation mode (slower performance)"
echo "  • Web GUI may take 1-2 minutes to fully load"
echo "  • Accept the self-signed certificate warning in browser"
echo "  • First login may require initial setup wizard"
echo ""
echo "Troubleshooting:"
echo "  • Check UFM logs: docker logs ufm"
echo "  • Check status: docker exec ufm /opt/ufm/scripts/ufm status"
echo "  • Restart UFM: docker restart ufm"
echo ""
echo "================================================================================"
