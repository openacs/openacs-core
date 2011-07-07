-- Data model to keep a journal of all actions on objects.
-- 
--
-- @author Lars Pind (lars@pinds.com)
-- @creation-date 2000-22-18
-- @cvs-id $Id$
--
-- Copyright (C) 1999-2000 ArsDigita Corporation
--
-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html


CREATE OR REPLACE FUNCTION inline_0 () RETURNS integer AS $$
BEGIN
  PERFORM acs_object_type__create_type (
    'journal_entry',
    'Journal Entry',
    'Journal Entries',
    'acs_object',
    'journal_entries',
    'journal_id',
    'journal_entry',
    'f',
    null,
    null
    );

  -- XXX fill in all the attributes in later.
  return 0;
END;
$$ LANGUAGE plpgsql;

select inline_0 ();

drop function inline_0 ();


-- show errors

create table journal_entries (
  journal_id		integer constraint journal_entries_journal_id_fk
			references acs_objects (object_id)
			constraint journal_entries_journal_id_pk
			primary key,
  object_id 		integer
			constraint journal_entries_object_id_fk
			references acs_objects on delete cascade,
  action                varchar(100),
  action_pretty         text,
  msg    		text
);

create index journal_entries_object_idx on journal_entries (object_id);

comment on table journal_entries is '
  Keeps track of actions performed on objects, e.g. banning a user,
  starting or finishing a workflow task, etc.
';


-- create or replace package journal_entry
-- as
-- 
--     function new (
--         journal_id	in journal_entries.journal_id%TYPE default null,
--         object_id	in journal_entries.object_id%TYPE,
--         action		in journal_entries.action%TYPE,
-- 	action_pretty   in journal_entries.action_pretty%TYPE default null,
--         creation_date	in acs_objects.creation_date%TYPE default sysdate,
--         creation_user	in acs_objects.creation_user%TYPE default null,
--         creation_ip	in acs_objects.creation_ip%TYPE default null,
--         msg		in journal_entries.msg%TYPE default null
--     ) return journal_entries.journal_id%TYPE;
-- 
--     procedure delete(
-- 	journal_id	in journal_entries.journal_id%TYPE
--     );
-- 
--     procedure delete_for_object(
-- 	object_id       in acs_objects.object_id%TYPE
--     );
-- 
-- end journal_entry;

-- show errors

-- create or replace package body journal_entry
-- function new


-- added
select define_function_args('journal_entry__new','journal_id;null,object_id,action,action_pretty;null,creation_date;now(),creation_user;null,creation_ip;null,msg;null');

--
-- procedure journal_entry__new/8
--
CREATE OR REPLACE FUNCTION journal_entry__new(
   new__journal_id integer,        -- default null
   new__object_id integer,
   new__action varchar,
   new__action_pretty varchar,     -- default null
   new__creation_date timestamptz, -- default now()
   new__creation_user integer,     -- default null
   new__creation_ip varchar,       -- default null
   new__msg varchar                -- default null

) RETURNS integer AS $$
DECLARE
  v_journal_id                journal_entries.journal_id%TYPE;
BEGIN
	v_journal_id := acs_object__new (
	  new__journal_id,
	  'journal_entry',
	  new__creation_date,
	  new__creation_user,
	  new__creation_ip,
	  new__object_id,
          't',
          new__action,
          null
	);

        insert into journal_entries (
            journal_id, object_id, action, action_pretty, msg
        ) values (
            v_journal_id, new__object_id, new__action, 
            new__action_pretty, new__msg
        );

        return v_journal_id;
     
END;
$$ LANGUAGE plpgsql;


-- procedure delete


-- added
select define_function_args('journal_entry__delete','journal_id');

--
-- procedure journal_entry__delete/1
--
CREATE OR REPLACE FUNCTION journal_entry__delete(
   delete__journal_id integer
) RETURNS integer AS $$
DECLARE
BEGIN
	delete from journal_entries where journal_id = delete__journal_id;
	PERFORM acs_object__delete(delete__journal_id);

        return 0; 
END;
$$ LANGUAGE plpgsql;


-- procedure delete_for_object


-- added
select define_function_args('journal_entry__delete_for_object','object_id');

--
-- procedure journal_entry__delete_for_object/1
--
CREATE OR REPLACE FUNCTION journal_entry__delete_for_object(
   delete_for_object__object_id integer
) RETURNS integer AS $$
DECLARE
  journal_rec                           record;
BEGIN
        for journal_rec in select journal_id 
                             from journal_entries 
                            where object_id = delete_for_object__object_id  
        LOOP
	    PERFORM journal_entry__delete(journal_rec.journal_id);
	end loop;

        return 0; 
END;
$$ LANGUAGE plpgsql;



-- show errors

