ad_page_contract {
    A quick and dirty batch editor for translation.

    @author Christian Hvid
} {
    locales
    package_key
    {page_start 0}
    {page_end 10}
} -properties {
}

if { ![info exists locales] } {
    set current_locale [ad_conn locale]
} else {
    set current_locale $locales
}

db_1row select_locale_lable {
    select label as locale_label from ad_locales where locale = :current_locale 
}

set tab [ns_urlencode "localized-messages"]
set return_url "display-grouped-messages?tab=$tab&locales=$locales"
set context_bar [ad_context_bar [list $return_url Listing] "Batch Editor - $package_key"]

form create batch_editor

# export variables

element create batch_editor locales -widget hidden -datatype text -value $locales
element create batch_editor package_key -widget hidden -datatype text -value $package_key
element create batch_editor page_start -widget hidden -datatype text -value $page_start
element create batch_editor page_end -widget hidden -datatype text -value $page_end

# use a counter for pagination etc.
# this works with both oracle and postgresql

set count 0
set keys [list]

db_foreach get_messages {
    select lm1.message_key as message_key,
           lm1.message as default_message
    from   lang_messages lm1
    where  lm1.locale = 'en_US' and
           lm1.package_key = :package_key
    order by upper(lm1.message_key)
}  {
    lappend keys [string tolower $message_key]

    if {($count >= $page_start) && ($count < $page_end)} {
        set translated_message "TRANSLATION MISSING"
        db_0or1row get_translated_message {
            select message as translated_message
            from   lang_messages
            where  package_key =:package_key and
                   message_key =:message_key and 
                   locale =:current_locale
        }
        element create batch_editor "message_key_$count" -widget hidden -datatype text
        element create batch_editor "message_key_info_$count" -widget inform -datatype text -label "key"
        element create batch_editor "en_us_message_$count" -widget inform -datatype text -label "American"
        element create batch_editor "message_$count" -widget textarea -datatype text -label $locale_label  -html {cols 60 rows 4}
        element set_properties batch_editor "message_key_$count" -value $message_key
        element set_properties batch_editor "message_key_info_$count" -value "<b>$message_key</b>"
        element set_properties batch_editor "en_us_message_$count" -value "<code>[ad_quotehtml $default_message]</code>"
        if { [form is_request batch_editor] } {
            element set_properties batch_editor "message_$count" -value $translated_message
        }
    }

    incr count
}

set total $count

# create pagination multiple

multirow create pagination text hint url selected group
for {set count 0} {$count < $total} {incr count 10 } {
    set end_page [expr $count + 9]
    if { $end_page > [expr $total-1] } {
        set end_page [expr $total-1]
    }
    if { ([string range [lindex $keys $count] 0 2] == "lt_") && ([string range [lindex $keys $end_page] 0 2] == "lt_") } {
        set text "[string range [lindex $keys $count] 2 4] - [string range [lindex $keys $end_page] 2 4]"
    } else {
        set text "[string range [lindex $keys $count] 0 2] - [string range [lindex $keys $end_page] 0 2]"
    }
    multirow append pagination $text "[lindex $keys $count] - [lindex $keys $end_page]" "batch-editor?page_start=$count&page_end=[expr $count+10]&locales=$locales&package_key=$package_key" [expr $count == $page_start] [expr $count / 100]
}

# is this a valid submit? then register the messages

if { [form is_valid batch_editor] } {
    for {set count $page_start} {($count < $page_end) && ($count < $total)} {incr count} {
        # Register message via acs-lang
        set message_key [element get_value batch_editor "message_key_$count"]
        set message [element get_value batch_editor "message_$count"]

        if { $message != "TRANSLATION MISSING" } {
            lang::message::register $locales $package_key $message_key $message
        }
    }
}
