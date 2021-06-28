-- Create dependencies
create extension "uuid-ossp";


-- Create pg_migrate 
create extension pg_migrate;


-- Select from upgrade table
select stmt from migrations.statement;


-- current_statement_id
begin;
    create function test_fn () returns bool as $$ select true $$ language sql;
    select migrations.current_statement_id() is not null;
rollback;


-- current_statement
begin;
    create function test_fn () returns bool as $$ select true $$ language sql;
    select (migrations.current_statement()).id is not null;
rollback;


-- TODO: register a downgrade
-- TODO: cut revision from statemetns
-- TODO: cut revision & apply downgrade
-- TODO: cut revision, apply downgarde, test revision
-- TODO: full migration cylce integration test
