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
 );

 select content_type__create_attribute (
   'content_revision',
   'content',
   'text',
   'Content',
   'Content',
   null,
   null,
   'text'
 );

end;
