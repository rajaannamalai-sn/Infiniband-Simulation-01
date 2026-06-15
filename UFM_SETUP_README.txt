================================================================================
UFM ENTERPRISE + IBSIM SETUP - APPLE SILICON (ARM64)
================================================================================

Status: UFM Docker image successfully downloaded (4.5GB)
Platform: Running AMD64 image on ARM64 Mac using Rosetta 2 emulation

================================================================================
WHAT WE'VE SET UP
================================================================================

✓ UFM Enterprise Docker image pulled (mellanox/ufm-enterprise:latest)
✓ Platform emulation configured (linux/amd64 on ARM64)
✓ Integration scripts created

Scripts Created:
  1. start_ufm.sh      - Starts UFM container connected to ibsim
  2. configure_ufm.sh  - Configures UFM to discover simulated fabric

================================================================================
QUICK START GUIDE
================================================================================

Step 1: Start UFM Container
----------------------------
./start_ufm.sh

What this does:
  • Stops any existing UFM container
  • Creates data directories (~/.ufm-data/)
  • Starts UFM container in AMD64 emulation mode
  • Connects UFM to ibsim network namespace
  • Waits for UFM services to initialize (60-90 seconds)


Step 2: Configure UFM for ibsim
--------------------------------
./configure_ufm.sh

What this does:
  • Installs umad2sim library in UFM container
  • Sets up environment for simulation mode
  • Restarts UFM services with LD_PRELOAD
  • Triggers fabric discovery


Step 3: Access UFM Web GUI
---------------------------
Open browser to: https://localhost:9080

Credentials:
  Username: admin
  Password: admin123

Accept the self-signed certificate warning

Initial login may show setup wizard - follow prompts


Step 4: Verify Fabric Discovery
--------------------------------
In UFM GUI:
  1. Navigate to "Topology" or "System" tab
  2. Should see: 4 switches, 4 hosts
  3. View topology diagram
  4. Explore devices and connections

================================================================================
IMPORTANT NOTES ABOUT ARM64 EMULATION
================================================================================

Performance:
  ⚠️  UFM runs in AMD64 emulation mode (Rosetta 2)
  ⚠️  Expect slower performance than native
  ⚠️  Web GUI may be sluggish
  ⚠️  First load can take 2-3 minutes

Compatibility:
  ✓  Basic UFM functionality should work
  ⚠️  Some advanced features may have issues
  ⚠️  Performance monitoring may be limited
  ⚠️  Not officially supported by NVIDIA

Recommendations:
  • Use for learning and GUI exploration only
  • For production testing, use x86_64 Linux host
  • For certification prep, consider NVIDIA AIR instead

================================================================================
TROUBLESHOOTING
================================================================================

Problem: UFM container won't start
Solution:
  docker logs ufm
  # Check for error messages
  # Restart: docker restart ufm

Problem: Web GUI not accessible
Solution:
  # Check if UFM services are running
  docker exec ufm ps aux | grep ufm

  # Check UFM status
  docker exec ufm /opt/ufm/scripts/ufm status

  # Restart UFM services
  docker exec ufm /opt/ufm/scripts/ufm restart

Problem: No devices discovered
Solution:
  # Verify ibsim is running
  docker exec ib-sim-active ps aux | grep ibsim

  # Check if umad2sim is loaded in UFM
  docker exec ufm bash -c 'echo $LD_PRELOAD'

  # Manually trigger discovery
  docker exec ufm bash -c 'export LD_PRELOAD=/usr/lib/umad2sim/libumad2sim.so && ibstat'

Problem: Slow performance / GUI freezes
Solution:
  • This is expected with ARM64 emulation
  • Close other applications to free resources
  • Consider using NVIDIA AIR instead (native performance)

Problem: Port 9080 already in use
Solution:
  # Find what's using the port
  lsof -i :9080

  # Stop UFM and restart with different port
  docker stop ufm
  # Edit start_ufm.sh to change UFM_PORT variable

================================================================================
NETWORK ARCHITECTURE
================================================================================

How UFM connects to ibsim:

┌─────────────────────────────────────────────────────┐
│  Docker Host (Your Mac)                             │
│                                                      │
│  ┌────────────────────┐    ┌────────────────────┐  │
│  │  UFM Container     │    │  ibsim Container   │  │
│  │  (AMD64 emulated)  │    │  (ARM64 native)    │  │
│  │                    │    │                    │  │
│  │  Port: 9080        │◄───┤  Shared Network    │  │
│  │                    │    │  Namespace         │  │
│  │  Uses umad2sim ────┼────►  /dev/infiniband/  │  │
│  │                    │    │  umad simulation   │  │
│  └────────────────────┘    └────────────────────┘  │
│         ▲                                           │
│         │                                           │
│   https://localhost:9080                            │
└─────────────────────────────────────────────────────┘

Key points:
• UFM shares network namespace with ibsim (--network container:ib-sim-active)
• UFM uses umad2sim library to access simulated IB devices
• Both containers see the same simulated fabric

================================================================================
VERIFICATION CHECKLIST
================================================================================

After setup, verify:

□ UFM container is running
  docker ps | grep ufm

□ UFM services are active
  docker exec ufm /opt/ufm/scripts/ufm status

□ umad2sim is loaded
  docker exec ufm bash -c 'echo $LD_PRELOAD'

□ UFM can see IB devices
  docker exec ufm bash -c 'export LD_PRELOAD=/usr/lib/umad2sim/libumad2sim.so && ibstat'

□ Web GUI is accessible
  curl -k https://localhost:9080

□ Can log in to web interface
  Open browser: https://localhost:9080

□ Fabric devices are discovered
  Check "Topology" tab in UFM GUI

================================================================================
STOPPING UFM
================================================================================

Stop UFM container:
  docker stop ufm

Remove UFM container:
  docker rm ufm

Restart UFM:
  ./start_ufm.sh
  ./configure_ufm.sh

View UFM logs:
  docker logs ufm -f

================================================================================
DATA PERSISTENCE
================================================================================

UFM data is stored in:
  ~/.ufm-data/
    ├── files/     - Configuration files
    ├── logs/      - UFM log files
    ├── db/        - Database files

To reset UFM (fresh start):
  docker stop ufm
  docker rm ufm
  rm -rf ~/.ufm-data/
  ./start_ufm.sh
  ./configure_ufm.sh

================================================================================
ALTERNATIVE: NVIDIA AIR (STILL RECOMMENDED)
================================================================================

If you encounter issues with ARM64 emulation, remember that NVIDIA AIR
provides a better experience:

Advantages of NVIDIA AIR:
  ✓ Native x86_64 performance (no emulation)
  ✓ No local resources consumed
  ✓ Pre-configured environments
  ✓ Multiple topology scenarios
  ✓ Always up-to-date
  ✓ Official NVIDIA support
  ✓ Free to use

Access: https://air.nvidia.com

Use local UFM for:
  • Offline learning
  • Custom topology testing with ibsim
  • Understanding UFM architecture

Use NVIDIA AIR for:
  • Production-like experience
  • Certification preparation
  • Performance testing
  • Advanced features

================================================================================
NEXT STEPS
================================================================================

1. Run the setup:
   ./start_ufm.sh
   ./configure_ufm.sh

2. Access UFM GUI:
   https://localhost:9080

3. Explore the interface:
   • Topology view
   • Device inventory
   • Performance monitoring
   • Configuration options

4. Compare with CLI:
   • Run ibtracert in ibsim
   • Compare with UFM path visualization
   • Understand GUI vs CLI workflows

5. Practice scenarios:
   • Identify devices
   • Trace paths
   • Check fabric health
   • View performance counters

================================================================================
