ad_library {

    Test cases for tcl/lang-catalog-procs.tcl

}

aa_register_case \
    -cats {smoke api} \
    -procs {
        lang::catalog::export
        lang::catalog::import
    } \
    test_catalog_import_export {

        Test import/export of catalog files

    } {
        set catalog_path [lang::catalog::get_catalog_file_path \
                              -package_key acs-lang -locale en_US]

        set catalog_checksum [ns_md file $catalog_path]
        set catalog_mtime [file mtime $catalog_path]

        lang::catalog::export \
            -package_key acs-lang -locales en_US

        aa_equals "Catalog was unchanged after export" \
            $catalog_checksum [ns_md file $catalog_path]

        aa_true "File was actually touched" {
            $catalog_mtime < [file mtime $catalog_path]
        }

        set result [lang::catalog::import \
                        -package_key acs-lang -locales en_US]

        aa_equals "All keys for this package and locale have been processed" \
            [dict get $result processed] \
            [db_string q {
                select count(*) from lang_messages
                where package_key = 'acs-lang' and locale = 'en_US'
            }]
        aa_equals "No keys added"   [dict get $result added]   0
        aa_equals "No keys deleted" [dict get $result deleted] 0
        aa_equals "No keys updated" [dict get $result updated] 0
    }
