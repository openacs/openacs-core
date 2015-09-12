ad_library {

    Installation procs for ref-language

    @author Emmanuelle Raffenne (eraffenne@gmail.com)

}

namespace eval ref_language {}
namespace eval ref_language::apm {}

ad_proc -private ref_language::apm::after_install {
} {
    Fill ISO-639-2 codes table
} {
    ref_language::apm::add_language_639_2_codes
}

ad_proc -private ref_language::apm::after_upgrade {
    {-from_version_name:required}
    {-to_version_name:required}
} {
    apm_upgrade_logic \
        -from_version_name $from_version_name \
        -to_version_name $to_version_name \
        -spec {  
            5.6.0d1 5.6.0d2 {

                # If the constraint doesn't exist, we don't care ...
                catch {
                    db_dml drop_unique_index {}
                    db_dml drop_constraint {}
                }

                set new_languages [ref_language::apm::lang_list_for_5_6_0d2]

                foreach {code name} $new_languages {
                    ref_language::set_data -iso1 $code -label $name
                }

            }
            5.6.0d2 5.6.0d3 {

                ref_language::apm::add_language_639_2_codes

            }
        }
}

## Helper procs

ad_proc -private ref_language::apm::add_language_639_2_codes {
} {
    Fills language_639_2_codes

    The ISO-639-2 codes are in a dat file located at
    ref-language/sql/commjon directory. The file was downloaded from
    http://www.loc.gov/standards/iso639-2/ISO-639-2_utf-8.txt

    Separator is "|" and the columns are:
    
    <ul>
    <li>ISO 639-2 Bibliographic code (used if terminology one is empty)</li>
    <li>ISO 639-2 Terminology code (used if exists)</li>
    <li>ISO 639-1 code (2 digits)</li>
    <li>Language name in english</li>
    <li>Language name in french (ignored if present)</li>
    </ul>

} {

    set filename "[acs_root_dir]/packages/ref-language/sql/common/iso-639-2.dat"

    set channel [open $filename]
    set data [read $channel]
    close $channel

    set row_list [split $data "\n"]
    foreach row $row_list {

        if { $row eq "" } {
            continue
        }

        set col_list [split $row "|"]

        # Set iso-639-2 code to terminology if exists, otherwise
        # uses the bibliography one (see RFC 4646)

        set iso2b [lindex $col_list 0]
        set iso2 [lindex $col_list 1]
        set iso1 [lindex $col_list 2]
        set label [lindex $col_list 3]

        if { $iso2 eq "" } {
            set iso2 $iso2b
        }

        ref_language::set_data -iso2 $iso2 -iso1 $iso1 -label $label

    }
}

ad_proc -private ref_language::apm::lang_list_for_5_6_0d2 {
} {
    return {
        ae "Avestan"
        ak "Akan"
        an "Aragonese"
        av "Avaric"
        be "Belarusian"
        bm "Bambara"
        bn "Bengali"
        bs "Bosnian"
        ca "Catalan; Valencian"
        ce "Chechen"
        ch "Chamorro"
        cr "Cree"
        cu "Church Slavic; Old Slavonic; Church Slavonic; Old Bulgarian; Old Church Slavonic"
        cv "Chuvash"
        dv "Divehi; Dhivehi; Maldivian"
        dz "Dzongkha"
        ee "Ewe"
        el "Greek, Modern (1453-)"
        es "Spanish; Castilian"
        ff "Fulah"
        fj "Fijian"
        fo "Faroese"
        fy "Western Frisian"
        gd "Gaelic; Scottish Gaelic"
        gv "Manx"
        he "Hebrew"
        ho "Hiri Motu"
        ht "Haitian; Haitian Creole"
        hz "Herero"
        ia "Interlingua (International Auxiliary Language Association)"
        id "Indonesian"
        ie "Interlingue; Occidental"
        ig "Igbo"
        ii "Sichuan Yi; Nuosu"
        ik "Inupiaq"
        io "Ido"
        iu "Inuktitut"
        jv "Javanese"
        kg "Kongo"
        ki "Kikuyu; Gikuyu"
        kj "Kuanyama; Kwanyama"
        kl "Kalaallisut; Greenlandic"
        km "Central Khmer"
        kr "Kanuri"
        kv "Komi"
        kw "Cornish"
        ky "Kirghiz; Kyrgyz"
        lb "Luxembourgish; Letzeburgesch"
        lg "Ganda"
        li "Limburgan; Limburger; Limburgish"
        lo "Lao"
        lu "Luba-Katanga"
        lv "Latvian"
        mh "Marshallese"
        nb "Bokmål, Norwegian; Norwegian Bokmål"
        nd "Ndebele, North; North Ndebele"
        ng "Ndonga"
        nl "Dutch; Flemish"
        nn "Norwegian Nynorsk; Nynorsk, Norwegian"
        nr "Ndebele, South; South Ndebele"
        nv "Navajo; Navaho"
        ny "Chichewa; Chewa; Nyanja"
        oc "Occitan (post 1500); Provençal"
        oj "Ojibwa"
        om "Oromo"
        os "Ossetian; Ossetic"
        pa "Panjabi; Punjabi"
        pi "Pali"
        ps "Pushto; Pashto"
        rm "Romansh"
        rn "Rundi"
        ro "Romanian; Moldavian; Moldovan"
        sc "Sardinian"
        se "Northern Sami"
        sg "Sango"
        si "Sinhala; Sinhalese"
        ss "Swati"
        st "Sotho, Southern"
        tn "Tswana"
        to "Tonga (Tonga Islands)"
        ty "Tahitian"
        ug "Uighur; Uyghur"
        ve "Venda"
        vo "Volapük"
        wa "Walloon"
        yi "Yiddish"
        yo "Yoruba"
        za "Zhuang; Chuang"
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
