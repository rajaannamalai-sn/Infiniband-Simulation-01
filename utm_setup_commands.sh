#!/bin/bash
################################################################################
# UFM Setup Commands for UTM Ubuntu VM
# Run these commands in your UTM Ubuntu terminal
################################################################################

set -e

echo "=================================================="
echo "UFM + ibsim Setup for UTM Ubuntu VM"
echo "=================================================="
echo ""

# Update system
echo "[1/8] Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Docker
echo "[2/8] Installing Docker..."
sudo apt install -y docker.io docker-compose
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

# Install InfiniBand packages (CRITICAL)
echo "[3/8] Installing InfiniBand packages..."
sudo apt install -y \
  rdma-core \
  infiniband-diags \
  ibverbs-utils \
  libibverbs-dev \
  libibumad-dev \
  opensm

# Load InfiniBand kernel modules
echo "[4/8] Loading InfiniBand kernel modules..."
sudo modprobe ib_core
sudo modprobe ib_umad
sudo modprobe ib_uverbs

# Make modules persistent
echo "ib_core" | sudo tee -a /etc/modules
echo "ib_umad" | sudo tee -a /etc/modules
echo "ib_uverbs" | sudo tee -a /etc/modules

# Verify IB devices
echo "[5/8] Verifying InfiniBand devices..."
ls -la /dev/infiniband/ || echo "Note: Devices will appear when ibsim starts"

# Create UFM data directories
echo "[6/8] Creating UFM data directories..."
mkdir -p ~/ufm-data/files/log
mkdir -p ~/ufm-data/files/conf
mkdir -p ~/ufm-data/logs
mkdir -p ~/ufm-data/db

# Create topology file
echo "[7/8] Creating spine-leaf topology..."
cat > ~/spine_leaf_fabric.topo <<'EOF'
# Spine-Leaf Topology with 2 Spine and 2 Leaf Switches
vendid=0x2c9
devid=0xc738
sysimgguid=0x0002c90200300001
switchguid=0x0002c90200300001(0x0002c90200300001)
Switch 36 "S-0002c90200300001" # "Spine-1" base port 0 lid 0 lmc 0
[1] "S-0002c90200300003"[1]
[2] "S-0002c90200300004"[1]

vendid=0x2c9
devid=0xc738
sysimgguid=0x0002c90200300002
switchguid=0x0002c90200300002(0x0002c90200300002)
Switch 36 "S-0002c90200300002" # "Spine-2" base port 0 lid 0 lmc 0
[1] "S-0002c90200300003"[2]
[2] "S-0002c90200300004"[2]

vendid=0x2c9
devid=0xc738
sysimgguid=0x0002c90200300003
switchguid=0x0002c90200300003(0x0002c90200300003)
Switch 36 "S-0002c90200300003" # "Leaf-1" base port 0 lid 0 lmc 0
[1] "S-0002c90200300001"[1]
[2] "S-0002c90200300002"[1]
[3] "H-0002c90200300005"[1]
[4] "H-0002c90200300006"[1]

vendid=0x2c9
devid=0xc738
sysimgguid=0x0002c90200300004
switchguid=0x0002c90200300004(0x0002c90200300004)
Switch 36 "S-0002c90200300004" # "Leaf-2" base port 0 lid 0 lmc 0
[1] "S-0002c90200300001"[2]
[2] "S-0002c90200300002"[2]
[3] "H-0002c90200300007"[1]
[4] "H-0002c90200300008"[1]

vendid=0x2c9
devid=0x5a44
caguid=0x0002c90200300005
Ca 2 "H-0002c90200300005" # "Host-1"
[1] "S-0002c90200300003"[3]

vendid=0x2c9
devid=0x5a44
caguid=0x0002c90200300006
Ca 2 "H-0002c90200300006" # "Host-2"
[1] "S-0002c90200300003"[4]

vendid=0x2c9
devid=0x5a44
caguid=0x0002c90200300007
Ca 2 "H-0002c90200300007" # "Host-3"
[1] "S-0002c90200300004"[3]

vendid=0x2c9
devid=0x5a44
caguid=0x0002c90200300008
Ca 2 "H-0002c90200300008" # "Host-4"
[1] "S-0002c90200300004"[4]
EOF

echo ""
echo "=================================================="
echo "Setup Complete!"
echo "=================================================="
echo ""
echo "IMPORTANT: Log out and log back in for Docker group to take effect:"
echo "  exit"
echo "  (then SSH back in)"
echo ""
echo "After logging back in, run:"
echo "  ./start_ibsim_ufm.sh"
echo ""
