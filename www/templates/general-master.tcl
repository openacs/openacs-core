ad_page_contract {

    OpenACS.org  general master 

    @author modified by Patrick Colgan pat pat@museatech.net
    @author modified by Ola Hansson ola@polyxena.net
    @creation-date 9/6/2001


} {
    { email "" }
} -properties {
    form_vars:onevalue
    allow_persistent_login_p:onevalue
    remember_password:onevalue
    name:onevalue
    first_names:onevalue
    email:onevalue
    home_url:onevalue
    home_url_name:onevalue
    oacs_admin_p:onevalue
    pkid:onevalue
}

# oacs_set_login_vars

set pkid [ad_conn package_id]

if [template::util::is_nil title]     { set title        [ad_system_name]   }
if [template::util::is_nil signatory] { set signatory    [ad_system_owner] }
#if ![info exists header_stuff]        { set header_stuff {<link rel="stylesheet" type="text/css" href="/templates/css/main.css">}                }
append header_stuff {<link rel="stylesheet" type="text/css" href="/templates/css/main.css">}
if ![template::util::is_nil context] { set context_bar [eval ad_context_bar $context]}
if [template::util::is_nil context_bar] { set context_bar [ad_context_bar] }
# Edit This Page - format the etp link for style sheet
set etp_link [etp::get_etp_link]
regsub "^<a" $etp_link "<a class=\"top\"" etp_link


# clean out title and context bar for index page.
if {[string equal [ad_conn url] "/"] || [string match /index* [ad_conn url]] || [string equal [ad_conn url] "/community/"]} { 
    set context_bar {} 
    set notitle 1
}

# stuff that is in the stock default-master

template::multirow create attribute key value

# Pull out the package_id of the subsite closest to our current node
set pkg_id [site_node_closest_ancestor_package "acs-subsite"]

template::multirow append \
    attribute bgcolor [ad_parameter -package_id $pkg_id bgcolor   dummy "white"]
template::multirow append \
    attribute text    [ad_parameter -package_id $pkg_id textcolor dummy "black"]

if { [info exists prefer_text_only_p]
     && $prefer_text_only_p == "f"
&& [ad_graphics_site_available_p] } {
  template::multirow append attribute background \
    [ad_parameter -package_id $pkg_id background dummy "/graphics/bg.gif"]
}

if { ![template::util::is_nil focus] } {
    # Handle elements wohse name contains a dot
    regexp {^([^.]*)\.(.*)$} $focus match form_name element_name
    
    template::multirow append \
            attribute onload "javascript:document.forms\['${form_name}'\].elements\['${element_name}'\].focus()"
}

# Where to find the stylesheet
set css_url "/resources/acs-subsite/site-master.css"
