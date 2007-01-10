ad_page_contract {
    Move authorities up/down to control sort order

    @author Simon Carstensen (simon@collaboraid.biz)
    @creation-date 2003-09-09
    @cvs-id $Id$
} {
    authority_id:integer
    direction
}

# Get the authority's sort_order
db_1row select_sort_order {
    select sort_order
    from auth_authorities 
    where authority_id = :authority_id
}

if { $direction eq "up" } {

    db_transaction {
        # Increase next authority's sort_order by one
        db_dml move_next_authority_down {
            update auth_authorities 
            set sort_order = :sort_order
            where sort_order = (select max(sort_order)
                                from   auth_authorities
                                where  sort_order < :sort_order)
        }

        # Decrease authority's sort_order by one
        db_dml move_authority_up {
            update auth_authorities 
            set sort_order = :sort_order - 1
            where authority_id = :authority_id
        }
    }

} elseif { $direction eq "down"} {

    db_transaction {
        # Decrease previous authority's sort_order by one
        db_dml move_prev_authority_up {
            update auth_authorities 
            set sort_order = :sort_order
            where sort_order = (select min(sort_order)
                                from   auth_authorities
                                where  sort_order > :sort_order)
        }

        # Increase authority's sort_order by one
        db_dml move_authority_down {
            update auth_authorities 
            set sort_order = :sort_order + 1
            where authority_id = :authority_id;
        }
    }

} 

ad_returnredirect .
ad_script_abort
