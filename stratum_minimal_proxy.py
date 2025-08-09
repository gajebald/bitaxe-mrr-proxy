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
    logger.info(f"🧍 Connection from miner {peername}")

    try:
        # Connect to the pool
        pool_reader, pool_writer = await asyncio.open_connection(pool_host, pool_port)
        logger.info(f"⛓️ Connected to pool {pool_host}:{pool_port}")

        async def forward(reader, writer, direction):
            try:
                while True:
                    data = await reader.read(4096)
                    if not data:
                        break
                    writer.write(data)
                    await writer.drain()
            except Exception as e:
                logger.warning(f"⚠️ Error while forwarding ({direction}): {e}")
            finally:
                try:
                    writer.close()
                    await writer.wait_closed()
                except Exception:
                    pass

        await asyncio.gather(
            forward(client_reader, pool_writer, "Miner ➜ Pool"),
            forward(pool_reader, client_writer, "Pool ➜ Miner")
        )
    except Exception as e:
        logger.error(f"❌ Error during connection: {e}")
    finally:
        try:
            client_writer.close()
            await client_writer.wait_closed()
        except Exception:
            pass
        logger.info(f"🔌 Connection to {peername} closed")

async def main():
    parser = argparse.ArgumentParser(description="Minimal Stratum proxy for MiningRigRentals")
    parser.add_argument('--listen-port', type=int, default=3333, help='Port on which the proxy accepts incoming connections')
    parser.add_argument('--pool-host', type=str, required=True, help='Hostname of the MiningRigRentals pool')
    parser.add_argument('--pool-port', type=int, required=True, help='Port of the MiningRigRentals pool')
    parser.add_argument('--user', type=str, required=True, help='Username (MRR) – currently not used by the proxy')
    parser.add_argument('--passw', type=str, required=True, help='Password (MRR) – currently not used by the proxy')
    args = parser.parse_args()

    server = await asyncio.start_server(
        lambda r, w: handle_client(r, w, args.pool_host, args.pool_port),
        '0.0.0.0', args.listen_port
    )

    addr = server.sockets[0].getsockname()
    logger.info(f"✅ Proxy running at {addr}")

    async with server:
        await server.serve_forever()

if __name__ == '__main__':
    asyncio.run(main())
