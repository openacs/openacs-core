-- providing upgrade script for subsite_callback__new

create or replace function subsite_callback__new(integer,varchar,varchar,varchar,varchar,integer)
returns integer as '
declare
  new__callback_id         alias for $1; -- default null,
  new__event_type          alias for $2;
  new__object_type         alias for $3;
  new__callback		   alias for $4;
  new__callback_type       alias for $5;
  new__sort_order          alias for $6; -- default null
  v_callback_id		   subsite_callbacks.callback_id%TYPE;
  v_sort_order		   subsite_callbacks.sort_order%TYPE;
begin

    if new__callback_id is null then
       select nextval(''t_acs_object_id_seq'') into v_callback_id;
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

end;' language 'plpgsql';
