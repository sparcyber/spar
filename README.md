# Spar

Open-source cyber range orchestration. Deploy realistic, multi-team network environments from a single binary.

Spar automates the full lifecycle of cyber ranges on Proxmox — from VM provisioning and network topology to routing, configuration, and exercise management. It's designed for security teams who need production-grade training environments without vendor lock-in or paywalled features.

## Why Spar?

Most range tools give you flat, isolated networks with pre-configured services. Spar builds environments that mirror real-world architecture:

- **Realistic network topology** — Multi-team ranges with per-team OPNsense firewalls, OSPF/BGP backbone routing, VLAN segmentation via Proxmox SDN, and a simulated ISP uplink to real internet.
- **Clean exercise environment** — Management traffic runs over QEMU Guest Agent, not WinRM or SSH. Participants configure remote access and hardening themselves as part of the exercise.
- **Self-service for participants** — Blue teams get a scoped topology view where they can place inline network taps, manage their VMs, and architect their own monitoring — no Proxmox access required.
- **Purple team visibility** — Integrates with Mythic C2 to automatically correlate red team actions with blue team detections on a shared timeline.
- **Fully open-source** — CLI, web UI, and all features ship in a single binary. No enterprise tier.

## How It Works

Define a range in YAML:

```yaml
range:
  name: purple-team-exercise
  backbone:
    router_type: vyos
    uplink_nic: eno1
    protocol: ospf
    network: 10.0.0.0/24

  teams:
    - name: blue-team-1
      type: defender
      router: opnsense
      backbone_ip: 10.0.0.10/24
      networks:
        - name: corporate
          vlan: 10
          subnet: 172.16.1.0/24
          vms:
            - name: dc01
              template: win2022-server
              cpus: 4
              ram_gb: 8
              roles:
                - role: ad-domain-controller
                  vars:
                    domain: corp.local
            - name: ws01
              template: win11-enterprise
              cpus: 4
              ram_gb: 8
              roles:
                - role: domain-join
                  vars:
                    domain: corp.local
        - name: dmz
          vlan: 20
          subnet: 172.16.2.0/24
          vms:
            - name: web01
              template: debian-12
              cpus: 2
              ram_gb: 4
        - name: security
          vlan: 30
          subnet: 172.16.3.0/24
          vms:
            - name: siem01
              template: debian-12
              cpus: 4
              ram_gb: 16
              roles:
                - role: wazuh-server

    - name: red-team
      type: attacker
      router: opnsense
      backbone_ip: 10.0.0.50/24
      c2:
        platform: mythic
        integrate: true
      networks:
        - name: attack
          vlan: 10
          subnet: 10.66.1.0/24
          vms:
            - name: kali01
              template: kali-rolling
              cpus: 4
              ram_gb: 8
```

Deploy it:

```
$ spar deploy purple-team-exercise.yaml

 ✓ Creating SDN zone: purple-team-exercise
 ✓ Creating VNets: corporate, dmz, security, attack
 ✓ Deploying backbone router (VyOS)
 ✓ Deploying blue-team-1 router (OPNsense)
 ✓ Deploying red-team router (OPNsense)
 ✓ Cloning VMs: dc01, ws01, web01, siem01, kali01
 ✓ Waiting for guest agents...
 ✓ Configuring OSPF adjacencies
 ✓ Running Ansible roles via QGA
 ✓ Range deployed in 14m32s

  Dashboard:  https://spar.local:8443
  Blue team:  https://spar.local:8443/team/blue-team-1
  Red team:   https://spar.local:8443/team/red-team
```

## Features

### Range Orchestration
- Deploy complex multi-VM environments from a single YAML config
- Clone from Packer-built templates with parallel provisioning
- Snapshot, restore, pause, and resume entire ranges
- Lifecycle management: testing mode with selective internet blocking

### Networking
- Per-team OPNsense firewalls configured automatically
- Backbone routing via OSPF or BGP between teams
- Physical NIC uplink simulates ISP connectivity
- Proxmox SDN for VLAN segmentation and isolation
- Multi-team ranges with full network isolation between teams

### Configuration
- Post-deployment configuration via Ansible
- Custom connection plugin routes through QEMU Guest Agent — no WinRM or SSH needed for orchestration
- Compatible with existing Ansible Galaxy roles
- Zero management footprint on the exercise network

### Web UI
- Embedded HTMX dashboard with real-time status
- Interactive topology canvas for visual range design
- Role-based views: admin, participant, purple team
- Live deployment logs via server-sent events

### Participant Self-Service
- Scoped topology view per team — blue teams only see their own network
- Drag-and-drop inline tap insertion for network monitoring
- VM console access proxied through Spar
- Power management for team VMs

### Purple Team
- Mythic C2 webhook integration for automatic red team activity tracking
- Generic SIEM webhook endpoint for blue team detection ingestion
- Correlated timeline: red team actions mapped against blue team alerts
- Composite topology view showing both sides simultaneously
- Exercise pause/resume with VM snapshots for debrief

## Requirements

- **Proxmox VE 8+** with SDN configured
- **QEMU Guest Agent** installed in VM templates
- **Ansible** on the Spar host (for post-deployment configuration)
- **Packer** on the Spar host (for template builds)

### Hardware
- x86_64 CPU with virtualisation support
- 64GB+ RAM recommended for multi-team ranges
- Fast NVMe storage — template clones are I/O heavy
- Dedicated NIC for ISP uplink (optional, for internet-connected ranges)

## Quick Start

```bash
# Download the latest release
curl -LO https://github.com/sparcyber/spar/releases/latest/download/spar-linux-amd64
chmod +x spar-linux-amd64
sudo mv spar-linux-amd64 /usr/local/bin/spar

# Initialise Spar with your Proxmox connection
spar init \
  --proxmox-host https://proxmox.local:8006 \
  --proxmox-token "spar@pam!spar=your-token-uuid" \
  --uplink-nic eno1

# Build base templates
spar template build --all

# Deploy a range
spar deploy examples/simple-ad-lab.yaml

# Check status
spar status

# Open the web UI
spar serve
```

## Architecture

```
┌─────────────────────────────────────────────┐
│                  Spar Binary                 │
│                                              │
│  ┌─────────┐  ┌──────────┐  ┌────────────┐  │
│  │   CLI   │  │ HTTP/SSE │  │    MCP     │  │
│  │ (Cobra) │  │  (HTMX)  │  │  Server    │  │
│  └────┬────┘  └────┬─────┘  └─────┬──────┘  │
│       │            │              │          │
│  ┌────┴────────────┴──────────────┴──────┐   │
│  │           Core Library                │   │
│  │  Range lifecycle, config parsing,     │   │
│  │  network topology, state management   │   │
│  └────┬──────────┬───────────────┬───────┘   │
│       │          │               │           │
│  ┌────┴───┐ ┌────┴─────┐ ┌──────┴────────┐  │
│  │Proxmox │ │ Ansible  │ │   Packer      │  │
│  │API + QGA│ │(via QGA) │ │ (templates)   │  │
│  └────┬───┘ └──────────┘ └───────────────┘  │
└───────┼─────────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────┐
│            Proxmox VE                  │
│  VMs, SDN, Storage, QGA, Snapshots    │
└───────────────────────────────────────┘
```

## Status

Spar is in early development. See the [implementation plan](IMPLEMENTATION.md) for the current roadmap and progress.

## Contributing

Contributions are welcome. If you're interested in contributing, open an issue to discuss your idea before submitting a PR.

## License

[AGPLv3](LICENSE)
