#!/bin/bash
################################################################################
# Start ibsim + UFM in UTM Ubuntu VM
# Run this after logging back in
################################################################################

set -e

echo "=================================================="
echo "Starting ibsim + UFM in UTM"
echo "=================================================="
echo ""

# Start ibsim
echo "[1/5] Starting ibsim container..."
docker run -d \
  --name ib-sim-active \
  --privileged \
  -p 5000:5000 \
  -v ~/spine_leaf_fabric.topo:/workspace/my_fabric.topo \
  ghcr.io/linux-rdma/ibsim:latest \
  tail -f /dev/null

echo "✓ ibsim container started"
echo ""

# Start ibsim daemon
echo "[2/5] Starting ibsim daemon..."
docker exec -d ib-sim-active ibsim -s /workspace/my_fabric.topo
sleep 3
echo "✓ ibsim daemon running"
echo ""

# Start OpenSM
echo "[3/5] Starting OpenSM..."
docker exec -d ib-sim-active bash -c \
  'export LD_PRELOAD=/usr/lib/umad2sim/libumad2sim.so && opensm -g 0x2c90200300001'
sleep 5
echo "✓ OpenSM running"
echo ""

# Verify fabric
echo "[4/5] Verifying simulated fabric..."
docker exec ib-sim-active bash -c \
  'export LD_PRELOAD=/usr/lib/umad2sim/libumad2sim.so && ibswitches'
echo ""

# Start UFM
echo "[5/5] Starting UFM Enterprise..."
docker run -d \
  --name ufm \
  --hostname ufm-server \
  --privileged \
  --network container:ib-sim-active \
  -v ~/ufm-data/files:/opt/ufm/files \
  -v ~/ufm-data/logs:/opt/ufm/logs \
  -v ~/ufm-data/db:/opt/ufm/database \
  -e UFM_USERNAME=admin \
  -e UFM_PASSWORD=admin123 \
  mellanox/ufm-enterprise:latest

echo "✓ UFM container started"
echo ""

echo "Waiting for UFM to initialize (this takes 2-3 minutes)..."
sleep 120

# Configure UFM for simulation
echo ""
echo "Configuring UFM to discover simulated fabric..."

# Copy umad2sim library
docker exec ib-sim-active tar -czf /tmp/umad2sim.tar.gz -C /usr/lib umad2sim
docker cp ib-sim-active:/tmp/umad2sim.tar.gz /tmp/
docker cp /tmp/umad2sim.tar.gz ufm:/tmp/
docker exec ufm tar -xzf /tmp/umad2sim.tar.gz -C /usr/lib

# Set LD_PRELOAD for UFM
docker exec ufm bash -c 'cat > /etc/profile.d/umad2sim.sh <<EOF
export LD_PRELOAD=/usr/lib/umad2sim/libumad2sim.so
EOF'

# Restart UFM with simulation library
docker exec ufm bash -c \
  'export LD_PRELOAD=/usr/lib/umad2sim/libumad2sim.so && /opt/ufm/scripts/ufm restart'

echo ""
echo "Waiting for UFM restart..."
sleep 30
echo ""

# Verify UFM can see fabric
echo "Verifying UFM can discover fabric..."
docker exec ufm bash -c \
  'export LD_PRELOAD=/usr/lib/umad2sim/libumad2sim.so && ibswitches' || \
  echo "Note: UFM may need more time to initialize"

echo ""
echo "=================================================="
echo "Setup Complete!"
echo "=================================================="
echo ""
echo "Access UFM Web GUI:"
echo "  URL: https://$(hostname -I | awk '{print $1}'):9080"
echo "  Username: admin"
echo "  Password: admin123"
echo ""
echo "From your Mac, open browser to:"
echo "  https://<VM-IP>:9080"
echo ""
echo "To find VM IP: hostname -I"
echo ""
echo "Check UFM status:"
echo "  docker exec ufm /opt/ufm/scripts/ufm status"
echo ""
echo "View UFM logs:"
echo "  docker logs -f ufm"
echo ""
echo "=================================================="
