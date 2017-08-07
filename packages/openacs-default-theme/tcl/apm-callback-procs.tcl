namespace eval openacs_default_theme {}
namespace eval openacs_default_theme::install {}

ad_proc openacs_default_theme::install::after_install {} {
    Package after installation callback proc.  Add our themes, and set the acs-subsite's
    default master template parameter's default value to our "plain" theme.
} {

    # Insert this package's themes
    db_transaction {

        subsite::new_subsite_theme \
            -key default_plain \
            -name #openacs-default-theme.plain# \
            -template /packages/openacs-default-theme/lib/plain-master \
            -css {
		{-href /resources/openacs-default-theme/styles/default-master.css -media all}
		{-href /resources/acs-templating/forms.css -media all}
		{-href /resources/acs-templating/lists.css -media all}
	    } \
            -form_template /packages/acs-templating/resources/forms/standard \
            -list_template /packages/acs-templating/resources/lists/table \
            -list_filter_template /packages/acs-templating/resources/lists/filters \
	    -dimensional_template ""

        subsite::new_subsite_theme \
            -key default_tabbed \
            -name #openacs-default-theme.tabbed# \
            -template /packages/openacs-default-theme/lib/tabbed-master \
            -css {
		{-href /resources/openacs-default-theme/styles/default-master.css -media all}
		{-href /resources/acs-templating/forms.css -media all}
		{-href /resources/acs-templating/lists.css -media all}
	    } \
            -form_template /packages/acs-templating/resources/forms/standard \
            -list_template /packages/acs-templating/resources/lists/table \
            -list_filter_template /packages/acs-templating/resources/lists/filters \
	    -dimensional_template ""
    }

    # Set the default value of the master template parameter, so all subsites will
    # default to this when mounted.  At this point in the ACS installation process, the
    # main subsite has yet to be mounted, so it will get the "plain" theme value
    # when the installer gets around to doing so.

    # Don't do this if you're creating your own theme package!  Override the default by
    # creating a custom install.xml file to be run during the install process if you want
    # it to be installed by default for your sites.

    # We don't set up the form or list templates or CSS because the default is to use
    # those values set for acs-templating during install.

    parameter::set_default -package_key acs-subsite -parameter DefaultMaster \
        -value /packages/openacs-default-theme/lib/plain-master

    parameter::set_default -package_key acs-subsite -parameter ThemeCSS \
	-value {
	    {-href /resources/openacs-default-theme/styles/default-master.css -media all}
	    {-href /resources/acs-templating/forms.css -media all}
	    {-href /resources/acs-templating/lists.css -media all}
	}

    parameter::set_default -package_key acs-subsite -parameter ThemeKey -value default_plain
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
