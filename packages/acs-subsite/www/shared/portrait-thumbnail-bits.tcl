ad_page_contract {
    spits out correctly MIME-typed bits for a user's portrait (thumbnail version)

    @author philg@mit.edu
    @creation-date 26 Sept 1999
    @cvs-id $Id$
} {
    user_id:integer
}

set column portrait_thumbnail

set file_type [db_string -default "" unused "select portrait_file_type
from users
where user_id = $user_id
and portrait_thumbnail is not null"]

if { [empty_string_p $file_type] } {
    # Try to get a regular portrait
    set file_type [db_string -default "" unused "select portrait_file_type
from users
where user_id = $user_id"]
    if [empty_string_p $file_type] {
	ad_return_error "Couldn't find thumbnail or portrait" "Couldn't find a thumbnail or a portrait for User $user_id"
	return
    }
    set column portrait
}

ReturnHeaders $file_type

ns_ora write_blob $db "select $column
from users
where user_id = $user_id"
    
