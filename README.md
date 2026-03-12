# Bitfocus Companion - Proxmox VE LXC Helper Script

Installs [Bitfocus Companion](https://bitfocus.io/companion) in a Proxmox VE LXC container, tteck-style.

## Usage

Run the following command on your Proxmox host:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/glabutis/companion-proxmox/main/companion.sh)"
```

## Defaults

| Setting | Value |
|---------|-------|
| OS | Debian 12 |
| Disk | 8GB |
| CPU | 2 cores |
| RAM | 512MB |
| Network | DHCP |
| Type | Unprivileged |

You will be prompted to use these defaults or customize before anything is created.

## Access

Once installed, the Companion web UI is available at:

```
http://<LXC-IP>:8888
```

## Updating

To update Companion to the latest release, run the helper script again inside the LXC container:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/glabutis/companion-proxmox/main/companion.sh)"
```

It will detect an existing installation and update in place.
