#/packages/acs-lang/tcl/lang-message-procs.tcl
ad_library {

    Routines for displaying web pages in multiple languages
    <p>
    This is free software distributed under the terms of the GNU Public
    License.  Full text of the license is available from the GNU Project:
    http://www.fsf.org/copyleft/gpl.html

    @creation-date 10 September 2000
    @author Jeff Davis (davis@xarg.net)
    @author Bruno Mattarollo (bruno.mattarollo@ams.greenpeace.org)
    @author Peter Marklund (peter@collaboraid.biz)
    @author Lars Pind (lars@collaboraid.biz)
    @cvs-id $Id$
}

namespace eval lang::message {}

ad_proc -public lang::message::check {
    locale
    package_key
    message_key
    message
} {
    <p>
    Check a message for semantic and sanity correctness (usually called just before a message is registered).
    Throws an error when one of the checks fails.
    </p>
} {
    # Qualify the locale variable value with a country code if it is
    # just a language
    if { [string length $locale] == 2 } {
        # It seems to be a language (iso codes are 2 characters)
        # We don't do a more throughout check since this is not
        # invoked by users.
        # let's get the default locale for that language
        set locale [lang::util::default_locale_from_lang $locale]
    }

    # Create a globally (across packages) unique key for the cache
    set key "${package_key}.${message_key}"

    # Check that non-en_US messages don't have invalid embedded variables
    # Exclude the special case of datetime configuration messages in acs-lang. An alternative
    # to treating those messages as a special case here would be to have those messages use
    # quoted percentage signs (double percentage signs).
    if { $locale ne "en_US" && ![regexp {^acs-lang\.localization-} $key] } {
        set embedded_vars [get_embedded_vars $message]
        set embedded_vars_en_us [get_embedded_vars [lang::message::lookup en_US $key {} {} 0]]
        set missing_vars [util_get_subset_missing $embedded_vars $embedded_vars_en_us]

        if { [llength $missing_vars] > 0 } {
            set msg "Message key '$key' in locale '$locale' has these embedded variables not present in the en_US locale:\
            [join $missing_vars ","]."
            ad_log error $msg
            error $msg
        }
    }

    # If a localization key from acs-lang...
    if {[regexp {^acs-lang\.localization-(.*)$} $key match lc_key]} {
        #
        # ...number separators for decimal and thousands must be
        # checked to ensure they are not equal, otherwise the
        # localized number parsing will fail.
        #
        if {$lc_key in {decimal_point thousands_sep mon_thousands_sep}} {
            #
            # Fetch values in case there were already loaded.
            #
            foreach k {decimal_point thousands_sep mon_thousands_sep} {
                set $k [expr {[lang::message::message_exists_p $locale acs-lang.localization-$k] ?
                              [lc_get -locale $locale $k] : ""}]
            }
            #
            # Overwrite the fetched value with the provided one.
            #
            set $lc_key $message

            #
            # We require, that the decimal_point was either provided
            # or loaded before to be able to compare it with the
            # thousands points.
            #
            if {$decimal_point ne "" &&
                [string first $decimal_point "$thousands_sep$mon_thousands_sep"] > -1} {
                error "locale $locale, key: $key: Message keys for thousands and decimal separators must be different."
            }
        }
    }
}


ad_proc -public lang::message::register {
    {-update_sync:boolean}
    {-upgrade_status "no_upgrade"}
    {-conflict:boolean}
    {-comment ""}
    {-object_id ""}
    locale
    package_key
    message_key
    message
} {
    <p>
    Registers a message for a given locale and package.
    Inserts the message key into the database if it
    doesn't already exists. Inserts the message itself
    in the given locale into the database if it doesn't
    exist and updates it if it does. Also updates the
    cache with the message.
    </p>

    @author Jeff Davis
    @author Peter Marklund
    @author Bruno Mattarollo (bruno.mattarollo@ams.greenpeace.org)
    @author Christian Hvid

    @see _mr

    @param locale           Locale or language of the message. If a language is supplied,
                            the default locale for the language is looked up.

    @param package_key      The package key of the package that the message belongs to.

    @param message_key      The key that identifies the message within the package.

    @param message          The message text

    @param update_sync      If this switch is provided the sync_time
                            of the message will be set to current time. The sync time for
                            a message should only be not null when we know that message in
                            catalog file and db are identical (in sync). This message is then
                            used as a merge base for message catalog upgrades. For more info,
                            see the lang::catalog::upgrade proc.

    @param upgrade_status   Set the upgrade status of the new message to "added", "updated", "deleted".
                            Defaults to "no_upgrade".

    @param conflict         Set this switch if the upgrade represents a conflict between
                            changes made in the database and in catalog files.

    @param object_id        Bind this message key to an acs_object, so that
                            upon deletion, the message key will be
                            removed as well.

    @see lang::message::lookup
    @see _
} {
    # Qualify the locale variable value with a country code if it is
    # just a language
    if { [string length $locale] == 2 } {
        # It seems to be a language (iso codes are 2 characters)
        # We don't do a more throughout check since this is not
        # invoked by users.
        # let's get the default locale for that language
        set locale [lang::util::default_locale_from_lang $locale]
    }

    # Create a globally (across packages) unique key for the cache
    set key "${package_key}.${message_key}"

    # Insert the message key into the database if it doesn't
    # already exist
    set key_exists_p [db_string message_key_exists_p {}]

    if { ! $key_exists_p } {
        # The system will not function correctly if there are keys
        # registered in other locales than en_US. If this is a new
        # message key for a locale different than en_US, register the
        # en_US version first.
        if {$locale eq "en_US"} {
            db_dml insert_message_key {
                insert into lang_message_keys
                (message_key, package_key, object_id)
                values
                (:message_key, :package_key, :object_id)
            }
        } else {
            lang::message::register \
                -update_sync=$update_sync_p \
                -upgrade_status $upgrade_status \
                -conflict=$conflict_p \
                -comment $comment \
                -object_id $object_id \
                en_US \
                $package_key \
                $message_key \
                $message
        }
    }

    # Call semantic and sanity checks on the key before registering.
    lang::message::check $locale $package_key $message_key $message

    # Build up an array of columns to set
    array set cols [list]
    if { $update_sync_p } {
        set cols(sync_time) current_timestamp
    } else {
        set cols(sync_time) "null"
    }
    if { [string is space $message] } {
        set cols(message) "null"
    } else {
        set cols(message) [db_map message]
    }
    set cols(upgrade_status) :upgrade_status

    set conflict_db_p [db_boolean $conflict_p]
    set cols(conflict_p) :conflict_db_p

    # Different logic for update and insert
    if { [db_0or1row message_exists {
        select
               -- For use in audit log call
               message as old_message
          from lang_messages
        where locale = :locale
          and package_key = :package_key
          and message_key = :message_key
    }] } {
        # Update existing message if the message has changed

        # Peter TODO: should these attributes be cached?
        lang::message::get \
            -package_key $package_key \
            -message_key $message_key \
            -locale $locale \
            -array old_message_array

        # An updated message is no longer deleted
        set deleted_p f
        set cols(deleted_p) :deleted_p

        # For use in update query
        set set_clauses [list]
        foreach col [array names cols] {
            lappend set_clauses "$col = $cols($col)"
        }

        db_transaction {

            # Update audit log
            lang::audit::changed_message \
                $old_message \
                $package_key \
                $message_key \
                $locale \
                $comment \
                $old_message_array(deleted_p) \
                $old_message_array(sync_time) \
                $old_message_array(conflict_p) \
                $old_message_array(upgrade_status)

            set cols(message) [db_map message]
            db_dml lang_message_update {} -clobs [list $message]
        }
    } else {
        # Insert new message

        set cols(package_key) :package_key
        set cols(message_key) :message_key
        set cols(locale) :locale

        # user_id is available only with a connection
        if {[ns_conn isconnected]} {
            set creation_user [ad_conn user_id]
            set cols(creation_user) :creation_user
        }

        set col_clauses [list]
        set val_clauses [list]
        foreach col [array names cols] {
            lappend col_clauses $col
            lappend val_clauses $cols($col)
        }

        db_dml lang_message_insert {} -clobs [list $message]
    }

    # Update the message catalog cache
    acs::clusterwide nsv_set lang_message_$locale $key $message
}

ad_proc -public lang::message::delete {
    -package_key:required
    -message_key:required
    -locale:required
} {
    Deletes a message in a particular locale.

    @author Lars Pind (lars@collaboraid.biz)
} {
    lang::message::edit \
        $package_key \
        $message_key \
        $locale \
        [list deleted_p t \
              upgrade_status no_upgrade \
              conflict_p f \
              sync_time "" \
        ]

    # Cleanup the nsv caching the message
    set key "${package_key}.${message_key}"
    acs::clusterwide nsv_unset -nocomplain -- lang_message_$locale $key
}

ad_proc -private lang::message::undelete {
    -package_key:required
    -message_key:required
    -locale:required
} {
    Undeletes a message from a particular locale.

    @author Héctor Romojaro <hector.romojaro@gmail.com>
} {
    lang::message::edit \
        $package_key \
        $message_key \
        $locale \
        [list deleted_p f \
              upgrade_status no_upgrade \
              conflict_p f \
              sync_time "" \
        ]
}

ad_proc -private lang::message::revert {
    {-package_key:required}
    {-message_key:required}
    {-locale:required}
} {
    Revert a message to the last overwritten version of it, i.e. revert the last change.

    @author Peter Marklund
} {
    set last_overwritten_message [db_string select_last_overwritten_message {
        select old_message
        from lang_messages_audit lma1
        where lma1.package_key = :package_key
          and lma1.message_key = :message_key
          and lma1.locale = :locale
          and lma1.audit_id = (select max(lma2.audit_id)
                               from lang_messages_audit lma2
                               where lma2.package_key = lma1.package_key
                                 and lma2.message_key = lma1.message_key
                                 and lma2.locale = lma1.locale
                               )
    }]

    lang::message::register \
        $locale \
        $package_key \
        $message_key \
        $last_overwritten_message
}

ad_proc -private lang::message::get_element {
    -package_key:required
    -message_key:required
    -locale:required
    -element:required
} {
    Get value of a single attribute of a message.

    @param element The name of the attribute that you want.

    @see lang::message::get

    @author Peter Marklund
} {
    lang::message::get \
        -package_key $package_key \
        -message_key $message_key \
        -locale $locale \
        -array message_array

    return $message_array($element)
}

ad_proc -public lang::message::get {
    -package_key:required
    -message_key:required
    -locale:required
    -array:required
} {
    Get all properties of a message in a particular locale.

    @param array Name of an array in the caller's namespace into
                 which you want the message properties delivered.

    @return The array will contain the following entries:
               message_key,
               package_key,
               locale,
               message,
               deleted_p,
               sync_time,
               conflict_p,
               upgrade_status,
               creation_date_ansi,
               creation_user,
               key_description.

    @author Lars Pind (lars@collaboraid.biz)
} {
    upvar 1 $array row

    db_1row select_message_props {
        select m.message_key,
               m.package_key,
               m.locale,
               m.message,
               m.deleted_p,
               m.sync_time,
               m.conflict_p,
               m.upgrade_status,
               to_char(m.creation_date, 'YYYY-MM-DD HH24:MI:SS') as creation_date_ansi,
               m.creation_user,
               k.description as key_description
        from   lang_messages m,
               lang_message_keys k
        where  m.package_key = :package_key
        and    m.message_key = :message_key
        and    m.locale = :locale
        and    k.package_key = m.package_key
        and    k.message_key = m.message_key
    } -column_array row
}

ad_proc -public lang::message::unregister {
    package_key
    message_key
} {
    Unregisters a message key, i.e. deletes it along with all its messages
    from the database and deleted entries in the cache. This proc is
    useful when installing a package.

    To delete an individual message, as opposed to the entire key,
    use lang::message::delete.

    @see lang::message::delete

    @author Peter Marklund
} {
    # Deletes messages as well
    db_dml delete_key {
        delete from lang_message_keys
        where message_key = :message_key
          and package_key = :package_key
    }

    remove_from_cache $package_key $message_key
}

ad_proc -private lang::message::edit {
    {-update_sync:boolean}
    package_key
    message_key
    locale
    edit_array_list
} {
    Edit properties (meta data) of a language catalog message, but not
    the message text itself. To update or add message catalog text, use
    the lang::message::register proc.

    Implementation note: some of the dynamic sql edit
    code of this proc was copied from the auth::authority::edit proc
    and should probably be broken out into a general API.

    @param package_key      The package_key of the message to update

    @param message_key      The message_key of the message to update

    @param locale           The locale of the message to update

    @param edit_array_list  An array list holding names of columns and
                            the values to set them to. Valid keys
                            in this array list are any column names in the
                            lang_messages table.

    @param update_sync      If this switch is provided the sync_time
                            of the message will be updated to current time. If not
                            provided no update to sync_time will be made. If sync_time
                            is contained in the edit_array_list then that value will
                            override the update_sync flag.

    @author Peter Marklund
} {
    array set edit_array $edit_array_list

    if { [info exists edit_array(message)] } {
        error "The proc lang::message::edit was invoked with the message attribute in the edit array. To edit the message text of a message use the lang::message::register proc instead"
    }
    #
    # Deleting/undeleting?
    #
    if { [info exists edit_array(deleted_p)] } {
        set edit_array(deleted_p) [db_boolean [string is true -strict $edit_array(deleted_p)]]
        if { [string is true -strict $edit_array(deleted_p)] } {
            set delete_p t
            set delete_comment "deleted"
        } else {
            set delete_p f
            set delete_comment "undeleted"
        }
        #
        # If we are deleting/undeleting we need to preserve the old message in the audit log
        #
        # Peter TODO: should these attributes be cached?
        #
        lang::message::get \
            -package_key $package_key \
            -message_key $message_key \
            -locale $locale \
            -array old_message_array

        lang::audit::changed_message \
            $old_message_array(message) \
            $package_key \
            $message_key \
            $locale \
            $delete_comment \
            $old_message_array(deleted_p) \
            $old_message_array(sync_time) \
            $old_message_array(conflict_p) \
            $old_message_array(upgrade_status)

        #
        # If we are deleting an en_US message we need to mark the message as deleted in all locales
        #
        if {$delete_p && $locale eq "en_US"} {
            set message_locales [db_list all_message_locales {
                select locale
                from lang_messages
                where package_key = :package_key
                  and message_key = :message_key
                  and locale <> 'en_US'
            }]
            foreach message_locale $message_locales {
                lang::message::delete \
                    -package_key $package_key \
                    -message_key $message_key \
                    -locale $message_locale
            }
        }
    }

    set set_clauses [list]
    foreach name [array names edit_array] {
        lappend set_clauses "$name = :$name"
        set $name $edit_array($name)
    }
    if { $update_sync_p && ![info exists edit_array(sync_time)] } {
        lappend set_clauses {sync_time = current_timestamp}
    }

    if { [llength $set_clauses] > 0 } {

        set sql "
            update lang_messages
            set    [join $set_clauses ", "]
            where  package_key = :package_key
            and    message_key = :message_key
            and    locale = :locale
        "
        db_dml edit_message $sql
    }
}

ad_proc -private lang::message::conflict_count {
    {-package_key ""}
    {-locale ""}
} {
    Return the number of messages with conflicts (conflict_p=t) resulting
    from catalog imports.

    @param package_key Restrict count to package with this key
    @param locale      Restrict count to messages of this locale

    @author Peter Marklund
} {
    return [db_string conflict_count {
        select count(*)
        from lang_messages
        where conflict_p = 't'
          and (:package_key is null or :package_key = package_key)
          and (:locale      is null or :locale      = locale)
    }]
}

ad_proc -private lang::message::remove_from_cache {
    package_key
    message_key
} {
    Delete a certain message key from the cache for all
    locales.

    @author Peter Marklund
} {
    set locales_list [db_list select_system_locales {
        select locale
        from   ad_locales
    }]

    # Delete from the cache for all enabled locales
    foreach locale $locales_list {
        set nsv_array lang_message_$locale
        set nsv_key "${package_key}.${message_key}"
        if { [nsv_exists $nsv_array $nsv_key] } {
            acs::clusterwide nsv_unset $nsv_array $nsv_key
        }
    }
}

ad_proc -public lang::message::get_embedded_vars {
    message
} {
    Returns a list of embedded substitution variables on the form %varname% in a message.
    This is useful if you want to check that the variables used in a translated message also
    appear in the en_US message. If not, there's likely to be a typo.

    @param message  A message with embedded %varname% notation

    @return         The list of variables in the message

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 12 November 2002
} {
    set variables_list [list]
    set remaining_message $message
    while { [regexp [embedded_vars_regexp] $remaining_message \
            match before_percent percent_match remaining_message] } {

        if {$percent_match eq "%%"} {
            # A quoted percentage sign - ignore
            continue
        } else {
            lappend variables_list [string range $percent_match 1 end-1]
        }
    }

    return $variables_list
}

ad_proc -public lang::message::format {
    localized_message
    {value_array_list {}}
    {upvar_level 3}
} {
    Substitute all occurencies of %array_key%
    in the given localized message with the value from a lookup in the value_array_list
    with array_key (what's between the percentage sings). If value_array_list is not
    provided then attempt to fetch variable values the number of levels up given by
    upvar_level (defaults to 3 because this proc is typically invoked from the underscore
    lookup proc).

    Here is an example:

    set localized_message "The %animal% jumped across the %barrier%. About 50% of the time, he stumbled, or maybe it was %%20 %times%."
    set value_list { animal "frog" barrier "fence" }

    ns_log notice formatted=[format $localized_message $value_list]

    The output from the example is:

    The frog jumped across the fence. About 50% of the time, he stumbled, or maybe it was %20 %times%.
} {
    if {[llength $value_array_list] % 2 != 0} {
        ad_log error "Invalid value_array_list passed in: <$value_array_list>"
    }

    array set value_array $value_array_list
    set value_array_keys [array names value_array]
    set remaining_message $localized_message
    set formatted_message ""
    while { [regexp [embedded_vars_regexp] $remaining_message match before_percent percent_match remaining_message] } {

        append formatted_message $before_percent

        if {$percent_match eq "%%"} {
            # A quoted percent sign
            append formatted_message "%"
        } else {
            set variable_string [string range $percent_match 1 end-1]

            if { [llength $value_array_list] > 0 } {
                # A substitution list is provided, the key should be in there

                if {$variable_string ni $value_array_keys} {
                    ns_log Warning "lang::message::format: The value_array_list" \
                        "\"$value_array_list\" does not contain the variable name" \
                        "$variable_string found in the message: $localized_message"

                    # There is no value available to do the substitution with
                    # so don't substitute at all
                    append formatted_message $percent_match
                } else {
                    # Do the substitution
                    append formatted_message $value_array($variable_string)
                }
            } else {
                regexp {^([^.]+)(?:\.([^.]+))?$} $variable_string match variable_name array_key

                # No substitution list provided - attempt to fetch variable value
                # from scope calling lang::message::lookup
                upvar $upvar_level $variable_name local_variable

                if { [info exists local_variable] } {
                    if { ![info exists array_key] || $array_key eq "" } {
                        # Normal Tcl variable
                        append formatted_message $local_variable
                    } else {
                        # Array variable
                        append formatted_message $local_variable($array_key)
                    }
                } else {
                    ns_log warning "Message contains a variable named '$variable_name' " \
                        "which doesn't exist in the caller's environment: message $localized_message"
                    append formatted_message "MISSING: variable '$variable_name' is not available"
                }
            }
        }
    }

    # Append text after the last match
    append formatted_message $remaining_message

    return $formatted_message
}

ad_proc -public lang::message::embedded_vars_regexp {} {
    The regexp pattern used to loop over variables embedded in
    message catalog texts.

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 12 November 2002
} {
    return {^(.*?)(%%|%[-a-zA-Z0-9_:\.]+(?:;noquote)?%)(.*)$}
}

if {[ns_info name] eq "NaviServer"} {
    #
    # NaviServer supports since ages nsv_get with an optional output
    # variable. This cuts the number of needed lock operations per
    # lookup into half.
    #
    ad_proc -public lang::message::message_exists_p {
        -varname
        locale
        key
    } {
        Return 1 if message exists in given locale, 0 otherwise.

        @param varname when specified, return value in this variable
        @author Gustaf Neumann
    } {
        #
        # Make sure messages are loaded into the cache.
        #
        acs::per_thread_cache eval -key acs-lang.message_cache_loaded {
            lang::message::cache
        }
        #
        # Provide linkage to the output variable and perform lookup
        #
        if {[info exists varname]} {
            upvar 1 $varname var
        }
        try {
            return [nsv_get lang_message_$locale $key var]
        } on error {errmsg} {
            return 0
        }
    }
} else {
    #
    # AOLserver compatible version
    #
    ad_proc -public lang::message::message_exists_p {
        -varname
        locale
        key
    } {
        Return 1 if message exists in given locale, 0 otherwise.

        @param varname when specified, return value in this variable
        @author Gustaf Neumann
    } {
        #
        # Make sure messages are loaded into the cache.
        #
        acs::per_thread_cache eval -key acs-lang.message_cache_loaded {
            lang::message::cache
        }
        #
        # Check for existence and return value if required.
        #
        set exists [nsv_exists lang_message_$locale $key]
        if {$exists && [info exists varname]} {
            upvar 1 $varname var
            set var [nsv_get lang_message_$locale $key]
        }
        return $exists
    }
}

ad_proc -public lang::message::lookup {
    locale
    key
    {default "TRANSLATION MISSING"}
    {substitution_list {}}
    {upvar_level 1}
    {translator_mode_p 1}
} {
    This proc is normally accessed through the _ procedure.

    Returns a translated string for the given locale and message key.
    If the user is a translator, inserts tags to link to the translator
    interface. This allows a translator to work from the context of a web page.

    Messages will have %name% replaced with variables either from substitution_list,
    if present, or from the caller's namespace (or upvar_level's namespace).
    Set upvar_level to 0 and substitution_list empty to prevent substitution from happening

    Note that this proc does not use named parameters, because named parameters are
    relatively slow, and this is going to get called a whole lot on each request.

    @param locale             Locale (e.g., "en_US") or language (e.g., "en") string.
                              If locale is the empty string ad_conn locale will be used
                              if we are in an HTTP connection, otherwise the system locale
                              (SiteWideLocale) will be used.

    @param key                Unique identifier for this message. Will be the same
                              identifier for each locale. All keys belong to a certain
                              package and should be prefixed with the package key of that package
                              on the format package_key.message_key (the dot is reserved for separating
                              the package key, the rest of the key should contain only alphanumeric
                              characters and underscores). If the key does not belong to
                              any particular package it should not contain a dot. A lookup
                              is always attempted with the exact key given to this proc.

    @param default            Text to return if there is no message in the message catalog for
                              the given locale. This argument is optional. If this argument is
                              not provided or is the empty string then the text returned will
                              be TRANSLATION MISSING - $key.

    @param substitution_list  A list of values to substitute into the message. This argument should
                              only be given for certain messages that contain place holders (on the syntax
                              %var_name%) for embedding variable values, see lang::message::format.
                              If this list is not provided and the message has embedded variables,
                              then the variable values can be fetched with upvar from the scope
                              calling this proc (see upvar_level).

    @param upvar_level        If there are embedded variables and no substitution list provided, this
                              parameter specifies how many levels up to fetch the values of the variables
                              in the message. The default is 1.

    @param translator_mode_p  Set to 0 if you do not want this call to honor translator mode.
                              Useful if you're not using this message in the page itself, but e.g.
                              for localization data or for the list of messages on the page.

    @author Jeff Davis (davis@xarg.net)
    @author Henry Minsky (hqm@arsdigita.com)
    @author Peter Marklund (peter@collaboraid.biz)

    @see _
    @see lang::message::register

    @return A localized piece of text.
} {
    # Make sure messages are in the cache
    acs::per_thread_cache eval -key acs-lang.message_cache_loaded {
        lang::message::cache
    }

    # Make sure that a default of "" is transformed into Translation Missing
    # As per discussion on IRC on 2008-03-06
    if { $default eq ""} {
        set default "TRANSLATION MISSING"
    }

    if { $locale eq "" } {
        # No locale provided

        if { [ns_conn isconnected] } {
            # We are in an HTTP connection (request) so use that locale
            set locale [ad_conn locale]
        } else {
            # There is no HTTP connection - resort to system locale
            set locale [lang::system::locale]
        }
    } elseif { [string length $locale] == 2 } {
        # Only language provided, let's get the default locale for this language
        set default_locale [lang::util::default_locale_from_lang $locale]
        if { $default_locale eq "" } {
            error "Could not look up locale for language $locale"
        } else {
            set locale $default_locale
        }
    }

    #
    # Probably, we should check for undefined locales passed in. We
    # omit this for now due to missing performance evaluation of this
    # change.
    #
    # elseif {$locale ni [lang::system::get_locales]} {
    #    error "Unknown locale $locale passed as argument"
    #}

    #
    # Trying locale directly
    #
    if { ![message_exists_p -varname message $locale $key] } {
        #
        # Trying default locale for language.
        #
        set language [lindex [split $locale "_"] 0]

        #
        # When the lookup returns empty (no locale for this language),
        # or returns the same language we checked before, there is no
        # reason for the message lookup and we can go to the next
        # test.
        #
        set lang_locale [lang::util::default_locale_from_lang $language]
        if { $lang_locale eq ""
             || $lang_locale eq $locale
             || ![message_exists_p -varname message $lang_locale $key]
         } {
            #
            # Trying system locale for package
            #
            if { ![message_exists_p -varname message [lang::system::locale] $key] } {
                #
                # Trying site-wide system locale
                #
                if { ![message_exists_p -varname message [lang::system::locale -site_wide] $key] } {
                    #
                    # Resorting to en_US
                    #
                    if { ![message_exists_p -varname message "en_US" $key] } {
                        if {"TRANSLATION MISSING" ne $default} {
                            set message $default
                        } else {
                            ad_log Error "lang::message::lookup: Key '$key' does not exist in en_US"
                            set message "MESSAGE KEY MISSING: '$key'"
                        }
                    }
                }
            }
        }
    }

    # Do any variable substitutions (interpolation of variables)
    # Set upvar_level to 0 and substitution_list empty to prevent substitution from happening
    if { [llength $substitution_list] > 0 || ($upvar_level >= 1 && [string first "%" $message] != -1) } {
        set message [lang::message::format $message $substitution_list [expr {$upvar_level + 1}]]
    }

    if { [lang::util::translator_mode_p] } {
        # Translator mode - record the message lookup
        lang::util::record_message_lookup $key

        if { $translator_mode_p } {
            global message_key_num
            if { ![info exists message_key_num] } {
                set message_key_num 1
            } else {
                incr message_key_num
            }

            # encode the key in the page
            set message "$message\x02(\x01$key\x01)\x02"
        }
    }

    return $message
}

ad_proc -public lang::message::cache {{-force:boolean}} {
    Loads the entire message catalog from the database into the cache.
} {
    #
    # We segregate messages by language. It might reduce contention if
    # we segregate instead by package keys. Check mutex contention
    # nsstats (with ns_info locks).
    #
    if {[nsv_incr lang_message_cache executed_p] == 1 || $force_p} {

        set i 0
        db_foreach select_locale_keys {
            select locale, package_key, message_key, message
            from   lang_messages
            where deleted_p = 'f'
        } {
            nsv_set lang_message_$locale "${package_key}.${message_key}" $message
            incr i
        }

        ns_log Notice "lang::message::cache - Initialized message cache with $i rows from database"
    }
}



#####
#
# Shorthand notation procs _ and _mr
#
#####

ad_proc -private -deprecated _mr { locale key message } {

    Registers a message in a given locale or language.
    Inserts the message into the table lang_messages
    if it does not exist and updates if it does.

    It assumes that the key is the concatenation of message and
    package key like this:  package_key.message_key

    Actually, there is very little need for this proc (which is not
    used in the 300+ packages in the repository), therefore, it is
    marked as deprecated. Use lang::message::register instead.

    @param locale  Abbreviation for language of the message or the locale.
    @param key     Unique identifier for this message. Will be the same identifier
                   for each language
    @param message Text of the message

    @see lang::message::register
} {
    regexp {^([^\.]+)\.([^\.]+)$} $key match package_key message_key
    return [lang::message::register $locale $package_key $message_key $message]
}

ad_proc -public _ {
    key
    {substitution_list {}}
} {
    Short hand proc that invokes the lang::message::lookup proc.
    Returns a localized text from the message catalog with the locale ad_conn locale
    if invoked within a request, or the system locale otherwise.

    <p>

    Example:
<pre>
    set the_url [export_vars -base "[ad_conn package_url]view" { item_id }]
    set body [_ my-package.lt_To_view_this_item [list item_url $the_url]]
</pre>

    If the message value is "To view this item, please click here: %item_url%", then the URL will be insert into the message.

    @param key        Unique identifier for this message. Will be the same identifier
                      for each locale. The key is on the format package_key.message_key

    @param substitution_list
                      A list of values to substitute into the message on the form { name value name value ... }.
                      This argument should only be given for certain messages that contain place holders (on the syntax
                      %1:pretty_name%, %2:another_pretty_name% etc) for embedding variable values.
                      If the message contains variables that should be interpolated and this argument
                      is not provided then upvar will be used to fetch the variable values.

    @return           A localized message

    @author Jeff Davis (davis@xarg.net)
    @author Peter Marklund (peter@collaboraid.biz)
    @author Christian Hvid (chvid@collaboraid.biz)

    @see lang::message::lookup
    @see lang::message::format
} {
    return [lang::message::lookup "" $key "TRANSLATION MISSING" $substitution_list 2]
}

#####
#
# Backwards compatibility procs
#
#####


ad_proc -public lang::message::update_description {
    {-package_key:required}
    {-message_key:required}
    {-description:required}
} {
    Update the description of a message key.

    @author Simon Carstensen
    @creation-date 2003-08-12
} {
    db_dml update_description {} -clobs [list $description]
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
