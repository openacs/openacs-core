-- Create the necessary data model and ACS relationships for the ACS Core UI.
--
-- @author Hiro Iwashima (iwashima@mit.edu)
--
-- @creation-date 28 August 2000
--
-- @cvs-id $Id$
--

\i portraits.sql
\i email-image.sql
\i application-groups-create.sql
\i subsite-callbacks-create.sql
\i host-node-map-create.sql
\i user-sc-create.sql
\i site-node-selection.sql
\i themes-create.sql

-- DRB: user profiles are fundamentally broken, which is probably why they
-- weren't created in the original ACS 4.2 Oracle sources. 
-- \i user-profiles-create.sql

-- This view lets us avoid using acs_object.name to get party_names.
-- 
-- create or replace view party_names
-- as
-- select p.party_id,
--        decode(groups.group_id,
--               null, decode(persons.person_id, 
--                            null, p.email,
--                            persons.first_names || ' ' || persons.last_name),
--               groups.group_name) as party_name
-- from parties p,
--      groups,
--      persons
-- where p.party_id = groups.group_id(+)
--   and p.party_id = persons.person_id(+);

create view party_names
as
select p.party_id,
       (case
         when groups.group_id is null then
	   (case
	     when persons.person_id is null then
	       p.email
	     else
	       persons.first_names || ' ' || persons.last_name
	    end)
         else
	   groups.group_name	    
       end) as party_name
from ((parties p left outer join groups on p.party_id = groups.group_id)
      left outer join persons on p.party_id = persons.person_id);
