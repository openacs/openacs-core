-- For now, at least, there's no reason for this table to include objects.  When a subsite_theme
-- is installed, it can add to the table.  When it is uninstalled, it can delete from the
-- table.  Theme switching is only accessible from the admin UI for subsites, therefore
-- we don't need permissions on subsite_themes ...

-- the css column contains a list of CSS file/media pairs.

-- css and the form/list templates can be null because evil old OpenACS provides defaults
-- for these.

create table subsite_themes (
    key           text
                  constraint subsite_themes_key_pk
                  primary key,
    name          text
                  constraint subsite_themes_name_nn
                  not null,
    template      text
                  constraint subsite_themes_template_nn
                  not null,
    css           text,
    js            text,
    form_template text,
    list_template text,
    list_filter_template text,
    dimensional_template text,
    resource_dir   text,
    streaming_head text,
    local_p        boolean default false
);

-- Insert the old themes that were hard-wired into earlier versions of acs-subsite.

insert into subsite_themes
  (key, name, template)
values
  ('obsolete_plain', 'Obsolete Plain', '/www/default-master');

insert into subsite_themes
  (key, name, template)
values
  ('obsolete_tabbed', 'Obsolete Tabbed', '/packages/acs-subsite/www/group-master');
