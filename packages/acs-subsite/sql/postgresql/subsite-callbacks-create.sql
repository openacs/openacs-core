-- /packages/acs-subsite/sql/subsite-group-callbacks-create.sql

-- Defines a simple callback system to allow other applications to
-- register callbacks when groups of a given type are created. 

-- Copyright (C) 2001 ArsDigita Corporation
-- @author Michael Bryzek (mbryzek@arsdigita.com)
-- @creation-date 2001-02-20

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html


-- What about instead of? 
   -- insead_of viewing the group, go to the portal
   -- instead of inserting the group with package_instantiate_object, go here 

create table subsite_callbacks (
       callback_id         integer 
			   constraint sgc_callback_id_pk primary key,
       event_type          varchar(100) not null
			   constraint sgc_event_type_ck check(event_type in ('insert','update','delete')),
       object_type         varchar(1000) not null
			   constraint sgc_object_type_fk references acs_object_types
                           on delete cascade,
       callback		   varchar(300) not null,
       callback_type       varchar(100) not null
			   constraint sgc_callback_type_ck check(callback_type in ('tcl')),
       sort_order          integer default(1) not null
			   constraint sgc_sort_order_ck check(sort_order >= 1),
       -- allow only one callback of a given type for given 
       constraint subsite_callbacks_un unique (object_type, event_type, callback_type, callback)
);

comment on table subsite_callbacks is '
	Applications can register callbacks that are triggered
	whenever a group of a specified type is created. The callback
	must expect the following arguments: 
	  * object_id: The object that just got created
	  * node_id: The node_id where the object got created
	  * package_id: The package_id from where the object got created
	These are passed in the following way:
	  * tcl procedure: Using named parameters (e.g. -object_id $object_id)
	All callbacks must accept all of these parameters.
';

comment on column subsite_callbacks.event_type is '
	The type of event we are monitoring. The keywords here are used
	by the applications to determine which callbacks to trigger.
';      

comment on column subsite_callbacks.object_type is '
	The object type to monitor. Whenever an object of this type is
	created, the subsite package will check for a registered
	callbacks.
';

comment on column subsite_callbacks.callback_type is ' 
	The type of the callback. This determines how the callback is
	executed. Currenlty only a tcl type is supported but other
	types may be added in the future. 
';


comment on column subsite_callbacks.callback is '
	The actual callback. This can be the name of a plsql function
	or procedure, a url stub relative to the node at which package
	id is mounted, or the name of a tcl function.
';

comment on column subsite_callbacks.sort_order is '
	The order in which the callbacks should fire. This is
	important when you need to ensure that one event fires before
	another (e.g. you must mount a portals application before the
	bboard application)
';      


-- create or replace package subsite_callback as

--   function new (
--   --/** Registers a new callback. If the same callback exists as
--   --    defined in the unique constraint on the table, does 
--   --    nothing but returns the existing callback_id.
--   -- 
--   --    @author Michael Bryzek (mbryzek@arsdigita.com)
--   --    @creation-date 2001-02-20
--   -- 
--   --*/
--        callback_id         IN subsite_callbacks.callback_id%TYPE default null,
--        event_type          IN subsite_callbacks.event_type%TYPE,
--        object_type         IN subsite_callbacks.object_type%TYPE,
--        callback		   IN subsite_callbacks.callback%TYPE,
--        callback_type       IN subsite_callbacks.callback_type%TYPE,
--        sort_order          IN subsite_callbacks.sort_order%TYPE default null
--   ) return subsite_callbacks.callback_id%TYPE;

--   procedure delete (
--   --/** Deletes the specified callback
--   -- 
--   --    @author Michael Bryzek (mbryzek@arsdigita.com)
--   --    @creation-date 2001-02-20
--   -- 
--   --*/
  
--        callback_id         IN subsite_callbacks.callback_id%TYPE
--   );

-- end subsite_callback;
-- /
-- show errors;



-- create or replace package body subsite_callback as

--   function new (
--        callback_id         IN subsite_callbacks.callback_id%TYPE default null,
--        event_type          IN subsite_callbacks.event_type%TYPE,
--        object_type         IN subsite_callbacks.object_type%TYPE,
--        callback		   IN subsite_callbacks.callback%TYPE,
--        callback_type       IN subsite_callbacks.callback_type%TYPE,
--        sort_order          IN subsite_callbacks.sort_order%TYPE default null
--   ) return subsite_callbacks.callback_id%TYPE
--   IS
--     v_callback_id  subsite_callbacks.callback_id%TYPE;
--     v_sort_order   subsite_callbacks.sort_order%TYPE;
--   BEGIN

--     if new.callback_id is null then
--        select acs_object_id_seq.nextval into v_callback_id from dual;
--     else
--        v_callback_id := new.callback_id;
--     end if;
   
--     if new.sort_order is null then
--        -- Make this the next event for this object_type/event_type combination
--        select nvl(max(sort_order),0) + 1 into v_sort_order
--          from subsite_callbacks
--         where object_type = new.object_type
--           and event_type = new.event_type;
--     else
--        v_sort_order := new.sort_order;
--     end if;

--     begin 
--       insert into subsite_callbacks
--       (callback_id, event_type, object_type, callback, callback_type, sort_order)
--       values
--       (v_callback_id, new.event_type, new.object_type, new.callback, new.callback_type, v_sort_order);
--      exception when dup_val_on_index then
--       select callback_id into v_callback_id
--         from subsite_callbacks
--        where event_type = new.event_type
--          and object_type = new.object_type
--          and callback_type = new.callback_type
--          and callback = new.callback;
--     end;
--     return v_callback_id;

--   END new;



-- added
select define_function_args('subsite_callback__new','callback_id;null,event_type,object_type,callback,callback_type,sort_order;null');

--
-- procedure subsite_callback__new/6
--
CREATE OR REPLACE FUNCTION subsite_callback__new(
   new__callback_id integer, -- default null,
   new__event_type varchar,
   new__object_type varchar,
   new__callback varchar,
   new__callback_type varchar,
   new__sort_order integer   -- default null

) RETURNS integer AS $$
DECLARE
  v_callback_id		   subsite_callbacks.callback_id%TYPE;
  v_sort_order		   subsite_callbacks.sort_order%TYPE;
BEGIN

    if new__callback_id is null then
       select nextval('t_acs_object_id_seq') into v_callback_id;
    else
       v_callback_id := new__callback_id;
    end if;
   
    if new__sort_order is null then
       -- Make this the next event for this object_type/event_type combination
       select coalesce(max(sort_order),0) + 1 into v_sort_order
         from subsite_callbacks
        where object_type = new__object_type
          and event_type = new__event_type;
    else
       v_sort_order := new__sort_order;
    end if;

--    begin 
      insert into subsite_callbacks
      (callback_id, event_type, object_type, callback, callback_type, sort_order)
      values
      (v_callback_id, new__event_type, new__object_type, new__callback, new__callback_type, v_sort_order);

-- TODO: Can we do this properly?
--       If not, could move select before insert
--      exception when dup_val_on_index then
--        select callback_id into v_callback_id
--          from subsite_callbacks
--         where event_type = new__event_type
--           and object_type = new__object_type
--           and callback_type = new__callback_type
--           and callback = new__callback;
--    end;
    return v_callback_id;

END;
$$ LANGUAGE plpgsql;

--   procedure delete (
--        callback_id         IN subsite_callbacks.callback_id%TYPE
--   )
--   is
--   begin
--      delete from subsite_callbacks where callback_id=subsite_callback.delete.callback_id;
--   end delete;



-- added
select define_function_args('subsite_callback__delete','callback_id');

--
-- procedure subsite_callback__delete/1
--
CREATE OR REPLACE FUNCTION subsite_callback__delete(
   delete__callback_id integer
) RETURNS integer AS $$
DECLARE
BEGIN
      delete from subsite_callbacks where callback_id = delete__callback_id;
      return 0;
END;
$$ LANGUAGE plpgsql;

-- end subsite_callback;
-- /
-- show errors;

