-- /packages/acs-subsite/sql/tests/subsite-group-callbacks-test.sql

-- Test the basic API to the subsite_callback package. You will
-- get an application error if there is an error

-- Copyright (C) 2001 ArsDigita Corporation
-- @author Michael Bryzek (mbryzek@arsdigita.com)
-- @creation-date 2001-02-20

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

declare
  v_count        integer;
  v_callback_id  integer;
  v_node_id   integer;
begin
  select min(node_id) into v_node_id from site_nodes;

  for i in 0..2 loop
    v_callback_id := subsite_callback.new(event_type=>'insert',
                                                object_type=>'group',
                                                callback=>'subsite_callback_test_foo',
                                                callback_type=>'tcl'
                                               );
  end loop;

  select count(*) into v_count
    from subsite_callbacks
   where object_type = 'group'
     and event_type = 'insert'
     and callback_type = 'tcl'
     and callback = 'subsite_callback_test_foo';

  if v_count = 0 then
     raise_application_error(-20000,'Insert failed');
  elsif v_count > 1 then
     raise_application_error(-20000,'Duplicate insert succeeded where it should have done nothing.');
  end if;

  subsite_callback.del(v_callback_id);

  v_callback_id := subsite_callback.new(object_type=>'group',
                                        event_type=>'insert',
                                        callback=>'subsite_callback_test_foo2',
                                        callback_type=>'tcl');  

  select count(*) into v_count
    from subsite_callbacks
   where object_type = 'group'
     and callback = 'subsite_callback_test_foo2'
     and callback_type = 'tcl';

  if v_count = 0 then
     raise_application_error(-20000,'Insert failed');
  end if;

  subsite_callback.del(v_callback_id);

  select count(*) into v_count
    from subsite_callbacks
   where callback in ('subsite_callback_test_foo','subsite_callback_test_foo2');

  if v_count > 0 then
     raise_application_error(-20000,'Delete failed');
  end if;

end;
/ 
show errors;
  
