--
-- acs-core-ui/sql/attribute-create.sql
--
-- Creates the necessary attributes for objects for the core ui
--
-- @author Hiro Iwashima (iwashima@mit.edu)
--
-- @creation-date 18 May 2000
--
-- @cvs-id $Id$
--

-- declare
--   result	varchar2(10);
-- begin
--   result := acs_attribute.create_attribute (
--     object_type => 'person',
--     attribute_name => 'bio',
--     datatype => 'string',
--     pretty_name => 'Biography',
--     pretty_plural => 'Biographies',
--     min_n_values => 0,
--     max_n_values => 1,
--     storage => 'generic'
--   );

--   commit;
-- end;
-- /
-- show errors

select acs_attribute__create_attribute (
    'person',
    'bio',
    'string',
    '#acs-subsite.Biography#',
    '#acs-subsite.Biographies#',
    null,
    null,
    null,
    0,
    1,
    null,
    'generic',
    'f'
);

select acs_attribute__create_attribute (
    'person',
    'bio_mime_type',
    'string',
    '#acs-subsite.Biography_Mime_Type#',
    '#acs-subsite.Biography_Mime_Types#',
    null,
    null,
    null,
    0,
    1,
    null,
    'generic',
    'f'
);
