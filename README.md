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

Buka Odoo di `http://localhost:<ODOO_PORT>` dan pgAdmin di `http://localhost:<PGADMIN_PORT>` (port ada di `.env`).

## Update modul

```bash
./update-module.sh <database> <modul1> [modul2] ...
```

## Update image Odoo

Image `odoo20-local` dibuild dari [odoo/docker 20.0](https://github.com/odoo/docker/tree/master/20.0) karena `odoo:20` belum ada di Docker Hub.

```bash
../odoo_docker_image/build.sh && docker compose up -d
```
