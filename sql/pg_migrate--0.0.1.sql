-----------------
-- Persistence -- 
-----------------

-- create extension if not exists "uuid-ossp";
create schema migrations;

create table migrations.revision (
	id uuid primary key default uuid_generate_v4(),
	-- SQL Contents
	upgrade_statement text not null,
	-- TODO: Allow manual population
	downgrade_statement text,
	-- Is this the current revision of the database
	-- Only 1 row may be 'true'
	is_current bool not null default false,
	-- Human readable message
	"message" text,
	-- Immediately preceeding revision.ids
	-- Multiple parents are allowed for branch merging
	parent_ids uuid[] not null default '{}'::uuid[],
	-- Human readable name
	tags text[] not null default '{}'::text[],
	-- Transaction id
	txid bigint not null default txid_current(),
	created_at timestamp not null default (now() at time zone 'utc'),
	exclude (is_current with =) where (is_current)
);

-- Registry of every DDL statement
create table migrations.statement (
	id uuid primary key default uuid_generate_v4(),
	stmt text not null,
	is_current bool not null default false,
	parent_id uuid not null,
	txid bigint not null default txid_current(),
	created_at timestamp not null default (now() at time zone 'utc'),

    -- constraints
	exclude (is_current with =) where (is_current)
);

-- Revisions should be cut once happy with the DB state
-- upgrades_state
create table migrations.rev (
	id uuid primary key default uuid_generate_v4(),
    -- Optionally set to override statement execution
    -- so a more concise migration can be written
    -- should be tested during insert to validate it
    -- preudces a schema matching the underlying statemnts
	upgrade_statement text not null,
    -- Inverse of the upgrade
	downgrade_statement text,
    -- Human readable message to log
	"message" text,
    -- Allow unit test failure on this migration
    allow_unit_test_failure bool default false,
    -- Preceeding migrations
    -- Human readable names to refer to this migration
	-- tags text[] not null default '{}'::text[],
	created_at timestamp not null default (now() at time zone 'utc')
);


create table migrations.revision_parent (
    id uuid primary key default uuid_generate_v4(),
    revision_id uuid not null,
    parent_id uuid not null,
	created_at timestamp not null default (now() at time zone 'utc'),
    constraint fk_revision_id foreign key (revision_id) references migrations.revision(id),
    constraint fk_parent_id foreign key (parent_id) references migrations.revision(id)
);



create or replace function migrations.persist_ddl()
returns event_trigger as
$$
declare
	db_rev migrations.revision;
	db_rev_id uuid;
	curr_ts timestamp := (select (now() at time zone 'utc'));
	curr_txid bigint := txid_current();
	curr_query text := current_query();
begin
	-- Retrieve the current database revision
	select * into db_rev from migrations.revision where is_current;

	/* If multiple ddl statements occur within a transaction, the event trigger
	fires multiple times. The duplicates must be filtered */
	if (curr_query, curr_txid, curr_ts) = (db_rev.upgrade_statement, db_rev.txid, db_rev.created_at) then
		return;
	end if;

	-- Convenience debug output
	raise info '%', 'ran ' || tg_tag || ' ' || curr_query;

	-- Mark the current revision as
	update migrations.revision set is_current = false where id = db_rev.id;

	insert into migrations.revision(upgrade_statement, txid, parent_ids, is_current)
	values (
		curr_query,
		curr_txid,
		case
			when db_rev.id is not null then ARRAY[db_rev.id]
			else '{}'::uuid[]
		end,
		true
	);
	return;
end;
$$ language plpgsql;


----------------
-- Inspection --
-----------------

create function migrations.current_revision_id()
returns uuid
as $$
    select id from migrations.revision where is_current;
$$ language sql;


create function migrations.current_revision()
returns migrations.revision 
as $$
    select * from migrations.revision where is_current;
$$ language sql;


---------------------
-- User Operations -- 
---------------------

create function migrations.set_downgrade(
    downgrade_statement text,
    revision_id uuid default null
)
returns uuid as 
$$
#variable_conflict use_column
<<decl>>
/* Registers a downgrade migration statement with the 
*/
declare
    downgrade_statement text := downgrade_statement;
    revision_id uuid := revision_id;
    edited_revision_id uuid;
begin

    update
        migrations.revision
    into
        edited_revision_id
    set
        downgrade_statement = decl.downgrade_statement
    where 
        id = coalesce(
                decl.revision_id,
                (select xyz.id from migrations.revision xyz where is_current limit 1)
        )
    returning id;

    -- If edited revision_id is null, no update occured
    if edited_revision_id is null
        then raise exception 'requested revision not found';
    end if;
    
    -- Successful exit
    return edited_revision_id;
end;

$$ language plpgsql;


create type migrations.test_result as (
    ok bool,
    message text
);

-- TODO
create or replace function migrations.test_current_revision()
returns migrations.test_result as 
$$
begin
    return (true, 'nada')::migrations.test_result;
end;

$$ language plpgsql;


create event trigger migrations_on_ddl
on ddl_command_end
execute procedure migrations.persist_ddl();

/*
create or replace function migrations.run()
returns void as
$$
declare
	rev migrations.revision;
begin
	for rev in select * from migrations.revision
	LOOP
		raise info '%', rev.id;
		execute rev.upgrade_statement;
	END LOOP;
end
$$ language plpgsql;
*/
