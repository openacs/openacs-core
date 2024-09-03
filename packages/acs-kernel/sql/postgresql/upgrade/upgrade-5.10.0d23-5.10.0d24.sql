
-- Create an index on these acs_object metadata
create index acs_objects_creation_date_idx on acs_objects (creation_date);
create index acs_objects_last_modified_idx on acs_objects (last_modified);
