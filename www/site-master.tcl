ad_page_contract {
  This is the highest level site specific master template.
  site-master adds site wide OpenACS functionality to every page.

  You should NOT need to modify this file unless you are adding functionality
  for a site wide service.

  If you want to customise the look and feel of your site you probably want to
  modify /www/default-master.

  Note: currently site wide service content is hard coded in this file.  At 
  some point we will want to determine this content dynamically which will 
  change the content of this file significantly.

  @author Lee Denison (lee@xarg.co.uk)

  $Id$
}

#
# Add Site-Wide CSS
#
template::head::add_css \
    -href "/resources/acs-subsite/site-master.css" \
    -media "all"

#
# Fire subsite callbacks to get header content
# FIXME: it's not clear why these callbacks are scoped to subsite or if 
# FIXME  callbacks are the right way to add content of this type.  Either way
# FIXME  using the @head@ property or indeed having a callback for every 
# FIXME  possible javascript event handler is probably not the right way to go.
#
append head [join [callback subsite::get_extra_headers] "\n"]
set onload_handlers [callback subsite::header_onload]
foreach onload_handler $onload_handlers {
   template::add_body_handler -event onload -script $onload_handler
}


