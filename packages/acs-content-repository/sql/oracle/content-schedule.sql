-- Data model to support release scheduling of items in the content
-- repository of the ArsDigita Publishing System

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Karl Goldstein (karlg@arsdigita.com)

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

prompt *** Preparing for scheduled updates to live content...

create or replace trigger cr_scheduled_release_tr
before insert on cr_scheduled_release_job
for each row
begin

   raise_application_error(-20000,
        'Inserts are not allowed into cr_scheduled_release_job.'
      );
end;
/
show errors

-- Update the publishing status for items that are due to be released
-- or expired.

create or replace procedure cr_scheduled_release_exec is

  last_exec date;
  this_exec date := sysdate;

  cursor start_cur is
    select 
      p.item_id, live_revision
    from
      cr_release_periods p, cr_items i
    where
      start_when between last_exec and sysdate
    and
      p.item_id = i.item_id;

  cursor end_cur is
    select 
      p.item_id, live_revision
    from
      cr_release_periods p, cr_items i
    where
      end_when between last_exec and sysdate
    and
      p.item_id = i.item_id;

  items_released integer := 0;
  items_expired integer := 0;

  err_num integer := sqlcode;
  err_msg varchar2(500) := substr(sqlerrm, 1, 500);

begin

  begin

    select last_exec into last_exec from cr_scheduled_release_job;

    for item_rec in start_cur loop

      -- update publish status
      update cr_items
	set publish_status = 'live'
      where
	item_id = item_rec.item_id;

      items_released := items_released + 1;

    end loop;

    for item_rec in end_cur loop

      -- update publish status
      update cr_items
	set publish_status = 'expired'
      where
	item_id = item_rec.item_id;

      items_expired := items_expired + 1;

    end loop;

  exception

    when others then
      err_num := SQLCODE;
      err_msg := substr(SQLERRM, 1, 500);
  end;

  -- keep a record of the update

  insert into cr_scheduled_release_log (
    items_released, items_expired, err_num, err_msg
  ) values (
    items_released, items_expired, err_num, err_msg
  );

  -- Reset the last time of execution to start of processing
  update cr_scheduled_release_job set last_exec = this_exec;

  -- Table was growing without bound (OpenACS DanW)
  delete from cr_scheduled_release_log
  where exec_date < sysdate - 4*7;

  commit;

end cr_scheduled_release_exec;
/
show errors

-- initialize the scheduled publication job
-- job scheduling moved to aolserver (OpenACS - DanW)    


-- declare

--   v_job_id integer;
--   interval integer := 15;

--   cursor job_cur is
--     select job from user_jobs 
--       where what = 'cr_scheduled_release_exec;';

-- begin

--   open job_cur;
--   fetch job_cur into v_job_id;

--   if job_cur%NOTFOUND then

--     dbms_output.put_line('
--       Submitting job to process scheduled updates to live content...');

--     dbms_job.submit(
--       job        =>  v_job_id, 
--       what       =>  'cr_scheduled_release_exec;',
--       next_date  =>  sysdate,
--       interval   =>  'sysdate + ' || (interval/24/60)
--     );

--     update cr_scheduled_release_job set job_id = v_job_id;
 
--   else

--     dbms_job.change(
--       job        =>  v_job_id, 
--       what       =>  'cr_scheduled_release_exec;',
--       next_date  =>  sysdate,
--       interval   =>  'sysdate + ' || (interval/24/60)
--     );

--   end if;

-- end;
-- /
-- show errors







