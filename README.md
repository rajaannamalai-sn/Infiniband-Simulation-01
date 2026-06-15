# InfiniBand Simulation with ibsim + UFM

A complete InfiniBand fabric simulation environment for learning and NVIDIA certification preparation.

## Overview

This project provides a fully functional InfiniBand simulation using:
- **ibsim** - InfiniBand subnet manager simulator
- **OpenSM** - Subnet Manager
- **UFM Enterprise** - NVIDIA Unified Fabric Manager (optional)
- **Spine-Leaf Topology** - 2 spine switches, 2 leaf switches, 4 hosts

## Architecture

```
           Spine-1 (LID 1)    Spine-2 (LID 2)
                ↕                   ↕
           Leaf-1 (LID 3) ←→  Leaf-2 (LID 4)
             ↕    ↕             ↕    ↕
          Host-1 Host-2     Host-3 Host-4
          (LID 5)(LID 6)    (LID 7)(LID 8)
```

## Quick Start

### Option 1: Docker on macOS (ibsim CLI only)

```bash
# Start ibsim with spine-leaf topology
docker run -d --name ib-sim-active \
  -v "$(pwd)/spine_leaf_fabric.topo:/workspace/my_fabric.topo" \
  -p 5000:5000 ib-simulator:latest tail -f /dev/null

# Start services
docker exec -d ib-sim-active ibsim -s /workspace/my_fabric.topo
docker exec -d ib-sim-active bash -c \
  'export LD_PRELOAD=/usr/lib/umad2sim/libumad2sim.so && opensm -g 0x2c90200300001'

# Test
docker exec -it ib-sim-active bash
export LD_PRELOAD=/usr/lib/umad2sim/libumad2sim.so
ibswitches
ibtracert 5 8
```

### Option 2: UTM VM (Full UFM GUI)

For UFM Enterprise with GUI on Apple Silicon:

1. **Install UTM** and create Ubuntu 22.04 x86_64 VM
2. **Run setup script** in VM:
   ```bash
   ./utm_setup_commands.sh
   exit  # Log out and back in
   ```
3. **Start services**:
   ```bash
   ./start_ibsim_ufm.sh
   ```
4. **Access UFM**: `https://<VM-IP>:9080`
   - Username: `admin`
   - Password: `admin123`

## Features

### Network Topology
- **4 Switches**: 2 spine (core), 2 leaf (access)
- **4 Hosts**: Connected to leaf switches
- **Full mesh**: Between spine and leaf tiers
- **Redundancy**: Multiple paths, ECMP routing

### Visualization Tools
- `topology_visualizer.sh` - ASCII dashboard
- `ibtracert` - Hop-by-hop path tracing
- `saquery` - Path statistics
- UFM Web GUI (with UTM setup)

### Documentation
- `HOST_COMMANDS_GUIDE.txt` - Complete command reference
- `SPINE_LEAF_TOPOLOGY_GUIDE.txt` - Architecture details
- `SPINE_LEAF_QUICK_START.txt` - Quick reference
- `UFM_INTEGRATION_GUIDE.txt` - UFM setup options

## Key Commands

```bash
# Fabric discovery
ibnetdiscover
ibswitches
ibhosts

# Path tracing (shows every hop)
ibtracert 5 8  # Host-1 to Host-4

# Path statistics
saquery --src-to-dst 5:8

# Performance monitoring
perfquery 1 1  # Spine-1 port 1

# Routing tables
ibroute 1  # Spine-1 routing
```

## Project Structure

```
IBSimulation-01/
├── spine_leaf_fabric.topo          # Topology definition
├── fixed_fabric.topo                # Simple 2-host topology
├── topology_visualizer.sh           # Dashboard script
├── utm_setup_commands.sh            # UTM VM setup
├── start_ibsim_ufm.sh              # Start services in UTM
├── Dockerfile                       # ibsim container
└── Documentation/
    ├── HOST_COMMANDS_GUIDE.txt
    ├── SPINE_LEAF_TOPOLOGY_GUIDE.txt
    ├── SPINE_LEAF_QUICK_START.txt
    ├── UFM_INTEGRATION_GUIDE.txt
    └── UFM_SETUP_README.txt
```

## Learning Path

### Week 1: CLI Mastery
- Use ibsim with Docker
- Practice all IB commands
- Master `ibtracert` and `saquery`
- Run `topology_visualizer.sh` daily

### Week 2: UFM GUI
- Set up UTM VM (optional)
- Or use NVIDIA AIR: https://air.nvidia.com
- Explore UFM interface
- Compare CLI vs GUI workflows

### Week 3: Advanced Topics
- Trace all 16 host-to-host paths
- Study ECMP load balancing
- Test fault tolerance scenarios
- Practice troubleshooting

## Use Cases

- **NVIDIA Certification Prep** - Hands-on practice for IB exams
- **Learning InfiniBand** - Understanding subnet management
- **Topology Design** - Test custom fabric layouts
- **Path Analysis** - Study routing and ECMP
- **Troubleshooting Practice** - Simulate failure scenarios

## Requirements

### Docker Setup (macOS)
- Docker Desktop
- 4GB RAM available
- macOS 11+ (any Mac)

### UTM Setup (for UFM GUI)
- UTM app (free)
- 16GB RAM (8GB for VM)
- 80GB free disk space
- Apple Silicon or Intel Mac

## Alternatives

### NVIDIA AIR (Recommended for UFM)
Free cloud-based InfiniBand labs:
- URL: https://air.nvidia.com
- No installation required
- Full UFM Enterprise GUI
- Multiple topology scenarios
- Perfect for certification prep

## Troubleshooting

### Docker on macOS
```bash
# Container won't start
docker logs ib-sim-active

# Commands fail
export LD_PRELOAD=/usr/lib/umad2sim/libumad2sim.so

# Restart services
docker restart ib-sim-active
```

### UTM VM
```bash
# Check IB modules
lsmod | grep ib_

# Verify devices
ls /dev/infiniband/

# UFM status
docker exec ufm /opt/ufm/scripts/ufm status
```

## Resources

### InfiniBand Documentation
- OpenFabrics Alliance: https://www.openfabrics.org
- InfiniBand Architecture: https://www.infinibandta.org

### NVIDIA Resources
- UFM Documentation: NVIDIA docs portal
- NVIDIA AIR: https://air.nvidia.com
- Training: https://www.nvidia.com/en-us/training/

### Community
- OpenSM Wiki
- Linux RDMA mailing lists

## Contributing

Contributions welcome! Areas for improvement:
- Additional topology examples
- More visualization tools
- Advanced testing scenarios
- Documentation enhancements

## License

This project is for educational purposes. Individual components have their own licenses:
- ibsim: OpenIB BSD license
- OpenSM: OpenIB BSD/GPL license
- UFM: NVIDIA proprietary (requires license)

## Acknowledgments

- OpenFabrics Alliance for ibsim
- NVIDIA for UFM Enterprise
- InfiniBand Trade Association

## Author

Created for NVIDIA InfiniBand certification preparation

## Status

✅ **Production Ready**
- ibsim simulation: Fully functional
- CLI tools: Complete and tested
- Documentation: Comprehensive
- UFM integration: Documented (UTM or NVIDIA AIR)

Perfect for NVIDIA certification exam preparation! 🎯
