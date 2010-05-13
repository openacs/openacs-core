ad_library {
    Country procs
    @author Malte Sussdorff (sussdorff@sussdorff.de)
    @creation-date 2006-03-09
}

namespace eval ref_countries {}

ad_proc -public ref_countries::get_country_code {
    {-country:required}
} {
    Gets the country code for a country

    @param country Name of the country in English!
} {
    
    set country_code [db_string get_country_code "select iso from countries where default_name = upper(:country)" -default ""]

    if {[string eq "" $country_code]} {
        
        # Lets try to be smart.
        set country_list [list \
                              [list England GB] \
                              [list "Great Britain" GB] \
                              [list Korea KR] \
                              [list Scotland GB] \
                              [list "South Korea" SK] \
                              [list "Taiwan, R.O.C." TW] \
                              [list "The Netherlands" NL] \
                              [list UK GB] \
                              [list USA US] \
                              [list "United States of America" US]]

        template::util::list_of_lists_to_array $country_list countries

        if {[exists_and_not_null countries($country)]} {
            set country_code $countries($country)
        }
    }
    
    return $country_code
}
