-- packages/acs-content-repository/sql/upgrade/upgrade-4.1.2-4.5.sql
--
-- @author vinod@kurup.com
-- @creation-date 2002-05-15
-- @cvs-id $Id$
--

-- fixes bug #1502 http://openacs.org/sdm/one-baf.tcl?baf_id=1502

drop function content_keyword__delete(integer);
create function content_keyword__delete (integer)
returns integer as '
declare
  delete__keyword_id             alias for $1;  
  v_rec                          record; 
begin

  for v_rec in select item_id from cr_item_keyword_map 
    where keyword_id = delete__keyword_id LOOP
    PERFORM content_keyword__item_unassign(v_rec.item_id, delete__keyword_id);
  end LOOP;

  PERFORM acs_object__delete(delete__keyword_id);

  return 0; 
end;' language 'plpgsql';
