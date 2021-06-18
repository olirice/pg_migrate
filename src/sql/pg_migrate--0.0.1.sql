-- create extension if not exists "uuid-ossp";

create schema migrations;

-- Tracks all DDL statements
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
	-- Track insert order
	seq_id serial not null,
	created_at timestamp not null default (now() at time zone 'utc'),
	exclude (is_current with =) where (is_current)
	-- event triggers will fire multiple times if multiple ddl statements
	-- are contained within the same transaction. We must de-duplicate
	--unique (upgrade_statement, txid, created_at)
);


create or replace function migrations.persist_ddl() returns event_trigger
as $$
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
	raise info '%', session_user || ' ran '|| tg_tag || ' ' || curr_query;

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

create event trigger migrations_on_ddl on ddl_command_end execute procedure migrations.persist_ddl();
-- drop event trigger migrations_on_ddl

create or replace function migrations.run() returns void
as $$
declare
	rev migrations.revision;
begin
	for rev in select * from migrations.revision --order by created_at asc
	LOOP
		raise info '%', rev.id;
		execute rev.upgrade_statement;
	END LOOP;
end
$$ language plpgsql;
