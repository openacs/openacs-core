ad_page_contract {
    displays the iso-codes

    @cvs-id $Id$
} -properties {
    ccodes:multirow
}

if {![db_table_exists country_codes] } {
    # Geo-tables not loaded
    set header [ad_header "ISO Codes"]

    ad_return_template iso-codes-no-exist

    return
}

db_multirow ccodes country_codes "select iso, country_name from country_codes
order by country_name" 

ad_return_template