-- Upgrade content_template.new() and make it take an optional text parameter.
-- If it is provided, a revision of the template will be created automatically.
-- You thus avoid calling content_revision.new() in a separate step ...
-- (ola@polyxena.net)

@@ ../packages-create.sql
@@ ../content-item.sql
