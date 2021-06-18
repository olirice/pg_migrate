EXTENSION = pg_migrate	# the extensions name
DATA = sql/pg_migrate--0.0.1.sql  # script files to install
REGRESS = pg_migrate_test

# postgres build stuff
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
