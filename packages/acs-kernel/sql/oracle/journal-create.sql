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


begin
  acs_object_type.create_type(
    object_type => 'journal_entry',
    pretty_name => 'Journal Entry',
    pretty_plural => 'Journal Entries',
    table_name => 'journal_entries',
    id_column => 'journal_id',
    package_name => 'journal_entry'
  );

  -- XXX fill in all the attributes in later.
end;
/
show errors

create table journal_entries (
  journal_id		constraint journal_entries_journal_id_fk
			references acs_objects (object_id)
			constraint journal_entries_pk
			primary key,
  object_id 		integer
			constraint journal_entries_object_fk
			references acs_objects on delete cascade,
  action                varchar2(100),
  action_pretty         varchar2(4000),
  msg    		varchar2(4000)
);

create index journal_entries_object_idx on journal_entries (object_id);

comment on table journal_entries is '
  Keeps track of actions performed on objects, e.g. banning a user,
  starting or finishing a workflow task, etc.
';


create or replace package journal_entry
as

    function new (
        journal_id	in journal_entries.journal_id%TYPE default null,
        object_id	in journal_entries.object_id%TYPE,
        action		in journal_entries.action%TYPE,
	action_pretty   in journal_entries.action_pretty%TYPE default null,
        creation_date	in acs_objects.creation_date%TYPE default sysdate,
        creation_user	in acs_objects.creation_user%TYPE default null,
        creation_ip	in acs_objects.creation_ip%TYPE default null,
        msg		in journal_entries.msg%TYPE default null
    ) return journal_entries.journal_id%TYPE;

    procedure del (
	journal_id	in journal_entries.journal_id%TYPE
    );

    procedure delete_for_object(
	object_id       in acs_objects.object_id%TYPE
    );

end journal_entry;
/
show errors;

create or replace package body journal_entry
as

    function new (
        journal_id	in journal_entries.journal_id%TYPE default null,
        object_id	in journal_entries.object_id%TYPE,
        action		in journal_entries.action%TYPE,
	action_pretty   in journal_entries.action_pretty%TYPE,
        creation_date	in acs_objects.creation_date%TYPE default sysdate,
        creation_user	in acs_objects.creation_user%TYPE default null,
        creation_ip	in acs_objects.creation_ip%TYPE default null,
        msg		in journal_entries.msg%TYPE default null
    ) return journal_entries.journal_id%TYPE
    is
        v_journal_id journal_entries.journal_id%TYPE;
    begin
	v_journal_id := acs_object.new (
	  object_id => journal_id,
	  object_type => 'journal_entry',
	  creation_date => creation_date,
	  creation_user => creation_user,
	  creation_ip => creation_ip,
	  context_id => object_id
	);

        insert into journal_entries (
            journal_id, object_id, action, action_pretty, msg
        ) values (
            v_journal_id, object_id, action, action_pretty, msg
        );

        return v_journal_id;
    end new;

    procedure del (
	journal_id	in journal_entries.journal_id%TYPE
    )
    is
    begin
	delete from journal_entries where journal_id = journal_entry.del.journal_id;
	acs_object.del(journal_entry.del.journal_id);
    end del;

    procedure delete_for_object(
	object_id       in acs_objects.object_id%TYPE
    )
    is
	cursor journal_cur is
	    select journal_id from journal_entries where object_id = delete_for_object.object_id;
    begin
        for journal_rec in journal_cur loop
	    journal_entry.del(journal_rec.journal_id);
	end loop;
    end delete_for_object;

end journal_entry;
/
show errors;

