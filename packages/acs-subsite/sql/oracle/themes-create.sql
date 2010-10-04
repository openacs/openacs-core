-- For now, at least, there's no reason for this table to include objects.  When a subsite_theme
-- is installed, it can add to the table.  When it is uninstalled, it can delete from the
-- table.  Theme switching is only accessible from the admin UI for subsites, therefore
-- we don't need permissions on subsite_themes ...

-- the css column contains a list of CSS file/media pairs.

-- css and the form/list templates can be null because evil old OpenACS provides defaults
--  for these.

create table subsite_themes (
    key           varchar(100) 
                  constraint subsite_themes_key_pk
                  primary key,
    name          varchar(100) 
                  constraint subsite_themes_name_nn
                  not null,
    template      varchar(200)
                  constraint subsite_themes_template_nn
                  not null,
    css           varchar(2000),
    form_template varchar(200),
    list_template varchar(200),
    list_filter_template varchar(200)
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
