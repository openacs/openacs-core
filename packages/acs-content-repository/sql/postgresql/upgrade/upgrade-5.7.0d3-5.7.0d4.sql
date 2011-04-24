-- Need to guard against xotcl-core which sneakily modifies core behind
-- our backs (rather than having fixed acs-core like nice people would do)

begin;

 select content_type__create_attribute (
   'content_revision',
   'item_id',
   'integer',
   'Item id',
   'Item ids',
   null,
   null,
   'integer'
 )
 where not exists (select 1
                   from acs_attributes
                   where object_type = 'content_revision'
                     and attribute_name = 'item_id');

 select content_type__create_attribute (
   'content_revision',
   'content',
   'text',
   'Content',
   'Content',
   null,
   null,
   'text'
 )
 where not exists (select 1
                   from acs_attributes
                   where object_type = 'content_revision'
                     and attribute_name = 'content');

end;
