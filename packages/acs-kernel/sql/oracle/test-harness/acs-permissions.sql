--    file: packages/acs-kernel/sql/acs-permissions-test.sql
-- history: date            email                   message
--          2000-08-10      rhs@mit.edu             initial version

begin
 -- Objects for testing.
 insert into acs_object_types
  (object_type, supertype, pretty_name, pretty_plural)
 values
  ('bboard', 'acs_object', 'BBoard', 'BBoards');

 insert into acs_object_types
  (object_type, supertype, pretty_name, pretty_plural)
 values
  ('bboard_message', 'acs_object', 'BBoard Message', 'BBoard Messages');

 --------------------------------------------------------------
 -- Some privileges that will be fundamental to all objects. --
 --------------------------------------------------------------

 insert into acs_privileges
  (privilege)
 values
  ('read');

 insert into acs_privileges
  (privilege)
 values
  ('write');

 insert into acs_privileges
  (privilege)
 values
  ('create');

 insert into acs_privileges
  (privilege)
 values
  ('delete');

 insert into acs_privileges
  (privilege)
 values
  ('admin');

 insert into acs_privileges
  (privilege)
 values
  ('all');

 ----------------------------------------------------------
 -- Some privileges that probably only apply to bboards. --
 ----------------------------------------------------------

 insert into acs_privileges
  (privilege)
 values
  ('moderate');

 -------------------------------------------------
 -- Administrators can read, write, and create. -- 
 -------------------------------------------------

 insert into acs_privilege_hierarchy
  (privilege, child_privilege)
 values
  ('admin', 'read');

 insert into acs_privilege_hierarchy
  (privilege, child_privilege)
 values
  ('admin', 'write');

 insert into acs_privilege_hierarchy
  (privilege, child_privilege)
 values
  ('admin', 'create');

 insert into acs_privilege_hierarchy
  (privilege, child_privilege)
 values
  ('admin', 'delete');

 ------------------------------------
 -- Moderators can read and write. -- 
 ------------------------------------

 insert into acs_privilege_hierarchy
  (privilege, child_privilege)
 values
  ('moderate', 'read');

 insert into acs_privilege_hierarchy
  (privilege, child_privilege)
 values
  ('moderate', 'write');

 insert into acs_privilege_hierarchy
  (privilege, child_privilege)
 values
  ('all', 'admin');

 insert into acs_privilege_hierarchy
  (privilege, child_privilege)
 values
  ('all', 'moderate');

 ------------------------
 -- Methods on bboards --
 ------------------------

 insert into acs_methods
  (object_type, method)
 values
  ('bboard', 'select_any_message');

 insert into acs_methods
  (object_type, method)
 values
  ('bboard', 'update_any_message');

 insert into acs_methods
  (object_type, method)
 values
  ('bboard', 'delete_any_message');

 insert into acs_methods
  (object_type, method)
 values
  ('bboard', 'insert_bboard');

 insert into acs_methods
  (object_type, method)
 values
  ('bboard', 'update_bboard');

 insert into acs_methods
  (object_type, method)
 values
  ('bboard', 'select_bboard');

 insert into acs_methods
  (object_type, method)
 values
  ('bboard', 'delete_bboard');

 ---------------------------------
 -- Methods on bboard messages. --
 ---------------------------------

 insert into acs_methods
  (object_type, method)
 values
  ('bboard_message', 'select_message');

 insert into acs_methods
  (object_type, method)
 values
  ('bboard_message', 'update_message');

 insert into acs_methods
  (object_type, method)
 values
  ('bboard_message', 'insert_message');

 insert into acs_methods
  (object_type, method)
 values
  ('bboard_message', 'delete_message');

 insert into acs_methods
  (object_type, method)
 values
  ('bboard_message', 'foo');

 -------------------------------------------------------------------------
 -- Mappings between privileges and methods on particular object types. --
 -------------------------------------------------------------------------


 -- Methods that correspond to read for a bboard
 insert into acs_privilege_method_rules
  (privilege, object_type, method)
 values
  ('read', 'bboard', 'select_any_message');

 insert into acs_privilege_method_rules
  (privilege, object_type, method)
 values
  ('read', 'bboard', 'select_bboard');

 -- Methods that correspond to read for a bboard message.
 insert into acs_privilege_method_rules
  (privilege, object_type, method)
 values
  ('read', 'bboard_message', 'select_message');

 -- Methods that correspond to write for a bboard.
 insert into acs_privilege_method_rules
  (privilege, object_type, method)
 values
  ('write', 'bboard', 'update_bboard');

 insert into acs_privilege_method_rules
  (privilege, object_type, method)
 values
  ('write', 'bboard', 'update_any_message');

 -- Methods that correspond to write for a bboard message.
 insert into acs_privilege_method_rules
  (privilege, object_type, method)
 values
  ('write', 'bboard_message', 'update_message');

 -- Methods that correspond to create for a bboard.
 insert into acs_privilege_method_rules
  (privilege, object_type, method)
 values
  ('create', 'bboard', 'insert_bboard');

 -- Methods that correspond to create for a bboard message.
 insert into acs_privilege_method_rules
  (privilege, object_type, method)
 values
  ('create', 'bboard_message', 'insert_message');

 -- Methods that correspond to delete for a bboard.
 insert into acs_privilege_method_rules
  (privilege, object_type, method)
 values
  ('delete', 'bboard', 'delete_bboard');

 -- Methods that correspond to delete for a bboard.
 insert into acs_privilege_method_rules
  (privilege, object_type, method)
 values
  ('delete', 'bboard', 'delete_any_message');

 -- Methods that correspond to create for a bboard message.
 insert into acs_privilege_method_rules
  (privilege, object_type, method)
 values
  ('delete', 'bboard_message', 'delete_message');

 insert into acs_privilege_method_rules
  (privilege, object_type, method)
 values
  ('all', 'bboard_message', 'foo');

 commit;
end;
/
show errors
