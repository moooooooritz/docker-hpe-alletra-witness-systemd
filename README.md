# HPE Alletra / Nimble Witness in Docker (Rocky Linux + systemd)

[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://docker.com)

A containerized HPE Nimble/Alletra Witness service running on Rocky Linux with systemd.

## Disclaimer
This Docker container setup is **not officially supported by HPE**. It provides a modern alternative to running the Witness on an outdated CentOS 7 VM, but use at your own risk and ensure compatibility with your environment.

## Features

- Based on Rocky Linux 8.4 with systemd
- Includes health checks
- Supports persistent data mounts (private data, certificates, logs)
- Easy deployment with Docker Compose
- Automatically creates witness user with configurable password

## Overview
This setup creates a containerized **HPE Nimble/Alletra Witness** based on **Rocky Linux 8.4** with systemd.
It is designed for HPE Alletra systems based on NimbleOS (e.g., Alletra 5000, 6000).
It includes:
- a Dockerfile to build the image
- a `docker-compose.yml` for start & healthcheck
- all necessary commands to prepare host directories

---

## 1. Prerequisites
- Docker and Docker Compose installed
- Witness-RPM in project directory:
  `hpe-alletra-witness-<version>.rpm` (obtain from infosight.hpe.com)
- Host must support systemd-based containers (`--privileged`, `/sys/fs/cgroup` mounted)
- Witness user is created automatically with default password "witness123" (configurable via `WITNESS_PASSWORD` environment variable)

---

## 2. Directory Structure

```
/docker/witness2
├── Dockerfile
├── docker-compose.yml
├── hpe-alletra-witness-<version>.rpm
├── log/
└── witness/
    ├── private/
    └── certs/
```

---

## 3. Build Image

```bash
cd /docker/witness2
docker build -t hpe-witness:1 .
```

---

## 4. First Start (without private mount)

1. In `docker-compose.yml` comment out the line
   ```yaml
   - ./witness/private:/opt/NimbleStorage/witness/var/private
   ```

2. Start container:
   ```bash
   docker compose up -d
   ```

3. Check:
   ```bash
   docker exec -it hpe-witness systemctl status nimble-witnessd
   ```
   → Service should be **active (running)**.

---

## 5. Copy Witness Data to Host

```bash
docker cp hpe-witness:/opt/NimbleStorage/witness/var/private ./witness
docker cp hpe-witness:/opt/NimbleStorage/witness/config/certs ./witness
```

Now exists on host: `./witness/private/...` and `./witness/certs/...`

---

## 6. Adjust UID/GID

Check in container:
```bash
docker exec -it hpe-witness getent passwd witness || docker exec -it hpe-witness id witness
```

Example output:
```
witness:x:1000:1000:...
```

Then on host:
```bash
sudo chown -R 1000:1000 ./witness ./log
sudo chmod -R 770 ./witness ./log
```
(Replace with other UID/GID if different. This sets permissions for private data, certificates, and logs.)

---

## 7. Activate Compose File with Mount

Restore `docker-compose.yml`:

```yaml
volumes:
  - /sys/fs/cgroup:/sys/fs/cgroup
  - ./log:/var/log/NimbleStorage
  - ./witness/private:/opt/NimbleStorage/witness/var/private
  - ./witness/certs:/opt/NimbleStorage/witness/config/certs
```

Then restart container:
```bash
docker compose up -d
```

Check status:
```bash
docker exec -it hpe-witness systemctl status nimble-witnessd
docker exec -it hpe-witness tail -n 200 /var/log/NimbleStorage/witnessd.log
```

---

## 8. Healthcheck

In the compose file is a healthcheck defined:

```yaml
healthcheck:
  test: ["CMD-SHELL", "systemctl is-active --quiet nimble-witnessd"]
  interval: 30s
  timeout: 5s
  retries: 3
  start_period: 40s
```

Docker shows the container as **healthy** once `systemd` reports that the service is running.

---

## 9. Troubleshooting

| Problem | Cause / Solution |
|----------|------------------|
| **Exit 134** | Usually wrong or incomplete content in `./witness/...`. Copy new directory from working container. |
| **Permission denied** | Host folders not set to container UID (`witness`) → `chown -R`. |
| **`array/` missing** | Normal – created only when an array registers with the Witness. |
| **Service does not start** | Check with `journalctl -u nimble-witnessd -xe` in container. |

Logs:
```bash
docker exec -it hpe-witness tail -f /var/log/NimbleStorage/witnessd.log
docker exec -it hpe-witness journalctl -u nimble-witnessd -f
```

---

## 10. Connection from Array
The Witness listens on port **5395**.
In the array under "Quorum Witness" enter the IP of the Docker host and port **5395**.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

© 2025 – Internal Documentation HPE Alletra Witness Container
