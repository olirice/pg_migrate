EXTENSION = pg_migrate	# the extensions name
DATA = ./src/sql/pg_migrate--0.0.1.sql  # script files to install

# postgres build stuff
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

