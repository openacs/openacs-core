ad_library {

    Tcl API for avatars (user profile pictures)

    @author Hector Romojaro (hector.romojaro@gmail.com)
}

namespace eval avatar {}

ad_proc -public avatar::get_public_p {
    -user_id:required
} {
    Returns the 'public_avatar_p' field from the user_preferences table

    @param user_id  User ID
} {
    return [db_string get_public_avatar_p {}]
}

ad_proc -public avatar::set_public_p {
    -user_id:required
    -value:required
} {
    Changes the 'public_avatar_p' field from the user_preferences table

    @param user_id  User ID
    @param value    New value
} {
    db_transaction {
        db_dml update_public_avatar_p {}
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
