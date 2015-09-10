ad_library {
    Support procedures for install.xml actions.

    @creation-date 20050129
    @author Jeff Davis davis@xarg.net
    @cvs-id $Id$
}

namespace eval ::install::xml::action {}

ad_proc -private ::install::xml::action::set-system-locale { node } {
   set the systewide locale

    <code>&lt;set-system-locale locale="en_US"&gt;</code>
} {
    set locale [apm_required_attribute_value $node locale]
    lang::system::set_locale $locale
}


ad_proc -private ::install::xml::action::enable-locale { node } {
    Enable a locale

    <code>&lt;enable-locale locale="en_US"&gt;</code>
} {
    set locale [apm_required_attribute_value $node locale]
    lang::system::locale_set_enabled -locale $locale -enabled_p t
}

ad_proc -private ::install::xml::action::disable-locale { node } {
    Disable a locale

    <code>&lt;disable-locale locale="en_US"&gt;</code>
} {
    set locale [apm_required_attribute_value $node locale]
    lang::system::locale_set_enabled -locale $locale -enabled_p f
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
