FROM ubuntu:24.04

# Install compilation tools and InfiniBand utilities
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    libibumad-dev \
    libibmad-dev \
    opensm \
    infiniband-diags \
    ibverbs-utils \
    rdma-core \
    && rm -rf /var/lib/apt/lists/*

# Compile ibsim natively for ARM64 from source
RUN git clone https://github.com/linux-rdma/ibsim.git /tmp/ibsim && \
    cd /tmp/ibsim && \
    make && \
    make install && \
    rm -rf /tmp/ibsim

# Set up simulated work environment
WORKDIR /workspace

# Generate simplified working fabric topology
RUN echo '# Simple InfiniBand Fabric - 1 Switch + 4 Hosts' > my_fabric.topo && \
    echo '' >> my_fabric.topo && \
    echo 'Switch  24  "S-0x0002c902002001"     0x0002c902002001' >> my_fabric.topo && \
    echo 'Hca     1   "H-0x0002c902002002"     0x0002c902002002' >> my_fabric.topo && \
    echo 'Hca     1   "H-0x0002c902002003"     0x0002c902002003' >> my_fabric.topo && \
    echo 'Hca     1   "H-0x0002c902002004"     0x0002c902002004' >> my_fabric.topo && \
    echo 'Hca     1   "H-0x0002c902002005"     0x0002c902002005' >> my_fabric.topo && \
    echo '' >> my_fabric.topo && \
    echo '0x0002c902002002    1       0x0002c902002001    1' >> my_fabric.topo && \
    echo '0x0002c902002003    1       0x0002c902002001    2' >> my_fabric.topo && \
    echo '0x0002c902002004    1       0x0002c902002001    3' >> my_fabric.topo && \
    echo '0x0002c902002005    1       0x0002c902002001    4' >> my_fabric.topo

# Create automated startup script for IB simulation
RUN echo '#!/bin/bash' > /usr/local/bin/start-ib-sim.sh && \
    echo 'set -e' >> /usr/local/bin/start-ib-sim.sh && \
    echo '' >> /usr/local/bin/start-ib-sim.sh && \
    echo 'echo "=========================================="' >> /usr/local/bin/start-ib-sim.sh && \
    echo 'echo "InfiniBand Fabric Simulator Starting..."' >> /usr/local/bin/start-ib-sim.sh && \
    echo 'echo "=========================================="' >> /usr/local/bin/start-ib-sim.sh && \
    echo 'echo ""' >> /usr/local/bin/start-ib-sim.sh && \
    echo '' >> /usr/local/bin/start-ib-sim.sh && \
    echo '# Start ibsim in background with -s (start simulation)' >> /usr/local/bin/start-ib-sim.sh && \
    echo 'echo "[1/4] Starting ibsim simulator..."' >> /usr/local/bin/start-ib-sim.sh && \
    echo 'ibsim -s /workspace/my_fabric.topo &' >> /usr/local/bin/start-ib-sim.sh && \
    echo 'IBSIM_PID=$!' >> /usr/local/bin/start-ib-sim.sh && \
    echo 'echo "       ibsim started (PID: $IBSIM_PID)"' >> /usr/local/bin/start-ib-sim.sh && \
    echo '' >> /usr/local/bin/start-ib-sim.sh && \
    echo '# Wait for ibsim to initialize and create umad devices' >> /usr/local/bin/start-ib-sim.sh && \
    echo 'echo "[2/4] Waiting for fabric initialization..."' >> /usr/local/bin/start-ib-sim.sh && \
    echo 'sleep 6' >> /usr/local/bin/start-ib-sim.sh && \
    echo 'ls -la /dev/infiniband/ 2>/dev/null || echo "Waiting for IB devices..."' >> /usr/local/bin/start-ib-sim.sh && \
    echo '' >> /usr/local/bin/start-ib-sim.sh && \
    echo '# Start OpenSM (Subnet Manager) with umad2sim for ibsim communication' >> /usr/local/bin/start-ib-sim.sh && \
    echo 'echo "[3/4] Starting OpenSM Subnet Manager..."' >> /usr/local/bin/start-ib-sim.sh && \
    echo 'LD_PRELOAD=/usr/lib/umad2sim/libumad2sim.so opensm -F /var/log/opensm.log -f /var/log/opensm-verbose.log &' >> /usr/local/bin/start-ib-sim.sh && \
    echo 'OPENSM_PID=$!' >> /usr/local/bin/start-ib-sim.sh && \
    echo 'echo "       OpenSM started with umad2sim (PID: $OPENSM_PID)"' >> /usr/local/bin/start-ib-sim.sh && \
    echo '' >> /usr/local/bin/start-ib-sim.sh && \
    echo '# Wait for OpenSM to discover fabric' >> /usr/local/bin/start-ib-sim.sh && \
    echo 'sleep 5' >> /usr/local/bin/start-ib-sim.sh && \
    echo '' >> /usr/local/bin/start-ib-sim.sh && \
    echo 'echo "[4/4] Fabric discovery complete!"' >> /usr/local/bin/start-ib-sim.sh && \
    echo 'echo ""' >> /usr/local/bin/start-ib-sim.sh && \
    echo 'echo "=========================================="' >> /usr/local/bin/start-ib-sim.sh && \
    echo 'echo "InfiniBand Simulation Ready"' >> /usr/local/bin/start-ib-sim.sh && \
    echo 'echo "=========================================="' >> /usr/local/bin/start-ib-sim.sh && \
    echo 'echo ""' >> /usr/local/bin/start-ib-sim.sh && \
    echo 'echo "Topology: /workspace/my_fabric.topo"' >> /usr/local/bin/start-ib-sim.sh && \
    echo 'echo "OpenSM Log: /var/log/opensm.log"' >> /usr/local/bin/start-ib-sim.sh && \
    echo 'echo ""' >> /usr/local/bin/start-ib-sim.sh && \
    echo 'echo "Available Commands (use with LD_PRELOAD=/usr/lib/umad2sim/libumad2sim.so):"' >> /usr/local/bin/start-ib-sim.sh && \
    echo 'echo "  LD_PRELOAD=/usr/lib/umad2sim/libumad2sim.so ibstat"' >> /usr/local/bin/start-ib-sim.sh && \
    echo 'echo "  LD_PRELOAD=/usr/lib/umad2sim/libumad2sim.so ibnetdiscover"' >> /usr/local/bin/start-ib-sim.sh && \
    echo 'echo "  LD_PRELOAD=/usr/lib/umad2sim/libumad2sim.so smpquery NI 1 1"' >> /usr/local/bin/start-ib-sim.sh && \
    echo 'echo "  LD_PRELOAD=/usr/lib/umad2sim/libumad2sim.so saquery"' >> /usr/local/bin/start-ib-sim.sh && \
    echo 'echo ""' >> /usr/local/bin/start-ib-sim.sh && \
    echo 'echo "Or set: export LD_PRELOAD=/usr/lib/umad2sim/libumad2sim.so"' >> /usr/local/bin/start-ib-sim.sh && \
    echo 'echo ""' >> /usr/local/bin/start-ib-sim.sh && \
    echo '' >> /usr/local/bin/start-ib-sim.sh && \
    echo '# Set up environment and drop to shell' >> /usr/local/bin/start-ib-sim.sh && \
    echo 'export LD_PRELOAD=/usr/lib/umad2sim/libumad2sim.so' >> /usr/local/bin/start-ib-sim.sh && \
    echo 'export PS1="[\u@ibsim \W]\\$ "' >> /usr/local/bin/start-ib-sim.sh && \
    echo 'echo "Environment configured. You can now run IB commands directly:"' >> /usr/local/bin/start-ib-sim.sh && \
    echo 'echo "  ibstat, ibnetdiscover, saquery, etc."' >> /usr/local/bin/start-ib-sim.sh && \
    echo 'echo ""' >> /usr/local/bin/start-ib-sim.sh && \
    echo 'exec /bin/bash' >> /usr/local/bin/start-ib-sim.sh && \
    chmod +x /usr/local/bin/start-ib-sim.sh

# Set the startup script as the default command
CMD ["/usr/local/bin/start-ib-sim.sh"]
