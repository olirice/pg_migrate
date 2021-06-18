# pg_migrate

A PostgreSQL Extension adding DDL tracking and migration tooling.



## API

- migrations.revision
- migrations.persist_ddl()
- TODO: migrations.upgrade(revision_id_or_tag text)
- TODO: migrations.downgrade(revision_id_or_tag text)
- TODO: migrations.merge(revision_id, revision_id)
- TODO: migrations.export()



### Installation

Requires:

 - Postgres 11+


```shell
git clone https://github.com/olirice/pg_migrate.git
cd pg_migrate
make install
```

### Testing
Requires:

 - Postgres 11+


```shell
PGUSER=postgres make install && PGUSER=postgres make installcheck
```

### Usage

Setup
```shell
createdb pgmig
createuser -s postgres
```

Launch postgres repl with
```
psql -d pgmig -U postgres
```

In PSQL
```sql
create extension pg_migrate;

-- Confirm everything worked
select * from migrations.revision
```

