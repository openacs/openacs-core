--
-- packages/acs-i18n/sql/language-create.sql
--
-- @author Jeff Davis (davis@arsdigita.com)
-- @creation-date 2000-09-10
-- @cvs-id $Id$
--

create table lang_messages (    
        key     	varchar2(200),
	lang		char(2) not null,
        message         clob,
        registered_p    char(1)
                        constraint lm_tranlated_p_tf check(registered_p in ('t','f')),
        constraint lang_messages_pk primary key (key, lang)
);


-- ****************************************************************************
-- * The lang_translate_columns table holds the columns that require translation.
-- * It is needed to generate the user interface for translating the web site.
-- * Note that we register on_what_column itself for translation.
-- ****************************************************************************

create table lang_translate_columns (   
        column_id               integer primary key,
        -- cant do references on user_tables cause oracle sucks
        on_which_table          varchar2(50),
        on_what_column          varchar2(50),
        --
        -- whether all entries in a column must be translated for the 
        -- site to function.
        --
        -- probably ultimately need something more sophisticated than 
        -- simply required_p
        --
        required_p              char(1)
                                constraint ltc_required_p_tf check(required_p in ('t','f')),
        --
        -- flag for whether to use the lang_translations table for content
        -- or add a row in the on_which_table table with the translated content.
        --
        short_p                 char(1)
                                constraint ltc_short_p_tf check(short_p in ('t','f')),
        constraint  ltc_u unique (on_which_table, on_what_column)
);


-- ****************************************************************************
-- * The lang_translation_registry table identifies a row as requiring translation
-- * to a given language. This should identify the parent table not the broken-apart
-- * child table.
-- ****************************************************************************

create table lang_translation_registry (
	on_which_table		varchar(50),
	on_what_id		integer not null,
        locale                  constraint ltr_locale_ref
                                references ad_locales(locale),
        --
        -- should have dependency info here
        --
        constraint lang_translation_registry_pk primary key(on_what_id, on_which_table, locale)
);




