-- Create the necessary data model and ACS relationships for the ACS Core UI.
--
-- @author Hiro Iwashima (iwashima@mit.edu)
--
-- @creation-date 28 August 2000
--
-- @cvs-id $Id$
--

@@ attribute
@@ portraits
@@ application-groups-create
@@ subsite-callbacks-create
@@ host-node-map-create
@@ user-sc-create
@@ site-node-delection

-- This view lets us avoid using acs_object.name to get party_names.
-- 
create or replace view party_names
as
select p.party_id,
       decode(groups.group_id,
              null, decode(persons.person_id, 
                           null, p.email,
                           persons.first_names || ' ' || persons.last_name),
              groups.group_name) as party_name
from parties p,
     groups,
     persons
where p.party_id = groups.group_id(+)
  and p.party_id = persons.person_id(+);
