ad_page_contract {
    A quick and dirty batch editor for translation.

    @author Christian Hvid
} {
    locale
    package_key
    {page_start 0}
    {page_end 10}
} -properties {
}

if { ![info exists locale] } {
    set current_locale [ad_conn locale]
} else {
    set current_locale $locale
}

db_1row select_locale_lable {
    select label as locale_label from ad_locales where locale = :current_locale 
}

set tab [ns_urlencode "localized-messages"]
set return_url "display-grouped-messages?tab=$tab&locale=$locale"
set context_bar [ad_context_bar [list $return_url Listing] "Batch Editor - $package_key"]

form create batch_editor

# export variables

element create batch_editor locale -widget hidden -datatype text -value $locale
element create batch_editor package_key -widget hidden -datatype text -value $package_key
element create batch_editor page_start -widget hidden -datatype text -value $page_start
element create batch_editor page_end -widget hidden -datatype text -value $page_end

# use a counter for pagination etc.
# this works with both oracle and postgresql

set count 0
set keys [list]
set displayed_keys [list]

set default_locale en_US
set default_locale_label [ad_locale_get_label $default_locale]

set keys [util_memoize [list db_list get_keys "select message_key from lang_message_keys where package_key = '[db_quote $package_key]' order by upper(message_key)"]]
set keys [db_list get_keys "select message_key from lang_message_keys where package_key = '[db_quote $package_key]' order by upper(message_key)"]

set total [llength $keys]

# TODO: Oracle
db_foreach get_messages {} {
    lappend displayed_keys $message_key
    element create batch_editor "message_key_$count" -widget hidden -datatype text
    
    element create batch_editor "message_key_info_$count" -widget inform -datatype text -label "Key"
    
    element create batch_editor "en_us_message_$count" -widget inform -datatype text -label $default_locale_label
    
    if { [string length $translated_message] > 150 } {
        set html { cols 80 rows 15 }
    } else {
        set html { cols 60 rows 4 }
    }
    element create batch_editor "message_$count" -widget textarea -datatype text -label $locale_label -html $html
    
    element set_value batch_editor "message_key_$count" $message_key
    
    element set_value batch_editor "message_key_info_$count" "<b>$message_key</b>"
    
    element set_properties batch_editor "en_us_message_$count" -value "<code>[ad_quotehtml $default_message]</code>"
    
    if { [form is_request batch_editor] } {
        element set_properties batch_editor "message_$count" -value [ad_decode $translated_message "" "TRANSLATION MISSING" $translated_message]
    }
    
    incr count
}



# create pagination multiple

multirow create pagination text hint url selected group
for {set count 0} {$count < $total} {incr count 10 } {
    set end_page [expr $count + 9]
    if { $end_page > [expr $total-1] } {
        set end_page [expr $total-1]
    }
    
    
    set text {}
    if { [string match "lt_*" [lindex $keys $count]] } {
        append text [string range [lindex $keys $count] 3 5]
    } else {
        append text [string range [lindex $keys $count] 0 2]
    }
    append text " - "
    if { [string match "lt_*" [lindex $keys $end_page]] } {
        append text [string range [lindex $keys $end_page] 3 5]
    } else {
        append text [string range [lindex $keys $end_page] 0 2]
    }

    multirow append pagination $text "[lindex $keys $count] - [lindex $keys $end_page]" "batch-editor?page_start=$count&page_end=[expr $count+10]&locale=$locale&package_key=$package_key" [expr $count == $page_start] [expr $count / 100]
}

# is this a valid submit? then register the messages

if { [form is_valid batch_editor] } {
    for {set count $page_start} {($count < $page_end) && ($count < $total)} {incr count} {
        # Register message via acs-lang
        set message_key [element get_value batch_editor "message_key_$count"]
        set message [element get_value batch_editor "message_$count"]

        if { $message != "TRANSLATION MISSING" } {
            lang::message::register $locale $package_key $message_key $message
        }
    }
}
