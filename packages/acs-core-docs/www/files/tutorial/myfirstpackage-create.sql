-- creation script
--
-- @author joel@aufrecht.org
-- @cvs-id &Id:$
--

select content_type__create_type(
    'mfp_note',                    -- content_type
    'content_revision',            -- supertype
    'MFP Note',                    -- pretty_name,
    'MFP Notes',                   -- pretty_plural
    'mfp_notes',                   -- table_name
    'note_id',                     -- id_column
    null                           -- name_method
);

-- necessary to work around limitation of content repository:
select content_folder__register_content_type(-100,'mfp_note','t');
