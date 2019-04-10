begin;

-- Apparently, older instances might still use the old unlocalized
-- nomenclatures for the person object type
update acs_object_types set
   pretty_name = '#acs-kernel.Person#',
   pretty_plural = '#acs-kernel.People#'
 where object_type = 'person';

end;
