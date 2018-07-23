ad_page_contract {
    A quick and dirty batch editor for translation.

    @author Christian Hvid
} {
    locale
    package_key
    {show "all"}
    {page_start 0}
}

# We rename to avoid conflict in queries
set current_locale $locale
set default_locale en_US

set locale_label [lang::util::get_label $current_locale]
set default_locale_label [lang::util::get_label $default_locale]

set page_title "Batch edit messages"
set context [list [list [export_vars -base package-list {locale}] $locale_label] \
                 [list [export_vars -base message-list {locale package_key show}] $package_key] \
                 $page_title]

# TODO: PG

#####
#
# Handle filtering
#
#####

# LARS: The reason I implemented this overly complex way of doing it is that I was just about to
# merge this page with messages-search ...

set where_clauses [list]
set keys_where_clauses [list]

switch -exact $show {
    translated {
        lappend where_clauses {lm2.message is not null}
        lappend keys_where_clauses {exists (select 1
                                            from   lang_messages lm
                                            where  lm.package_key = lmk.package_key
                                            and    lm.message_key = lmk.message_key
                                            and    lm.locale = :current_locale)}
    }
    untranslated {
        lappend where_clauses {lm2.message is null}
        lappend keys_where_clauses {not exists (select 1
                                            from   lang_messages lm
                                            where  lm.package_key = lmk.package_key
                                            and    lm.message_key = lmk.message_key
                                            and    lm.locale = :current_locale)}
    }
}
set where_clause {}
set keys_where_clause {}

if { [llength $where_clauses] > 0 } {
    set where_clause "and [join $where_clauses "\n and "]"
}
if { [llength $keys_where_clauses] > 0 } {
    set keys_where_clause "and [join $keys_where_clauses "\n and "]"
}

#####
#
# Counting messages
#
#####

db_1row counts {
    select (select count(*) from lang_messages where package_key = :package_key and locale = :locale) as num_translated,
           (select count(*) from lang_message_keys where package_key = :package_key) as num_messages
    from   dual
}
set num_untranslated [expr {$num_messages - $num_translated}]

set num_messages_pretty [lc_numeric $num_messages]
set num_translated_pretty [lc_numeric $num_translated]
set num_untranslated_pretty [lc_numeric $num_untranslated]

#####
#
# Initialize pagination
#
#####

set keys [db_list get_keys "
    select lmk.message_key
    from   lang_message_keys lmk
    where  lmk.package_key = :package_key
    $keys_where_clause
    order by upper(lmk.message_key), lmk.message_key
"]

set total [llength $keys]
set page_end [expr {$page_start + 10}]

#####
#
# Build the form
#
#####

set edit_buttons [list]

if { $show ne "untranslated" && $page_start > 0 } {
    lappend edit_buttons { "< Update and back" "prev" }
}

lappend edit_buttons { "Update" "ok" }

if { $show ne "untranslated"
     && $page_end < $total
 } {
    lappend edit_buttons { "Update and next >" "next" }
}

ad_form -name batch_editor -edit_buttons $edit_buttons -form {
    {locale:text(hidden) {value $locale}}
    {package_key:text(hidden) {value $package_key}}
    {page_start:integer(hidden),optional}
    {show:text(hidden),optional}
}

# Each message has the following fields:
#
# message_key_x:text(hidden)
# message_key_pretty_x:text(inform)
# description_x:text(inform)
# default_locale_message_x:text(textarea)
# message_x:text(textarea)
# org_message_x:text(hidden)


set count $page_start
array set sections {}
db_foreach get_messages {} {
    ad_form -extend -name batch_editor -form \
        [list [list "message_key_$count:text(hidden)" {value $message_key}]]

    set message_url [export_vars -base edit-localized-message { locale package_key message_key show }]

    # Adding section
    set section_name "$package_key.$message_key"
    if { ![info exists sections($section_name)] } {
        set sec [list "-section" $section_name {legendtext "$section_name"}]
        ad_form -extend -name batch_editor -form [list $sec]
        set sections($section_name) "$section_name"
    }

    ad_form -extend -name batch_editor -form \
        [list [list "message_key_pretty_$count:text(inform)" \
                   {label "Message Key"} \
                   {value "<a href=\"[ns_quotehtml $message_url]\">$package_key.$message_key</a>"}]]

    if { $description ne "" } {
        set description_edit_url [export_vars -base edit-description { locale package_key message_key show }]
        set description "[ad_text_to_html -- $description] [subst { (<a href="[ns_quotehtml $description_edit_url]">edit</a>)}]"

        ad_form -extend -name batch_editor -form \
            [list [list "description_$count:text(inform),optional" \
                       {label "Description"} \
                       {value $description}]]
    }

    if { $current_locale ne $default_locale } {
        ad_form -extend -name batch_editor -form \
            [list [list "default_locale_message_$count:text(inform),optional" \
                       {label $default_locale_label} \
                       {value {[ns_quotehtml $default_message]}}]]
    }

    if { [string length $translated_message] > 80 } {
        set html { cols 80 rows 15 }
    } else {
        set html { cols 60 rows 2 }
    }

    ad_form -extend -name batch_editor -form \
        [list [list "org_message_$count:text(hidden),optional"]]

    ad_form -extend -name batch_editor -form \
        [list [list "message_$count:text(textarea),optional" {label $locale_label} {html $html}]]

    # We set this as a local variable, so that ad_form's normal system works
    set message_$count $translated_message

    incr count
}


ad_form -extend -name batch_editor -on_request {
    # Set from local vars
} -on_submit {

    for { set i $page_start } { $i < $page_end && $i < $total } { incr i } {

        if { [set org_message_$i] ne [set message_$i] } {
            lang::message::register $current_locale $package_key \
                [set message_key_$i] \
                [set message_$i]
        }
    }

    set button [form::get_button batch_editor]

    if { $button ne "ok" } {
        switch $button {
            prev {
                set page_start [expr {$page_start - 10}]
                if { $page_start < 0 } {
                    set page_start 0
                }
            }
            next {
                incr page_start 10
                if { $page_start > $total } {
                    set page_start [expr {$total - ($total % 10)}]
                }
            }
        }
    }

    ad_returnredirect [export_vars -base [ad_conn url] { locale package_key show page_start }]
    ad_script_abort
}

#####
#
# Slider for pagination
#
#####

multirow create pagination text hint url selected group

for {set count 0} {$count < $total} {incr count 10 } {
    set end_page [expr {$count + 9}]
    if { $end_page > $total-1 } {
        set end_page [expr {$total-1}]
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

    multirow append pagination \
        $text \
        "[lindex $keys $count] - [lindex $keys $end_page]" \
        [export_vars -base batch-editor { { page_start $count } locale package_key show }] \
        [expr {$count == $page_start}] \
        [expr {$count / 100}]
}

#####
#
# Slider for 'show' options
#
#####

multirow create show_opts value label count

multirow append show_opts "all" "All" $num_messages_pretty
multirow append show_opts "translated" "Translated" $num_translated_pretty
multirow append show_opts "untranslated" "Untranslated" $num_untranslated_pretty

multirow extend show_opts url selected_p

multirow foreach show_opts {
    set selected_p [string equal $show $value]
    if {$value eq "all"} {
        set url [export_vars -base [ad_conn url] { locale package_key }]
    } else {
        set url [export_vars -base [ad_conn url] { locale package_key {show $value} }]
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
