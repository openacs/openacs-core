-- moved from site-wide search to acs-kernel.

drop function acs_object_util__object_type_p (integer,varchar);
drop function acs_object_util__object_ancestor_type_p (integer,varchar);
drop function acs_object_util__type_ancestor_type_p (varchar,varchar);
drop function acs_object_util__get_object_type (integer);
drop function acs_object_util__object_type_exist_p (varchar);
