create extension "uuid-ossp";
create extension pg_migrate;
SELECT upgrade_statement from migrations.revision;
