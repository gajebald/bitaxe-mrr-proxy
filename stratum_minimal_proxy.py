#!/usr/bin/env python3
import asyncio
import argparse
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s'
)
logger = logging.getLogger(__name__)

async def handle_client(client_reader, client_writer, pool_host, pool_port):
    peername = client_writer.get_extra_info('peername')
    logger.info(f"🧑 Verbindung von Miner {peername}")

    try:
        pool_reader, pool_writer = await asyncio.open_connection(pool_host, pool_port)
        logger.info(f"⚓️ Verbindung zum Pool {pool_host}:{pool_port} hergestellt")

        async def forward(reader, writer, direction):
            try:
                while True:
                    data = await reader.read(4096)
                    if not data:
                        break
                    writer.write(data)
                    await writer.drain()
            except Exception as e:
                logger.warning(f"⚠️ Fehler bei Weiterleitung ({direction}): {e}")
            finally:
                writer.close()
                await writer.wait_closed()

        await asyncio.gather(
            forward(client_reader, pool_writer, "Miner ➜ Pool"),
            forward(pool_reader, client_writer, "Pool ➜ Miner")
        )
    except Exception as e:
        logger.error(f"❌ Fehler bei Verbindung: {e}")
    finally:
        client_writer.close()
        await client_writer.wait_closed()
        logger.info(f"🔌 Verbindung zu {peername} beendet")

async def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--listen-port', type=int, default=3333)
    parser.add_argument('--pool-host', type=str, required=True)
    parser.add_argument('--pool-port', type=int, required=True)
    parser.add_argument('--user', type=str, required=True)
    parser.add_argument('--passw', type=str, required=True)
    args = parser.parse_args()

    server = await asyncio.start_server(
        lambda r, w: handle_client(r, w, args.pool_host, args.pool_port),
        '0.0.0.0', args.listen_port
    )

    addr = server.sockets[0].getsockname()
    logger.info(f"✅ Proxy läuft auf {addr}")

    async with server:
        await server.serve_forever()

if __name__ == '__main__':
    asyncio.run(main())
