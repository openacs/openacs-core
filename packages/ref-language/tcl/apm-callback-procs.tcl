ad_library {

    Installation procs for ref-language

    @author Emmanuelle Raffenne (eraffenne@gmail.com)

}

namespace eval ref_language {}
namespace eval ref_language::apm {}

ad_proc -private ref_language::apm::after_upgrade {
    {-from_version_name:required}
    {-to_version_name:required}
} {
    apm_upgrade_logic \
        -from_version_name $from_version_name \
        -to_version_name $to_version_name \
        -spec {  
            5.6.0d1 5.6.0d2 {

                set new_languages [ref_language::apm::lang_list_for_5_6_0d2]

                foreach {name code} $new_languages {
                    set exists_p [db_string get_lang {select count(*) from language_codes where language_id = :code} -default 0]

                    if { $exists_p } {
                        db_dml update_lang {
                            update language_codes set name = :name
                            where language_id = :code
                        }
                    } else {
                        db_dml insert_lang {
                            insert into language_codes (language_id, name)
                            values (:code, :name)
                        }
                    }
                }
            }
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
