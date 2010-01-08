# /packages/acs-lang/tcl/apm-callback-procs.tcl

ad_library {

    APM callbacks library

    @creation-date August 2009
    @author  Emmanuelle Raffenne (eraffenne@gmail.com)
    @cvs-id $Id$

}

namespace eval lang {}
namespace eval lang::apm {}

ad_proc -private lang::apm::after_install {
} {
    Add ISO-639-2 codes to ad_locales
} {
    lang::apm::add_language_codes
    lang::apm::add_country_codes
}

ad_proc -private lang::apm::after_upgrade {
    {-from_version_name:required}
    {-to_version_name:required}
} {
    After upgrade callback for acs-lang
} {
    apm_upgrade_logic \
        -from_version_name $from_version_name \
        -to_version_name $to_version_name \
        -spec {
            5.6.0d2 5.6.0d3 {    
                lang::apm::add_language_codes
                lang::apm::add_country_codes
            }
        }
}

## Helper procs

ad_proc -private lang::apm::add_language_codes {
} {
    Fills language_codes with ISO-639-2 codes 

    The ISO-639-2 codes are in a text file located at
    acs-lang/resources directory. The file was downloaded from
    http://www.loc.gov/standards/iso639-2/ISO-639-2_utf-8.txt

    Separator is "|" and the columns are:
    
    <ul>
    <li>ISO 639-2 Bibliographic code (used if terminology one is empty)</li>
    <li>ISO 639-2 Terminology code (used if exists)</li>
    <li>ISO 639-1 code (2 digits)</li>
    <li>Language name in english</li>
    <li>Language name in french (ignored)</li>
    </ul>

} {

    set filename "[acs_root_dir]/packages/acs-lang/resources/iso-639-2_utf-8.txt"

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

        db_dml insert_iso639 {
            insert into language_codes 
            (iso_639_2, iso_639_1, label)
            values
            (:iso2, :iso1, :label)
        } 
    }
}

ad_proc -private lang::apm::add_country_codes {
} {
    Fills country_codes with ISO-3166 codes 

    The ISO-3166 codes are in a text file located at
    acs-lang/resources directory. The file was downloaded from
    http://www.iso.org/iso/list-en1-semic-3.txt

    Separator is ";" and the columns are:
    
    <ul>
    <li>Country name in english</li>
    <li>ISO 3166 code</li>
    </ul>

} {

    set filename "[acs_root_dir]/packages/acs-lang/resources/iso-3166-1-countries.txt"

    set channel [open $filename]
    set data [read $channel]
    close $channel

    set row_list [split $data "\n"]
    foreach row $row_list {

        if { $row eq "" } {
            continue
        }

        set col_list [split $row ";"]
        set label [lindex $col_list 0]
        set country [lindex $col_list 1]

        db_dml insert_iso3166 {
            insert into country_codes
            (label, country)
            values
            (:label, :country)
        } 
    }
}
