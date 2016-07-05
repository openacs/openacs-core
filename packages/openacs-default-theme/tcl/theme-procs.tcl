ad_library {

    Provides a simple API theme interactions
    
    @author Gustaf Neumann
    @creation-date 05 July 2015
}


ad_proc -public -callback subsite::theme_changed -impl openacs-default-theme {
    -subsite_id:required
    -old_theme:required
    -new_theme:required
} {

    Implementation of the theme_changed callback which is called, whenever a theme is changed
    
    @param subsite_id subsite, of which the theme was changed
    @param old_theme the name of the old theme
    @param new_theme the name of the new theme
} {
    ns_log notice "openacs-default-theme: theme of subsite $subsite_id changed from $old_theme to $new_theme"
}


