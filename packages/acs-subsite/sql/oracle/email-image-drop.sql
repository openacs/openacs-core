--
-- packages/acs-subsite/sql/portraits-drop.sql
--
-- author  Miguel Marin (miguelmarin@viaro.net) Viaro Networks (www.viaro.net)
-- creation-date 2005-01-22
--

drop table email_images;

begin
  acs_rel_type.drop_type('email_image_rel');
end;
/
show errors
