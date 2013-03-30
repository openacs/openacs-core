-- providing upgrade script for subsite_callback__new



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
