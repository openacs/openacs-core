ad_page_contract {
    spits out correctly MIME-typed bits for a user's portrait (thumbnail version)

    @author philg@mit.edu
    @creation-date 26 Sept 1999
    @cvs-id $Id$
} {
    user_id:naturalnum,notnull
}

# NB: this really doesn't work! You can now pass a &size= parameter
# into portrait-bits.tcl. sizes as per image::get_convert_to_sizes


set column portrait_thumbnail

set file_type [db_string unused {
    select portrait_file_type
    from users
    where user_id = :user_id
    and portrait_thumbnail is not null
}] -default ""

if { $file_type eq "" } {
    # Try to get a regular portrait
    set file_type [db_string unused {
        select portrait_file_type
        from users
        where user_id = :user_id
    } -default "" ]
    if {$file_type eq ""} {
	ad_return_error "Couldn't find thumbnail or portrait" "Couldn't find a thumbnail or a portrait for User $user_id"
	return
    }
    set column portrait
}

ReturnHeaders $file_type

ns_ora write_blob $db [subst {
    select $column
    from users
    where user_id = :user_id
}]
    

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
