# AdGuard Home with Tailscale

A Docker/Podman-based deployment of [AdGuard Home](https://adguard.com/en/adguard-home/overview.html) integrated with [Tailscale](https://tailscale.com/) for secure network-wide ad blocking and privacy protection accessible from anywhere.

## Overview

This project provides a containerized setup that combines:

- **AdGuard Home**: Network-wide software for blocking ads and tracking
- **Tailscale**: Zero-config VPN for secure remote access to your DNS server

The integration allows you to use your private AdGuard Home DNS server from any device connected to your Tailscale network, providing ad blocking and privacy protection wherever you go.

## Features

- 🛡️ Network-wide ad blocking and tracker protection
- 🔒 Secure remote access via Tailscale VPN
- 🚀 Easy deployment with Docker/Podman Compose
- 🔧 Automated DNS configuration for Linux systems
- 📊 Web-based dashboard for statistics and configuration
- 🌐 Support for DNS-over-HTTPS, DNS-over-TLS, DNS-over-QUIC, and DNSCrypt
- 🏠 Optional DHCP server functionality

## Prerequisites

- Docker or Podman with compose support
- A [Tailscale account](https://login.tailscale.com/start) (free tier available)
- Linux system with systemd (for DNS setup script)

### Optional: Nix Development Environment

This project includes a Nix flake for reproducible development environments:

```bash
# Enter development shell with Podman and Podman Compose
nix develop
```

## Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd adblock
```

### 2. Configure Environment Variables

Create a `.env` file from the example:

```bash
cp .env.example .env
```

Edit `.env` and add your Tailscale authentication key:

```env
TS_AUTHKEY=tskey-auth-your-actual-key-here
```

**Getting a Tailscale Auth Key:**

1. Visit https://login.tailscale.com/admin/settings/keys
2. Generate a new auth key
3. Consider making it reusable and setting an appropriate expiration
4. Add the tag `container` to your ACL policy (or adjust `TS_EXTRA_ARGS` in [compose.yaml](compose.yaml))

### 3. Configure DNS (Linux with systemd-resolved)

If you're running on a Linux system using systemd-resolved, run the setup script to free port 53:

```bash
./setup-dns.sh
```

This script will:
- Configure systemd-resolved to use localhost DNS
- Disable the DNS stub listener
- Make port 53 available for AdGuard Home

### 4. Start the Services

Using Docker Compose:

```bash
docker compose up -d
```

Using Podman Compose:

```bash
podman-compose up -d
```

Or with Nix:

```bash
nix develop -c podman-compose up -d
```

### 5. Access AdGuard Home

The first time you start the services:

1. Wait a few moments for containers to initialize
2. Access the web interface at `http://localhost:3000` (or via Tailscale hostname)
3. Complete the initial setup wizard
4. Configure your DNS settings and filters

## Architecture

The setup uses a shared network stack where AdGuard Home operates through the Tailscale container's network interface:

```
┌─────────────────────────────────────┐
│         Tailscale Container         │
│  ┌───────────────────────────────┐  │
│  │    Network Interface          │  │
│  │  - Tailscale VPN              │  │
│  │  - Port 53 (DNS)              │  │
│  │  - Port 80/443 (HTTP/HTTPS)   │  │
│  │  - Port 3000 (Setup)          │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
              ▲
              │ network_mode: service:tailscale
              │
┌─────────────────────────────────────┐
│      AdGuard Home Container         │
│  - DNS filtering                    │
│  - Web dashboard                    │
│  - Statistics                       │
└─────────────────────────────────────┘
```

## Configuration

### Service Ports

The following ports are exposed on the Tailscale container:

| Port(s) | Protocol | Service |
|---------|----------|---------|
| 53 | TCP/UDP | DNS |
| 67-68 | TCP/UDP | DHCP |
| 80, 443 | TCP | HTTP/HTTPS |
| 443 | UDP | HTTP/3 (QUIC) |
| 3000 | TCP | Initial setup interface |
| 853 | TCP/UDP | DNS-over-TLS/QUIC |
| 784, 8853 | UDP | DNS-over-QUIC |
| 5443 | TCP/UDP | DNSCrypt |

### Data Persistence

Configuration and data are stored in local directories:

- `./adguard/conf/` - AdGuard Home configuration files
- `./adguard/work/` - Runtime data, logs, and statistics
- `./tailscale/state/` - Tailscale state and authentication

### Tailscale Configuration

Environment variables for the Tailscale container:

- `TS_AUTHKEY` - Your Tailscale authentication key (required)
- `TS_EXTRA_ARGS` - Additional Tailscale arguments (default: `--advertise-tags=tag:container`)
- `TS_STATE_DIR` - State directory path (default: `/var/lib/tailscale`)
- `TS_USERSPACE` - Use userspace networking (default: `false`)

### AdGuard Home Configuration

Environment variables:

- `TZ` - Timezone (default: `Asia/Seoul`)

## Usage

### Starting and Stopping

```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# View logs
docker compose logs -f

# Restart services
docker compose restart
```

### Accessing from Devices

1. Install Tailscale on your devices
2. Connect to your Tailscale network
3. Configure DNS settings to use your AdGuard Home server's Tailscale IP
4. Alternatively, configure Tailscale to use it as a global nameserver:
   ```bash
   tailscale set --accept-dns=true
   ```

### Updating

```bash
# Pull latest images
docker compose pull

# Recreate containers with new images
docker compose up -d
```

## Troubleshooting

### Port 53 Already in Use

If you get a "port 53 already in use" error:

1. Run the [setup-dns.sh](setup-dns.sh) script if using systemd-resolved
2. Or identify and stop the conflicting service:
   ```bash
   sudo lsof -i :53
   ```

### Tailscale Authentication Issues

If Tailscale fails to authenticate:

1. Verify your `TS_AUTHKEY` in `.env` is valid and not expired
2. Check the Tailscale container logs:
   ```bash
   docker compose logs tailscale
   ```
3. Generate a new auth key if needed

### AdGuard Home Not Accessible

1. Ensure both containers are running:
   ```bash
   docker compose ps
   ```
2. Check that AdGuard Home completed its initial setup at `http://localhost:3000`
3. Verify network connectivity through Tailscale
4. Check logs for errors:
   ```bash
   docker compose logs adguard
   ```

### Cannot Access Initial Setup (Port 3000)

The setup interface on port 3000 is only needed during initial configuration. If you can't access it:

1. Verify the Tailscale container is running and healthy
2. Check if you can access it via localhost: `http://localhost:3000`
3. After initial setup, use port 80 or 443 for regular access

## Security Considerations

- **Auth Keys**: Never commit your actual Tailscale auth key to version control
- **Access Control**: Use Tailscale ACLs to restrict access to the DNS server
- **Updates**: Regularly update both AdGuard Home and Tailscale images
- **Backups**: Periodically backup the `./adguard/conf/` directory

## License

This is a configuration repository. Please refer to the licenses of the individual components:

- [AdGuard Home License](https://github.com/AdguardTeam/AdGuardHome/blob/master/LICENSE.txt)
- [Tailscale Terms](https://tailscale.com/terms)

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## Acknowledgments

- [AdGuard Home](https://github.com/AdguardTeam/AdGuardHome) - Network-wide ads & trackers blocking DNS server
- [Tailscale](https://tailscale.com/) - Zero config VPN built on WireGuard
