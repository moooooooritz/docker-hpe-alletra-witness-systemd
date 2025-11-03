# HPE Alletra / Nimble Witness in Docker (Rocky Linux + systemd)

## Übersicht
Dieses Setup erstellt einen containerisierten **HPE Nimble/Alletra Witness** auf Basis von **Rocky Linux 8.4** mit systemd.  
Es enthält:
- ein Dockerfile zum Bauen des Images  
- ein `docker-compose.yml` für Start & Healthcheck  
- alle nötigen Befehle zur Vorbereitung der Host-Verzeichnisse  

---

## 1. Voraussetzungen
- Docker und Docker Compose installiert  
- Witness-RPM im Projektverzeichnis:  
  `hpe-alletra-witness-<version>.rpm`
- Host muss systemd-basierte Container unterstützen (`--privileged`, `/sys/fs/cgroup` gemountet)

---

## 2. Verzeichnisstruktur

```
/docker/witness2
├── Dockerfile
├── docker-compose.yml
├── hpe-alletra-witness-<version>.rpm
├── log/
└── witness/
```

---

## 3. Image bauen

```bash
cd /docker/witness2
docker build -t hpe-witness:1 .
```

---

## 4. Erster Start (ohne private-Mount)

1. In `docker-compose.yml` die Zeile  
   ```yaml
   - ./witness/private:/opt/NimbleStorage/witness/var/private
   ```  
   **auskommentieren**.

2. Container starten:
   ```bash
   docker compose up -d
   ```

3. Prüfen:
   ```bash
   docker exec -it hpe-witness systemctl status nimble-witnessd
   ```
   → Dienst sollte **active (running)** sein.

---

## 5. Witness-Daten auf den Host kopieren

```bash
docker cp hpe-witness:/opt/NimbleStorage/witness/var/private ./witness
```

Jetzt existiert auf dem Host: `./witness/private/...`

---

## 6. UID/GID anpassen

Im Container prüfen:
```bash
docker exec -it hpe-witness getent passwd witness || docker exec -it hpe-witness id witness
```

Beispielausgabe:
```
witness:x:1000:1000:...
```

Dann auf dem Host:
```bash
sudo chown -R 1000:1000 ./witness ./log
sudo chmod -R 770 ./witness ./log
```
(Bei anderer UID/GID diese Werte ersetzen.)

---

## 7. Compose-Datei mit Mount aktivieren

`docker-compose.yml` wiederherstellen:

```yaml
volumes:
  - /sys/fs/cgroup:/sys/fs/cgroup
  - ./log:/var/log/NimbleStorage
  - ./witness/private:/opt/NimbleStorage/witness/var/private
```

Dann Container neu starten:
```bash
docker compose up -d
```

Status prüfen:
```bash
docker exec -it hpe-witness systemctl status nimble-witnessd
docker exec -it hpe-witness tail -n 200 /var/log/NimbleStorage/witnessd.log
```

---

## 8. Healthcheck

In der Compose-Datei ist ein Healthcheck definiert:

```yaml
healthcheck:
  test: ["CMD-SHELL", "systemctl is-active --quiet nimble-witnessd"]
  interval: 30s
  timeout: 5s
  retries: 3
  start_period: 40s
```

Docker zeigt den Container als **healthy**, sobald `systemd` meldet, dass der Dienst läuft.

---

## 9. Troubleshooting

| Problem | Ursache / Lösung |
|----------|------------------|
| **Exit 134** | Meist falscher oder unvollständiger Inhalt in `./witness/...`. Neues Verzeichnis aus funktionierendem Container kopieren. |
| **Permission denied** | Host-Ordner nicht auf Container-UID (`witness`) gesetzt → `chown -R`. |
| **`array/` fehlt** | Normal – wird erst erzeugt, wenn sich ein Array beim Witness registriert. |
| **Dienst startet nicht** | Prüfen mit `journalctl -u nimble-witnessd -xe` im Container. |

Logs:
```bash
docker exec -it hpe-witness tail -f /var/log/NimbleStorage/witnessd.log
docker exec -it hpe-witness journalctl -u nimble-witnessd -f
```

---

## 10. Verbindung vom Array
Der Witness lauscht auf Port **5395**.  
Im Array unter „Quorum Witness“ die IP des Docker-Hosts und Port **5395** eintragen.

---

© 2025 – interne Dokumentation HPE Alletra Witness Container
