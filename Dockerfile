FROM postgres:latest

COPY Makefile tmp/pg_migrate/Makefile
COPY pg_migrate.control tmp/pg_migrate/pg_migrate.control
COPY sql tmp/pg_migrate/sql

RUN apt-get update \
    && apt-get install build-essential -y --no-install-recommends \
    && cd tmp/pg_migrate \
    && make install \
    && apt-get clean \
    && apt-get remove build-essential -y \
    && apt-get autoremove -y \
    && rm -rf /tmp/pg_migrate /var/lib/apt/lists/* /var/tmp/*
