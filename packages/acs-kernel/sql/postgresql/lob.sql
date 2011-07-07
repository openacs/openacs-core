-- SQL support for fake lobs for ACS/Postgres.
-- Don Baccus February 2000

-- for each user table my_table in which you want to stuff large
-- amounts of data:

-- define a column "lob integer references lobs"
-- do "create trigger my_table_lob_trig before delete or update or insert
-- on my_table for each row execute procedure on_lob_ref()"

-- to initialize a row's lob column,  use empty_lob():

-- insert into my_table (lob) values(empty_lob());

-- deletes and updates on my_table use reference count information
-- to delete data from lobs and lob_data when appropriate.


create sequence lob_sequence;

create table lobs (
	lob_id			integer not null 
                            constraint lobs_lob_id_pk primary key,
	refcount		integer not null default 0
);

CREATE OR REPLACE FUNCTION lobs_delete_tr() RETURNS trigger AS $$
BEGIN
	delete from lob_data where lob_id = old.lob_id;
	return old;
END;
$$ LANGUAGE plpgsql;

create trigger lobs_delete_tr before delete on lobs
for each row execute procedure lobs_delete_tr();

create table lob_data (
        lob_id              integer not null
                            constraint lob_data_lob_id_fk
                            references lobs on delete cascade,
        segment             integer not null,
        byte_len            integer not null,
        data                bytea not null,
        constraint lob_data_lob_id_segment_pk
        primary key (lob_id, segment)
);

create index lob_data_index on lob_data(lob_id);

-- Note - race conditions might cause problems here, but I 
-- couldn't get locking to work consistently between PG 6.5
-- and PG 7.0.  The ACS doesn't share LOBs between tables
-- or rows within a table anyway, I don't think/hope.

CREATE OR REPLACE FUNCTION on_lob_ref() RETURNS trigger AS $$
BEGIN
	if TG_OP = 'UPDATE' then
		if new.lob = old.lob then
			return new;
		end if;
	end if;

	if TG_OP = 'INSERT' or TG_OP = 'UPDATE' then
		if new.lob is not null then
			insert into lobs select new.lob, 0
				where 0 = (select count(*) from lobs where lob_id = new.lob);
			update lobs set refcount = refcount + 1 where lob_id = new.lob;
		end if;
	end if;

	if TG_OP <> 'INSERT' then
		if old.lob is not null then
			update lobs set refcount = refcount - 1 where lob_id = old.lob;
			delete from lobs where lob_id = old.lob and refcount = 0;
		end if;
	end if;

	if TG_OP = 'INSERT' or TG_OP = 'UPDATE' then return new;
	else return old;
	end if;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION empty_lob() RETURNS integer AS $$
BEGIN
	return nextval('lob_sequence');
END;
$$ LANGUAGE plpgsql;



-- added
select define_function_args('lob_get_data','lob_id');

--
-- procedure lob_get_data/1
--
CREATE OR REPLACE FUNCTION lob_get_data(
   p_lob_id integer
) RETURNS text AS $$
DECLARE
        v_rec   record;
        v_data  text default '';
BEGIN
        for v_rec in select data, segment from lob_data where lob_id = p_lob_id order by segment 
        loop
            v_data := v_data || v_rec.data;
        end loop;

        return v_data;

END;
$$ LANGUAGE plpgsql;



-- added
select define_function_args('lob_copy','from_id,to_id');

--
-- procedure lob_copy/2
--
CREATE OR REPLACE FUNCTION lob_copy(
   from_id integer,
   to_id integer
) RETURNS integer AS $$
DECLARE
BEGIN
	if from_id is null then 
	    raise exception 'lob_copy: attempt to copy null from_id to % to_id',to_id;
        end if;

        insert into lobs (lob_id,refcount) values (to_id,0);

        insert into lob_data
             select to_id as lob_id, segment, byte_len, data
               from lob_data
              where lob_id = from_id;

        return null;

END;
$$ LANGUAGE plpgsql;



-- added
select define_function_args('lob_length','id');

--
-- procedure lob_length/1
--
CREATE OR REPLACE FUNCTION lob_length(
   id integer
) RETURNS integer AS $$
DECLARE
BEGIN
        return sum(byte_len) from lob_data where lob_id = id;
END;
$$ LANGUAGE plpgsql;
