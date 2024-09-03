ad_page_contract {
    Move an authority up or down one step in the authorities sort_order hierarchy

    @author Simon Carstensen (simon@collaboraid.biz)
    @creation-date 2003-09-09
    @cvs-id $Id$
} {
    {authority_id:naturalnum,notnull}
    {direction:notnull,oneof(up|down)}
}  -validate {
    authority_exists -requires {authority_id:naturalnum} {
        if {![db_0or1row dbqd...check_authority_id {select authority_id, sort_order from auth_authorities where authority_id = :authority_id}]} {
            ad_complain "Invalid authority"
            return
        }
    }
}

# Determine the authority which is next to the passed in authority
# in the order hierarchy depending on the direction we want to move it.
switch -- $direction {
    "up" {
        set op "<"
        set orderby_direction desc
    }
    "down" {
        set op ">"
        set orderby_direction asc
    }
}

set sql [subst {select
                    authority_id as swap_authority_id,
                    sort_order as swap_sort_order
                 from auth_authorities
                 where sort_order $op :sort_order
                 order by sort_order $orderby_direction
                 fetch first 1 rows only}]

if {[db_0or1row dbqd..get_swap_authority $sql]} {
    # adjust sort_order of the passed in authority
    set element_arr(sort_order) $swap_sort_order
    auth::authority::edit -authority_id $authority_id -array element_arr
    
    # adjust sort_order of the swap partner authority
    set element_arr(sort_order) $sort_order
    auth::authority::edit -authority_id $swap_authority_id -array element_arr
}

ad_returnredirect .
ad_script_abort

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
