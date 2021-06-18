-- Create dependencies
create extension "uuid-ossp";


-- Create pg_migrate 
create extension pg_migrate;


-- Select from upgrade table
select upgrade_statement from migrations.revision;


-- Get revision_id
begin;
    create function test_fn () returns bool as $$ select true $$ language sql;
    select migrations.current_revision_id() is not null;
rollback;


-- Get revision
begin;
    create function test_fn () returns bool as $$ select true $$ language sql;
    select (migrations.current_revision()).id is not null;
rollback;


-- Execute register_downgrade
begin;
    create function test_fn () returns bool as $$ select true $$ language sql;
    select migrations.set_downgrade('drop function test_fn;') is not null;
rollback;

-- TODO: cut revision from statemetns
-- TODO: cut revision & apply downgrade
-- TODO: cut revision, apply downgarde, test revision
-- TODO: full migration cylce integration test
