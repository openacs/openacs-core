ad_library {

    Procedures used only in admin pages (mostly the user class stuff).

    @author Multiple
    @creation-date 11/18/98
    @cvs-id $Id$

}

ad_proc -public ad_restrict_to_https {conn args why} {
    Redirects user to HTTPS.

    @author Allen Pulsifer (pulsifer@mediaone.net)
    @creation-date 2 November 2000
} {
    if { [security::secure_conn_p] } {
        return "filter_ok"
    }

    ad_returnredirect [security::get_secure_qualified_url [ad_return_url]]
    # No abort since in filter
    
    return "filter_return"
}

ad_proc -public ad_approval_system_inuse_p {} {
    Returns 1 if the system is configured to use and approval system.
} {
    if {[parameter::get -parameter RegistrationRequiresEmailVerification] && 
	[parameter::get -parameter RegistrationRequiresApprovalP] } {
	return 1
    } else {
	return 0
    }
}

ad_proc -private ad_user_class_parameters {} {
    Returns the list of parameter var names used to define a user class.
} {
    return {
        category_id country_code usps_abbrev intranet_user_p
        group_id last_name_starts_with email_starts_with expensive
        user_state sex age_above_years age_below_years
        registration_during_month registration_before_days
        registration_after_days registration_after_date
        last_login_before_days last_login_after_days
        last_login_equals_days number_visits_below number_visits_above
        user_class_id sql_post_select crm_state
        curriculum_elements_completed
    }
}
 
ad_proc -private ad_user_class_description { set_id } {
    Takes an ns_set of key/value pairs and produces a human-readable
    description of the class of users specified.
} {
    set clauses [list]
    set pretty_description ""

    # turn all the parameters in the ns_set into Tcl vars
    ad_ns_set_to_tcl_vars -duplicates fail $set_id 
    
    # All the SQL statements are named after the criteria name (e.g. category_id)

    foreach criteria [ad_user_class_parameters] {
	if { [info exists $criteria] && [set $criteria] ne "" } {

	    switch -- $criteria {
		"category_id" {
		    set pretty_category [db_string $criteria {
			select category from categories where category_id = :category_id
		    } ]
		    lappend clauses "said they were interested in $pretty_category"
		}
		"country_code" {
		    set pretty_country [db_string $criteria {
			select country_name from country_codes where iso = :country_code
		    } ]
		    lappend clauses "told us that they live in $pretty_country"
		}
		"usps_abbrev" {
		    set pretty_state [db_string $criteria {
			select state_name from states where usps_abbrev = :usps_abbrev
		    } ]
		    lappend clauses "told us that they live in $pretty_state"
		}
		"intranet_user_p" {
		    lappend clauses "are an employee"
		}
		"group_id" {
		    set group_name [db_string $criteria {
			select group_name from groups where group_id = :group_id
		    } ]
		    lappend clauses "are a member of $group_name"
		}
		"last_name_starts_with" {
		    lappend clauses "have a last name starting with $last_name_starts_with"
		}
		"email_starts_with" {
		    lappend clauses "have an email address starting with $email_starts_with"
		}	
		"expensive" {
		    lappend clauses "have accumulated unpaid charges of more than [parameter::get -parameter ExpensiveThreshold]"
		}
		"user_state" {
		    lappend clauses "have user state of $user_state"
		}
		"sex" {
		    lappend clauses "are $sex."
		}
		"age_above_years" {
		    lappend clauses "is older than $age_above_years years"
		}
		"age_below_years" {
		    lappend clauses "is younger than $age_below_years years"
		}
		"registration_during_month" {
		    set pretty_during_month [db_string $criteria {
			select to_char(to_date(:registration_during_month,'YYYYMM'),'fmMonth YYYY') from dual
		    } ]
		    lappend clauses "registered during $pretty_during_month"
		}
		"registration_before_days" {
		    lappend clauses "registered over $registration_before_days days ago"
		}
		"registration_after_days" {
		    lappend clauses "registered in the last $registration_after_days days"
		}
		"registration_after_date" {
		    lappend clauses "registered on or after $registration_after_date"
		}
		"last_login_before_days" {
		    lappend clauses "have not visited the site in $last_login_before_days days"
		}
		"last_login_after_days" {
		    lappend clauses "have not visited the site in $last_login_after_days days"
		}
		"last_login_equals_days" {
		    if { $last_login_equals_days == 1 } {
			lappend clauses "visited the site exactly 1 day ago"
		    } else {
			lappend clauses "visited the site exactly $last_login_equals_days days ago"
		    }
		}
		"number_of_visits_below" {
		    lappend clauses "have visited less than $number_visits_below times"
		}
		"number_of_visits_above" {
		    lappend clauses "have visited more than $number_visits_above times"
		}
		"user_class_id" {
		    set pretty_class_name [db_string $criteria {
			select name from user_classes where user_class_id = :user_class_id
		    } ]
		    lappend clauses "are in the user class $pretty_class_name"
		}
		"sql_post_select" {
		    lappend clauses "are returned by \"<i>select users(*) from $sql_post_select</i>"
		}
		"crm_state" {
		    lappend clauses "are in the customer state \"$crm_state\""
		}
		"curriculum_elements_completed" {
		    if { $curriculum_elements_completed == 1 } {
			lappend clauses "who have completed exactly $curriculum_elements_completed curriculum element"
		    } else {
			lappend clauses "who have completed exactly $curriculum_elements_completed curriculum elements"
		    }
		}
	    }
	}
    }

    if { [info exists combine_method] && $combine_method eq "or" } {
	set pretty_description [join $clauses " or "]
    } else {
	set pretty_description [join $clauses " and "]
    }

    return $pretty_description
}


ad_proc -private ad_registration_finite_state_machine_admin_links {
    -nohtml:boolean
    member_state
    email_verified_p
    user_id
    {return_url ""}
} {
    Returns the admininistation links to change the user's state
    in the user_state finite state machine. If the nohtml switch
    is set, then a list of lists will be returned (url label).
} {
    set user_finite_states [list]
    switch -- $member_state {
        "approved" {
            lappend user_finite_states \
                [list [export_vars -base "/acs-admin/users/member-state-change" {
                    user_id return_url {member_state banned}
                }] [_ acs-tcl.ban]] \
                [list [export_vars -base "/acs-admin/users/member-state-change" {
                    user_id return_url {member_state deleted}
                }] [_ acs-tcl.delete]]
        }
        "deleted" {
            lappend user_finite_states \
                [list [export_vars -base "/acs-admin/users/member-state-change" {
                    user_id return_url {member_state approved}
                }] [_ acs-tcl.undelete]] \
                [list [export_vars -base "/acs-admin/users/member-state-change" {
                    user_id return_url {member_state banned}
                }] [_ acs-tcl.ban]]
        }
        "needs approval" {
            lappend user_finite_states \
                [list [export_vars -base "/acs-admin/users/member-state-change" {
                    user_id return_url {member_state approved}
                }] [_ acs-tcl.approve]] \
                [list [export_vars -base "/acs-admin/users/member-state-change" {
                    user_id return_url {member_state rejected}
                }] [_ acs-tcl.reject]]
        }
        "rejected" {
            lappend user_finite_states \
                [list [export_vars -base "/acs-admin/users/member-state-change" {
                    user_id return_url {member_state approved}
                }] [_ acs-tcl.approve]]
        }
        "banned" {
            lappend user_finite_states \
                [list [export_vars -base "/acs-admin/users/member-state-change" {
                    user_id return_url {member_state approved}
                }] [_ acs-tcl.approve]]
        }
    }

    if { $email_verified_p == "t" } {
        lappend user_finite_states \
            [list [export_vars -base "/acs-admin/users/member-state-change" {
                user_id return_url {email_verified_p f}
            }] [_ acs-tcl.lt_require_email_verific]]
    } else {
        lappend user_finite_states \
            [list [export_vars -base "/acs-admin/users/member-state-change" {
                user_id return_url {email_verified_p t}
            }] [_ acs-tcl.approve_email]]
    }

    if { $nohtml_p } {

        # Return the list of lists (url label)
        return $user_finite_states

    } else {

        # Build a list of anchor tags

        set user_finite_state_links {}
        foreach elm $user_finite_states {
            lassign $elm url label
            lappend user_finite_state_links [subst {<a href="[ns_quotehtml $url]">$label</a>}]
        }
        
        return $user_finite_state_links

    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
