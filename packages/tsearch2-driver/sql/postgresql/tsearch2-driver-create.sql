-- 
-- tsearch2 based FTSEngineDriver for Search package 
-- 
-- @author Dave Bauer (dave@thedesignexperience.org)
-- @creation-date 2004-06-05
-- @cvs-id $Id$
--

-- FIXME need to load tsearch2.sql from postgresql/share/contrib
-- (on debian /usr/share/postgresql/contrib)
create table txt (
	object_id integer
		  constraint txt_object_id_fk
	          references acs_objects on delete cascade,
	fti	  tsvector
);

create index fti_idx on txt using gist(fti);
create index object_id_idx on txt (object_id);

