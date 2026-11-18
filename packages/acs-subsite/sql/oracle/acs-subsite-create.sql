-- Create the necessary data model and ACS relationships for the ACS Core UI.
--
-- @author Hiro Iwashima (iwashima@mit.edu)
--
-- @creation-date 28 August 2000
--
-- @cvs-id $Id$
--

-- create table email_image_rel_ext (
--	rel_id 		integer constraint email_image_rel_ext_fk references acs_rels(rel_id)
--			constraint email_image_rel_ext primary key 
-- );


@@ portraits
@@ email-image
@@ application-groups-create
@@ subsite-callbacks-create
@@ host-node-map-create
@@ user-sc-create
@@ site-node-selection
@@ themes-create

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

create table subsite_email_changes (
    user_id integer constraint subsite_email_changes_pk primary key
                    constraint subsite_email_changes_fk references users(user_id) on delete cascade,
    old_email varchar(100),
    new_email varchar(100) not null,
    token_digest varchar(64) not null,
    expires_at numeric(12) not null
);
