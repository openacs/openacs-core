set locale [ad_conn locale]

set display_p [expr {[lang::util::translator_mode_p] && [ad_conn locale] ne "en_US" }]

template::list::create \
    -name messages \
    -multirow messages \
    -elements {
        message_key {
            label "Message key"
        }
        orig_text {
            label "English text"
        }
        translated_text {
            label "Translation"
            display_template {
               <if @messages.translated_p;literal@ false>
                 <a href="@messages.translate_url@" title="Translate"><font color="red">Translate</font></a>
               </if>
               <else>
                 @messages.translated_text@
               </else>
            }
        }
        edit {
            label ""
            display_template {
                <if @messages.translated_p;literal@ true>
                  <a href="@messages.translate_url@" title="Edit the translation">
                    <img src="/shared/images/Edit16.gif" height="16" width="16" alt="Edit" border="0">
                  </a>
                </if>
            }
            sub_class narrow
        }
    }

if { $display_p } {
    multirow create messages message_key orig_text translated_text translate_url translated_p

    foreach message_key [lang::util::get_message_lookups] {

        set locale [ad_conn locale]

        # Extra args mean no substitution
        set orig_text [lang::message::lookup "en_US" $message_key {} {} 0 0]
        set translated_text [lang::message::lookup $locale $message_key {} {} 0 0]

        set key_split [split $message_key "."]
        lassign $key_split package_key_part message_key_part
        set translate_url [export_vars -base /acs-lang/admin/edit-localized-message {
            {message_key $message_key_part}
            {package_key $package_key_part}
            locale
            {return_url [ad_return_url]}
        }]

        set translated_p [lang::message::message_exists_p [ad_conn locale] $message_key]

        multirow append messages $message_key $orig_text $translated_text $translate_url $translated_p
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
