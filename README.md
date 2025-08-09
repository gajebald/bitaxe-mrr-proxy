# bitaxe-mrr-proxy

Ein einfacher Stratum‑Proxy für Bitaxe Gamma 601 und MiningRigRentals. Er leitet Stratum‑V1‑Datenverkehr an MiningRigRentals weiter und hilft dabei, Redirects zu umgehen. Die Implementierung basiert auf Python 3 und `asyncio`.

## Installation

1. **Repository klonen**:
   ```bash
   git clone https://github.com/gajebald/bitaxe-mrr-proxy.git
   cd bitaxe-mrr-proxy
   ```

2. **Python-Abhängigkeiten**: Es sind keine zusätzlichen Bibliotheken erforderlich; Python 3.8 oder neuer genügt. Optional können Sie eine virtuelle Umgebung nutzen:

   ```bash
   python3 -m venv venv
   source venv/bin/activate
   ```

## Nutzung

Starten Sie den Proxy mit den folgenden Parametern:

```bash
python3 stratum_minimal_proxy.py \
  --listen-port 3333 \
  --pool-host eu-de02.miningrigrentals.com \
  --pool-port 3333 \
  --user gajebald.318975 \
  --passw x
```

- `--listen-port`: Port, an dem Ihr Bitaxe-Miner sich mit dem Proxy verbindet (z. B. 3333).
- `--pool-host`: Adresse des MiningRigRentals‑Servers (z. B. `eu-de02.miningrigrentals.com`).
- `--pool-port`: Port des Pools. MiningRigRentals kann per `client.reconnect` auf einen anderen Port verweisen; in diesem Fall muss der Wert angepasst werden.
- `--user`: Ihr MiningRigRentals‑Benutzername inklusive Worker‑Suffix (Beispiel: `gajebald.318975`).
- `--passw`: Passwort (bei MRR meist `x`, oder ein individuelles Kennwort).

## Bitaxe konfigurieren

Tragen Sie im Bitaxe‑Webinterface als Pool‑Adresse die IP‑Adresse Ihres Raspberry Pi und den Listen‑Port ein, z. B. `192.168.178.69:3333`. Benutzername und Passwort können leer bleiben, da der Proxy diese automatisch an MiningRigRentals übergibt.

## Autostart mit systemd

Um den Proxy automatisch nach jedem Neustart zu starten, können Sie einen systemd‑Dienst einrichten. Legen Sie eine Datei `/etc/systemd/system/stratum-proxy.service` mit folgendem Inhalt an (Pfad und Benutzernamen gegebenenfalls anpassen):

```ini
[Unit]
Description=Stratum Mining Proxy
After=network.target

[Service]
ExecStart=/usr/bin/python3 /home/pi/bitaxe-mrr-proxy/stratum_minimal_proxy.py \
  --listen-port 3333 \
  --pool-host eu-de02.miningrigrentals.com \
  --pool-port 3333 \
  --user gajebald.318975 \
  --passw x
WorkingDirectory=/home/pi/bitaxe-mrr-proxy
User=pi
Restart=always

[Install]
WantedBy=multi-user.target
```

Aktivieren Sie den Dienst anschließend mit:

```bash
sudo systemctl daemon-reload
sudo systemctl enable stratum-proxy.service
sudo systemctl start stratum-proxy.service
```

## Hinweise

- MiningRigRentals antwortet gelegentlich mit `client.reconnect`‑Meldungen, um den Port zu wechseln. Wenn der Proxy ständig Verbindungen öffnet und schließt, lesen Sie die Logs und passen Sie `--pool-port` entsprechend an.
- Das Logging des Proxys ist bewusst auf INFO reduziert, sodass nur relevante Ereignisse wie Verbindungsaufbau oder Fehler ausgegeben werden.
- Der Proxy kümmert sich um das Weiterleiten der Anmeldedaten; Sie müssen diese nicht im Bitaxe eingeben.

