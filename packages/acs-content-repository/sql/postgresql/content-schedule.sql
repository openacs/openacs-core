-- Data model to support release scheduling of items in the content
-- repository of the ArsDigita Publishing System

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Karl Goldstein (karlg@arsdigita.com)

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

-- prompt *** Preparing for scheduled updates to live content...

create function cr_scheduled_release_tr () returns opaque as '
begin

   raise EXCEPTION ''-20000: Inserts are not allowed into cr_scheduled_release_job.'';

  return new;
end;' language 'plpgsql';

create trigger cr_scheduled_release_tr 
before insert on cr_scheduled_release_job
for each row execute procedure cr_scheduled_release_tr ();

-- show errors

-- Update the publishing status for items that are due to be released
-- or expired.

create function cr_scheduled_release_exec () returns integer as '
declare
  exec__last_exec             timestamptz;
  exec__this_exec             timestamptz default current_timestamp;
  exec__items_released        integer default 0;
  exec__items_expired         integer default 0;
  exec__err_num               integer;  -- sqlcode
  exec__err_msg               varchar;  -- substr(sqlerrm, 1, 500);
  item_rec                    record;
begin

    select last_exec into exec__last_exec from cr_scheduled_release_job;

    for item_rec in select 
                      p.item_id, live_revision
                    from
                      cr_release_periods p, cr_items i
                    where
                      start_when between exec__last_exec and now()
                    and
                      p.item_id = i.item_id 
    LOOP
      -- update publish status
      update cr_items
	set publish_status = ''live''
      where
	item_id = item_rec.item_id;
      exec__items_released := exec__items_released + 1;
    end loop;

    for item_rec in select 
                      p.item_id, live_revision
                    from
                      cr_release_periods p, cr_items i
                    where
                      end_when between exec__last_exec and now()
                    and
                      p.item_id = i.item_id
    LOOP
      -- update publish status
      update cr_items
	set publish_status = ''expired''
      where
	item_id = item_rec.item_id;

      exec__items_expired := exec__items_expired + 1;

    end loop;

  -- exception

  --   when others then
  --    err_num := SQLCODE;
  --    err_msg := substr(SQLERRM, 1, 500);
  -- end;

  -- keep a record of the update

  insert into cr_scheduled_release_log (
    items_released, items_expired, err_num, err_msg
  ) values (
    exec__items_released, exec__items_expired, exec__err_num, 
    exec__err_msg
  );

  -- Table was growing without bound (OpenACS DanW)
  delete from cr_scheduled_release_log
  where exec_date < now() - ''4 week''::interval;

  -- Reset the last time of execution to start of processing
  update cr_scheduled_release_job set last_exec = exec__this_exec;

  return 0;
end;' language 'plpgsql';
