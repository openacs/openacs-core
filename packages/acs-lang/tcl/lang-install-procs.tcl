ad_library {
    Support procedures for install.xml actions.

    @creation-date 20050129
    @author Jeff Davis davis@xarg.net
    @cvs-id $Id$
}

ad_proc -private ::install::xml::action::set-system-locale { node } {
   set the systewide locale
} {
    set locale [apm_required_attribute_value $node locale]
    lang::system::set_locale $locale
}


ad_proc -private ::install::xml::action::enable-locale { node } {
   set the systewide locale
} {
    set locale [apm_required_attribute_value $node locale]
    lang::system::locale_set_enabled -locale $locale -enabled_p t
}
