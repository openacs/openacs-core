# Procs to support testing OpenACS with Tclwebtest.
#
# Procs used to access the Tcl API on the OpenACS server.
#
# @author Peter Marklund

namespace eval ::twt::oacs {}

ad_proc ::twt::oacs::eval { tcl_command } {
    Execute an OpenACS Tcl API command and return the result.

    @param tcl_command A list where the first item is the the
           proc name and the remaining ones are proc arguments
} {
    ::twt::do_request "/eval-command?[::http::formatQuery tcl_command $tcl_command]"

    return [response body]
}

ad_proc ::twt::oacs::user_id_from_email { email } {
    return [::twt::oacs::eval "
        db_string user_id_from_email {
            select party_id from parties where email = '$email'
        }
    "]
}

ad_proc ::twt::oacs::get_classes_to_join { email } {
    Return a list of ids for classes that the user with
    given email can join.
} {
    set user_id [user_id_from_email $email]

    return [::twt::oacs::eval "
        db_list can_join_community_ids {
            select community_id
            from dotlrn_class_instances_full
            where dotlrn_class_instances_full.join_policy <> 'closed'
            and not exists (select 1
                            from dotlrn_member_rels_full
                            where dotlrn_member_rels_full.user_id = '$user_id'
                            and dotlrn_member_rels_full.community_id = dotlrn_class_instances_full.class_instance_id)

        }
    "]
}

ad_proc ::twt::oacs::get_clubs_to_join { email } {
    Return a list of ids for clubs that the user with
    given email can join.
} {
    set user_id [user_id_from_email $email]

    return [::twt::oacs::eval "
        db_list can_join_club_ids {
            select f.community_id
                from dotlrn_clubs_full f
                where f.join_policy <> 'closed'
                  and f.club_id not in (select dotlrn_member_rels_full.community_id as club_id
                                          from dotlrn_member_rels_full
                                         where dotlrn_member_rels_full.user_id = '$user_id')
        }
    "]
}
