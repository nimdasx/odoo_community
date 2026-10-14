# Odoo 20 Community

## Instalasi

```bash
# 1. Clone/pull source Odoo & addons, lalu build image Odoo 20 (dari folder induk)
cd .. && ./pull.sh && ./odoo_docker_image/build.sh && cd odoo_community

# 2. Siapkan config
cp .env.sample .env                     # untuk prod: pakai COMPOSE_FILE prod di .env
cp odoo.conf.sample.dev odoo.conf       # untuk prod: odoo.conf.sample.prod

# 3. Jalankan
docker compose up -d
```

Odoo: `localhost:<ODOO_PORT>`, pgAdmin: `localhost:<PGADMIN_PORT>` (lihat `.env`).

## Update modul

```bash
./update-module.sh <database> <modul1> [modul2] ...
```
