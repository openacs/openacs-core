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

if {![info exists doc(title)] || $doc(title) eq ""} {
    set doc(title) [ad_conn instance_name]

    # There is no way to determine the language of instance_name so we guess
    # that it is the same as the site wide locale setting - if not this must
    # be overridden
    set doc(title_lang) [lindex [split [lang::system::site_wide_locale] _] 0]
}


#
# Add standard meta tags
#
template::head::add_meta \
    -name generator \
    -lang en \
    -content "OpenACS version [ad_acs_version]"
    
#
# Add standard css
#
template::head::add_css \
    -href "/resources/acs-subsite/site-master.css" \
    -media "all"

template::head::add_css \
    -href "/resources/acs-templating/lists.css" \
    -media "all"

template::head::add_css \
    -href "/resources/acs-templating/forms.css" \
    -media "all"

# Add standard javascript
#
template::head::add_javascript -src "/resources/acs-subsite/core.js"

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

# Determine if we should be displaying the translation UI
#
if {[lang::util::translator_mode_p]} {
    template::add_footer -src "/packages/acs-lang/lib/messages-to-translate"
}

#
# Determine if we should be displaying the dotLRN toolbar
#
set dotlrn_toolbar_p [expr {
    [llength [namespace eval :: info procs dotlrn_toolbar::show_p]] == 1
}]

if {$dotlrn_toolbar_p} {
    template::head::add_css \
        -href "/resources/dotlrn/dotlrn-toolbar.css" \
        -media "all"

    template::add_header -src "/packages/dotlrn/lib/toolbar"
}
 
# DRB: Devsup and dotlrn toolbars moved here temporarily until we rewrite 
#  things so packages can push tool bars up to the blank master.
#
# Determine if developer support is installed and enabled
#
set developer_support_p [expr {
    [llength [info procs ::ds_show_p]] == 1 && [ds_show_p]
}]

if {$developer_support_p} {
    template::head::add_css \
        -href "/resources/acs-developer-support/acs-developer-support.css" \
        -media "all"
 
    template::add_header -src "/packages/acs-developer-support/lib/toolbar"
    template::add_footer -src "/packages/acs-developer-support/lib/footer"
}
