#!/bin/bash
################################################################################
# UFM Enterprise Setup Script for ibsim Integration
# Connects UFM to simulated InfiniBand fabric
################################################################################

set -e

echo "================================================================================"
echo "  UFM Enterprise + ibsim Integration Setup"
echo "================================================================================"
echo ""

# Configuration
UFM_USERNAME="${UFM_USERNAME:-admin}"
UFM_PASSWORD="${UFM_PASSWORD:-admin123}"
UFM_PORT="${UFM_PORT:-9080}"

# Check if ibsim container is running
echo "[1/5] Checking ibsim container..."
if ! docker ps | grep -q ib-sim-active; then
    echo "ERROR: ibsim container (ib-sim-active) is not running!"
    echo "Please start ibsim first."
    exit 1
fi
echo "✓ ibsim container is running"
echo ""

# Stop existing UFM container if running
echo "[2/5] Cleaning up existing UFM container..."
docker stop ufm 2>/dev/null || true
docker rm ufm 2>/dev/null || true
echo "✓ Cleanup complete"
echo ""

# Create UFM data directories
echo "[3/5] Creating UFM data directories..."
UFM_BASE_DIR="$HOME/.ufm-data"
mkdir -p "$UFM_BASE_DIR/files"
mkdir -p "$UFM_BASE_DIR/logs"
mkdir -p "$UFM_BASE_DIR/db"
echo "✓ Directories created at: $UFM_BASE_DIR"
echo ""

# Detect Docker socket path (macOS vs Linux)
echo "[4/7] Detecting Docker socket location..."
DOCKER_SOCK=""
if [ -S "/var/run/docker.sock" ]; then
    DOCKER_SOCK="/var/run/docker.sock"
    echo "✓ Found Docker socket at: /var/run/docker.sock (Linux/Docker Desktop)"
elif [ -S "$HOME/.docker/run/docker.sock" ]; then
    DOCKER_SOCK="$HOME/.docker/run/docker.sock"
    echo "✓ Found Docker socket at: $HOME/.docker/run/docker.sock (macOS Docker Desktop)"
else
    echo "⚠ WARNING: Docker socket not found!"
    echo "  This may cause UFM initialization to fail."
    echo "  Enable 'Allow the default Docker socket to be used' in Docker Desktop settings"
    echo ""
    echo "  Continuing without socket mount..."
fi
echo ""

# Start UFM container
echo "[5/7] Starting UFM Enterprise container..."
echo "Platform: linux/amd64 (emulated on ARM64)"
echo "Network: Shared with ibsim container"
echo "Privileged mode: Enabled for IB device access"
echo "This may take 2-3 minutes for first-time initialization..."
echo ""

# Build docker run command with conditional socket mount
DOCKER_CMD="docker run -d \
  --name ufm \
  --platform linux/amd64 \
  --privileged \
  --network container:ib-sim-active"

# Add Docker socket mount if available
if [ -n "$DOCKER_SOCK" ]; then
    DOCKER_CMD="$DOCKER_CMD \
  -v $DOCKER_SOCK:/var/run/docker.sock"
    echo "✓ Mounting Docker socket: $DOCKER_SOCK"
fi

# Add remaining parameters
DOCKER_CMD="$DOCKER_CMD \
  -v $UFM_BASE_DIR/files:/opt/ufm/files \
  -v $UFM_BASE_DIR/logs:/opt/ufm/logs \
  -v $UFM_BASE_DIR/db:/opt/ufm/database \
  -e UFM_USERNAME=$UFM_USERNAME \
  -e UFM_PASSWORD=$UFM_PASSWORD \
  -e UFM_LOG_LEVEL=INFO \
  mellanox/ufm-enterprise:latest"

# Execute the command
eval $DOCKER_CMD

echo "✓ UFM container started"
echo ""

# Check if container is running
echo "[6/7] Verifying container status..."
sleep 3
if ! docker ps | grep -q "ufm"; then
    echo "⚠ WARNING: UFM container exited immediately!"
    echo ""
    echo "Checking logs for errors:"
    docker logs ufm 2>&1 | tail -20
    echo ""
    echo "Common issues on Apple Silicon:"
    echo "  • x86_64 emulation compatibility"
    echo "  • Missing kernel modules for InfiniBand"
    echo "  • Docker socket permission issues"
    echo ""
    echo "Recommended: Use NVIDIA AIR instead (https://air.nvidia.com)"
    echo ""
    exit 1
fi
echo "✓ Container is running"
echo ""

# Wait for UFM to initialize
echo "[7/7] Waiting for UFM services to start..."
echo "This can take 60-90 seconds on ARM64 emulation..."
echo "(UFM is initializing x86_64 binaries via Rosetta 2)"
echo ""

for i in {1..90}; do
    if docker exec ufm bash -c 'curl -k -s https://localhost:9080/ufm 2>/dev/null' | grep -q "UFM\|html" 2>/dev/null; then
        echo ""
        echo "✓ UFM web service is ready!"
        break
    fi
    echo -n "."
    sleep 1
done
echo ""

echo "================================================================================"
echo "  UFM Enterprise is Running!"
echo "================================================================================"
echo ""
echo "Container Status:"
echo "  Name:     ufm"
echo "  Platform: linux/amd64 (emulated on ARM64)"
echo "  Mode:     Privileged (for IB device access)"
if [ -n "$DOCKER_SOCK" ]; then
    echo "  Socket:   ✓ Docker socket mounted"
else
    echo "  Socket:   ⚠ No Docker socket (may limit functionality)"
fi
echo ""
echo "Access Information:"
echo "  URL:      https://localhost:$UFM_PORT"
echo "  Username: $UFM_USERNAME"
echo "  Password: $UFM_PASSWORD"
echo ""
echo "Important Notes:"
echo "  • UFM runs in x86_64 emulation mode (Rosetta 2)"
echo "  • Performance may be slower than native"
echo "  • Some features may not work due to ARM64 limitations"
echo "  • UFM shares network namespace with ibsim container"
echo ""
echo "Next Steps:"
echo "  1. Configure UFM to discover ibsim fabric:"
echo "     ./configure_ufm.sh"
echo ""
echo "  2. Access UFM Web GUI:"
echo "     Open browser: https://localhost:$UFM_PORT"
echo "     Accept self-signed certificate warning"
echo "     Login with credentials above"
echo ""
echo "  3. Verify fabric discovery:"
echo "     Check 'Topology' tab for 4 switches, 4 hosts"
echo ""
echo "Troubleshooting:"
echo "  • View logs: docker logs ufm -f"
echo "  • Check status: docker exec ufm ps aux | grep ufm"
echo "  • Restart: docker restart ufm"
echo ""
echo "Alternative (Recommended for Certification):"
echo "  NVIDIA AIR provides better UFM experience:"
echo "  https://air.nvidia.com"
echo ""
echo "================================================================================"
