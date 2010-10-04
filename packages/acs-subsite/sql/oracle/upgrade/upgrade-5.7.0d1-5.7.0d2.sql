-- Getting right constraint names on subsite_themes this dont matter for PG since 
-- 
-- 
-- @author Victor Guerra (vguerra@gmail.com)
-- @creation-date 2010-09-29
--

alter table subsite_themes rename constraint subsite_theme_name_nn to subsite_themes_nn;
alter table subsite_themes rename constraint subsite_theme_template_nn to subsite_themes_template_nn;
