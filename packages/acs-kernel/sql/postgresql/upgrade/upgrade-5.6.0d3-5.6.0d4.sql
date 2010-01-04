alter table acs_data_links add column relation_tag varchar(100);

drop index acs_data_links_un;

create unique index acs_data_links_un on acs_data_links (
  object_id_one, object_id_two, relation_tag
);

create index acs_data_links_rel_tag_idx on acs_data_links (relation_tag);