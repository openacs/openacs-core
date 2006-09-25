----------------------------
-- Application Data Links --
----------------------------

create sequence acs_data_links_seq start with 1;

create table acs_data_links (
        rel_id          integer not null
                        constraint acs_data_links_rel_id_pk primary key,
        object_id_one   integer not null
                        constraint acs_data_links_one_fk
                        references acs_objects (object_id)
                        on delete cascade,
        object_id_two   integer not null
                        constraint acs_data_links_two_fk
                        references acs_objects (object_id)
                        on delete cascade,
        constraint acs_data_links_un unique
        (object_id_one, object_id_two)
);

create index acs_data_links_id_one_idx on acs_data_links (object_id_one);
create index acs_data_links_id_two_idx on acs_data_links (object_id_two);

insert into acs_data_links
(select - rel_id as rel_id, object_id_one, object_id_two
 from acs_rels
 where rel_type = 'application_data_link');
