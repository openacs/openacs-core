# Initialize global variables
global __server_url
set __server_url $server_url
global __admin_last_name
set __admin_last_name $admin_last_name
global __admin_email
set __admin_email $admin_email
global __admin_password
set __admin_password $admin_password
global __url_history
set __url_history [list]
global __demo_users_password
if { [info exists demo_users_password] } {
    set __demo_users_password $demo_users_password
} else {
    set __demo_users_password "guest"
}
global __dotlrn_users_data_file
if { [info exists dotlrn_users_data_file] } {
    set __dotlrn_users_data_file $dotlrn_users_data_file
} else {
    set __dotlrn_users_data_file users-data.csv
} 

# Extracted from OpenACS for generating random numbers 
# This is really over kill. I will use the Tcl builtin
# expr rand() instead
proc randomInit {seed} {
    global __random

    array set __random {}
    
    set __random(ia) 9301
    set __random(ic) 49297
    set __random(im) 233280
    set __random(seed) $seed
}
    
randomInit [clock seconds]

proc random {} {
    global __random

    set __random(seed) [expr ($__random(seed) * $__random(ia) + $__random(ic)) % $__random(im)]

    return [expr $__random(seed)/double($__random(im))]
}

proc randomRange {range} {

#    return [expr int([random] * $range)]
     return [expr int([expr rand()] * $range)]
}

proc get_random_items_from_list { list number } {

    # Build a list of indices
    set index_list [list]
    for { set i 0 } { $i < [llength $list] } { incr i } {
        lappend index_list $i
    }

    # If the list was empty - return
    if { [llength $index_list] == 0 } {
        return {}
    }

    # Cannot return more items than are in the list
    if { $number > [llength $list] } {
        error "get_random_items_from_list: cannot return $number items from list $list"
    }

    # Pick number random indices from the list. Remove each index that we have
    # already picked.
    set random_indices [list]
    for { set index_count 0 } { $index_count < $number } { incr index_count } {
        set random_index [randomRange [llength $index_list]]

        lappend random_indices [lindex $index_list $random_index]

        # Remove the index that we picked
        set index_list [lreplace $index_list $random_index $random_index]
    }

    # Build and return the items at the random indices
    set return_list [list]
    foreach index $random_indices {
        lappend return_list [lindex $list $index]
    }
    if { [llength $return_list] == 1 } {
        return [lindex $return_list 0]
    } else {
        return $return_list
    }
}

proc write_response_to_file { filename } {

    # Create the directory of the output file if it doesn't exist
    if { ![file isdirectory [file dirname $filename]] } { 
        exec mkdir -p [file dirname $filename] 
    }
    set file_id [open "$filename" w+]
    puts $file_id "[response body]"
}

# Start User data
ad_proc get_users_emails { {type ""} } {
    set user_emails [list]

    foreach user_data [get_users_data] {
        if { [empty_string_p $type] || \
                [string equal -nocase [lindex $user_data 4] $type] } {
            
            lappend user_emails [lindex $user_data 2]
        }
    }

    return $user_emails
}

proc get_random_users_of_type { type number } {
    set email_list [get_users_emails $type]

    return [get_random_items_from_list $email_list $number]
}

proc get_user_password { email } {
    global __demo_users_password

    return $__demo_users_password
}
# End user data

proc engineering_class_p { class_url } {

    return [regexp {dotlrn/classes/(computer-science|mathematics)} $class_url match]
}

proc follow_class_members_link {} {

    link follow ~u {members$}    
}

proc get_professor_for_class { class_url } {

    # TODO: find the professor of the class
    follow_class_members_link

    # This is fragile...
    # TODO regexping on HTML code is too fragile
    # write special pages that export such data instead

    return [get_random_users_of_type professor 1]
}

proc login_user { user_email user_password} {

    logout_user

    global __server_url

    # Request the start page
    do_request "$__server_url"

    # Login the user
    form find ~n login
    field find ~n email
    field fill "$user_email"
    field find ~n password
    field fill "$user_password"
    form submit
}

proc logout_user {} {
    global __server_url

    do_request "${__server_url}/register/logout"
}

proc login_site_wide_admin {} {
    global __server_url
    global __admin_email
    global __admin_password

    login_user $__admin_email $__admin_password
}

proc install_all_packages { server_url } {

    do_request "$server_url/acs-admin/apm/packages-install?checked_by_default_p=1"
    #assert text "Package Installation"
    # If there are no new packages to install, just return
    if { [regexp -nocase {no new packages to install} [response body] match] } {
        return
    }

    form submit

    # Sometimes there are failed dependencies for certain packages    
    # In this case we ignore those packages and continue
    if { [regexp {.*packages-install-2} "$::tclwebtest::url" match]} {
        form submit
    }

    #assert text "Select Data Model Scripts to Run"
    # Source SQL scripts (took 68s)
    form submit
}

proc add_main_site_folder { server_url folder_name } {

	do_request "$server_url/admin/site-map"

	link follow ~c "new sub folder" 
	form find ~a new 
	field find ~n name
	field fill "$folder_name"
	form submit
}

proc mount_main_site_package { server_url folder_name instance_name package_key } {

    do_request "$server_url/admin/site-map"

    # Follow the link to add a new application at the first matching folder name
    link find ~c $folder_name
    link follow ~c "new application"

    # Add the package instance
    form find ~a "package-new"
    field find ~n instance_name
    field fill "$instance_name"
    # package_key
    field select "$package_key"
    form submit
}

# FIXME: This proc is very vulnerable since the parameter-set form in
# the site-map uses parameter_id to identify parameters
proc submit_acs_param_internal { old_parameter_value new_parameter_value } {

    form find ~a "parameter-set-2"
    field find ~v "$old_parameter_value"
    field fill "$new_parameter_value"
    form submit
}

proc set_acs_subsite_param { server_url old_parameter_value parameter_value } {

    do_request "$server_url/admin/site-map"
    link follow ~u {parameter-set\?package%5fid=[0-9]+&package%5fkey=acs%2dsubsite&instance%5fname=Main%20Site}

    submit_acs_param_internal $old_parameter_value $parameter_value
}

proc set_acs_kernel_param { server_url param_section old_parameter_value parameter_value } {

    do_request "$server_url/admin/site-map"
    link follow ~u {parameter-set\?package%5fid=[0-9]+&package%5fkey=acs%2dkernel}

    if { ![string equal $param_section "acs-kernel"] } {
	link follow ~c "$param_section"
    }

    submit_acs_param_internal $old_parameter_value $parameter_value
}

proc add_user { 
    server_url 
    first_names 
    last_name 
    email 
    id
    type
    full_access
    guest
} {
    do_request "$server_url/dotlrn/admin/users"
    link follow ~u "user-add"

    form find ~a "/dotlrn/user-add"
    field find ~n "email"
    field fill $email
    field find ~n "first_names"
    field fill $first_names
    field find ~n "last_name"
    field fill $last_name
    field find ~n "password"
    field fill [get_user_password $email]
    field find ~n "password_confirm"
    field fill [get_user_password $email]
    field find ~n "secret_question"
    field fill 1
    field find ~n "secret_answer"
    field fill 1
    form submit

    form find ~n add_user
    field find ~n "id"
    field select $type

    # FIXME: TclWebTest chooses option based on label rather than value
    # Full Access or Limited Access
    field select $full_access
    # Yes or No
    field select $guest
    form submit    
}

proc get_users_data {} {

    # Let's cache the data
    global __users_data
    
    if { [info exists __users_data] } {
        return $__users_data
    }

    global __dotlrn_users_data_file

    set file_id [open "$__dotlrn_users_data_file" r]
    set file_contents [read -nonewline $file_id]
    set file_lines_list [split $file_contents "\n"]

    set return_list [list]

    foreach line $file_lines_list {
	set fields_list [split $line ","]

	# Allow commenting of lines with hash
	if { ![regexp {\#.+} "[string trim [lindex $fields_list 0]]" match] } {
	    
	    # FIXME: TclWebTest chooses option based on label rather than value
	    # This is a workaround that converts values to labels
	    if { [string trim [lindex $fields_list 5]] == "1" } {
		set full_access "Full Access"
	    } else {
		set full_access "Limited Access"
	    }	
	    if { [string trim [lindex $fields_list 6]] == "t" } {
		set guest "Yes"
	    } else {
		set guest "No"
	    }
	    set type [string trim [lindex $fields_list 4]]
	    if { $type == "admin" } {
		set type "Staff"
	    }
             
	    lappend return_list [list \
		    [string trim [lindex $fields_list 0]] \
		    [string trim [lindex $fields_list 1]] \
		    [string trim [lindex $fields_list 2]] \
		    [string trim [lindex $fields_list 3]] \
		    $type \
		    $full_access \
		    $guest]

	}
    }

    set __users_data $return_list

    return $return_list
}

proc upload_users { server_url } {

# File upload
# Does not work - TclWebTest does not support file upload yet
#    do_request "$server_url/dotlrn/admin/users-bulk-upload"

#    form find ~a "users-bulk-upload-2"
#    field find ~n "users_csv_file"
#    field fill "$users_csv_file"
#    form submit

    set users_data_list [get_users_data]

    foreach user_data $users_data_list {

	    add_user $server_url \
		    [lindex $user_data 0] \
		    [lindex $user_data 1] \
		    [lindex $user_data 2] \
		    [lindex $user_data 3] \
		    [lindex $user_data 4] \
		    [lindex $user_data 5] \
		    [lindex $user_data 6]

    }
}

proc set_users_passwords { server_url } {
    
    foreach user_email [get_users_emails] {
        #puts "setting guest password for user $user_email"

        # User admin page
        do_request "${server_url}/dotlrn/admin/users"

        form find ~a "users-search"
        field fill $user_email ~n name    
        form submit

        # User workspace
        link follow ~u {user\?}

        # change password
        link follow ~u {password-update\?}

        form find ~a password-update-2
        field fill [get_user_password $user_email] ~n password_1
        field fill [get_user_password $user_email] ~n password_2
        form submit
    }
}

proc add_term { server_url term_name start_month start_year end_month end_year } {

    do_request "$server_url/dotlrn/admin/term-new"
    form find ~n add_term
    field find ~n "term_name"

    field fill "$term_name"
    # Start date
    field select $start_month
    field select "01"
    field find ~n "start_date.year"
    field fill $start_year
    # End date
    field select $end_month
    field select "01"
    field find ~n "end_date.year"
    field fill $end_year
    form submit
}

proc setup_terms { server_url } {

    add_term $server_url "Fall" "September" "2003" "January" "2004"    
    add_term $server_url "Spring" "January" "2004" "July" "2004"
    add_term $server_url "Fall" "September" "2004" "January" "2005"    
}

proc add_department { server_url pretty_name description external_url } {

    do_request "$server_url/dotlrn/admin/department-new"
    form find ~n add_department
    field find ~n "pretty_name"
    field fill $pretty_name
    field find ~n "description"
    field fill $description 
    field find ~n "external_url"
    field fill $external_url

    form submit
}

proc setup_departments { server_url } {

    add_department $server_url "Mathematics" \
	                       "The Faculty of Mathematics consists of the Department of Applied Mathematics & Theoretical Physics (DAMTP) and the Department of Pure Mathematics & Mathematical Statistics (DPMMS). The  Statistical Laboratory is a sub-department of the DPMMS. Also located within the University of Cambridge is the Isaac Newton Institute for Mathematical Sciences." \
			       "http://www.maths.cam.ac.uk/"

    add_department $server_url "Computer Science" \
	                       "The Computer Laboratory is the Computer Science department of the University of Cambridge. The University Computing Service has a separate set of web pages." \
			       "http://www.cl.cam.ac.uk/"

    add_department $server_url "Architecture" \
	                       "Because of the great diversity of offerings in the College of Environmental Design and in the Department of Architecture in areas such as building environments, practice of design, design methods, structures and construction, history, social and cultural factors in design, and design itself, it is possible to obtain either a very broad and general foundation or to concentrate in one or several areas." \
	                       "http://arch.ced.berkeley.edu/"

    add_department $server_url "Business Administration" \
                               "The department offers a range of courses in Business Administration, Finance, and Law" \
                               "http://mitsloan.mit.edu/"
}

proc add_subject { server_url department_pretty_name pretty_name description } {

    do_request "$server_url/dotlrn/admin/class-new"

    form find ~n add_class
    field find ~n "form:id"
    field select "$department_pretty_name"
    field find ~n "pretty_name"
    field fill $pretty_name
    field find ~n "description"
    field fill $description

    form submit
}

proc setup_subjects { server_url } {

    # Mathematics Department
    add_subject $server_url "Mathematics" "Differential Geometry" " An introduction to differential geometry with applications to general relativity. Metrics, Lie bracket, connections, geodesics, tensors, intrinsic and extrinsic curvature are studied on abstractly defined manifolds using coordinate charts. Curves and surfaces in three dimensions are studied as important special cases. Gauss-Bonnet theorem for surfaces and selected introductory topics in special and general relativity are also studied. 18.100 is required, 18.101 is strongly recommended, and 18.901 would be helpful."

    # Computer Science department
    add_subject $server_url "Computer Science" "Peer to Peer Computing" "The term peer-to-peer (P2P) refers to a class of systems and applications that employ distributed resources to perform a critical function in a decentralized manner..."

    add_subject $server_url "Computer Science" "Advanced Topics in Programming Languages" "This course focuses on bioinformatics applications, high-performance computing, and the application of high-performance computing to bioinformatics applications."

    add_subject $server_url "Computer Science" "Computer and Network Security" "This class serves as an introduction to information systems security and covers security issues at an undergraduate level"

    # Architecture Department
    add_subject $server_url "Architecture" "Architecture and Culture" "Selected examples of architecture and interior design are used as case studies to illustrate the presence of ideas in built matter. A range of projects are analysed and discussed in terms of the conceptual qualities that underpin the physical manifestations of architecture and interior design."

    # Business Administration Department
    add_subject $server_url "Business Administration" "Economic Analysis for Business Decisions" " Introduces students to principles of microeconomic analysis used in managerial decision making. Topics include demand analysis, cost and production functions, the behavior of competitive and non-competitive markets, sources and uses of market power, and game theory and competitive strategy, with applications to various business and public policy decisions. Antitrust policy and other government regulations are also discussed. 15.010 restricted to first-year Sloan masters students. 15.011 primarily for non-Sloan School students."

    add_subject $server_url "Business Administration" "Organizational Psychology & Sociology" "Organizations are changing rapidly. To deal with these changes requires new skills and attitudes on the part of managers. The goal of the OPS course is to make you aware of this challenge and equip you to better meet it. In short, the purpose is to acquaint you with some of psychological and sociological phenomena that regularly occur in organizations - the less visible forces that influence employee and managerial behavior.  The aim is to increase your understanding of these forces -- in yourself and in others -- so that as they become more visible, they become manageable (more or less) and hence subject to analysis and choice."

    add_subject $server_url "Business Administration" "Advanced Corporate Finance" "The primary objective of the advanced corporate finance course is to conduct an in-depth analysis of special topics of interest to corporate finance managers.  Our attempt will be to obtain a detailed understanding of the motives and reasons that lead to certain corporate decisions specifically in relation to the following issues: Mergers and Acquisitions, Corporate Restructurings, Corporate Bankruptcy, Corporate Governance"
}

proc get_class_add_urls_foreach_subject { server_url } {

    return [get_list_of_urls_from_links $server_url "$server_url/dotlrn/admin/classes" "class-instance-new"]
}

proc get_list_of_urls_from_links { server_url page_url link_url_pattern } {

    do_request "$page_url"

    set urls_list [list]

    # Loop over and add all links
    set errno "0"
    while { $errno == "0" } {
	set errno [catch {
            array set link_array [link find -next ~u "$link_url_pattern"]} error]

         if { [string equal $errno "0"] } {
            set url $link_array(url)
     
            if { [regexp {http://} $url match] } {
                # Fully qualified URL
                lappend urls_list $url
            } elseif { [string index $url 0] == "/" } {
                # Absolute path
                lappend urls_list ${server_url}${url}
            } else {
                # Relative path
                regexp {(http://[^?]+/)} $page_url match dir_url
                lappend urls_list ${dir_url}${url}
            }
        }
    }
    

    return $urls_list
}

proc get_class_admin_urls { server_url term_pretty_name } {
    set admin_url_base "$server_url/dotlrn/admin/term"
    set admin_url_no_term "${admin_url_base}?term_id=-1"

    # First extract the term_id corresponding to the term_pretty_name
    do_request $admin_url_no_term
    form find ~n term_form
    field find ~n term_id
    field select $term_pretty_name
    array set term_select_field [field current]
    set term_id $term_select_field(value)

    set admin_url_term "${admin_url_base}?term_id=$term_id"

    return [get_list_of_urls_from_links $server_url $admin_url_term {/dotlrn/classes/.*/one-community-admin$}]
}

proc setup_classes { server_url } {

    setup_classes_for_term $server_url "Fall 2003/2004"
    setup_classes_for_term $server_url "Spring 2004"
}

proc setup_classes_for_term { server_url term_name } {

    foreach link [get_class_add_urls_foreach_subject $server_url] {

        do_request $link
        form find ~n "add_class_instance"
        field find
        field select $term_name
        field find ~n pretty_name
        array set name_field [field current]
        set pretty_name $name_field(value)
        field fill "$pretty_name $term_name"
        form submit
    }
}

proc setup_class_memberships { server_url } {

    foreach admin_url [get_class_admin_urls $server_url "Fall 2003/2004"] {

        # Admin page for the class
        do_request "$admin_url"

        # Member management for the class
        follow_class_members_link

        # Add all students
        add_class_members [get_users_emails student] "Student"

        # Add a random professor
        add_class_member [get_random_users_of_type professor 1] "Professor"

        # Add two random staff
        set admin_users [get_random_users_of_type staff 2]
        set admin_labels [list "Course Assistant" "Teaching Assistant"]
        set admin_counter 0
        for { set admin_counter 0 } \
            { [expr $admin_counter < 2 && $admin_counter < [llength $admin_users]] } \
            { incr admin_counter } {

            set admin_label [get_random_items_from_list $admin_labels 1]
            add_class_member [lindex $admin_users $admin_counter] $admin_label
        }
    }
}

proc setup_class_subgroups { server_url } {

    foreach admin_url [get_class_admin_urls $server_url "Fall 2003/2004"] {

        foreach {name description policy} [subcommunity_properties_list] {

            # Admin page of one class
            do_request $admin_url

            # Add subcommunity form
            link follow ~u subcommunity-new

            form find ~n add_subcomm
            field fill $name ~n pretty_name
            field fill $description ~n description
            field find ~n join_policy
            field select $policy
            form submit
        }
    }    
}

proc add_default_class_forums { server_url } {

    foreach admin_url [get_class_admin_urls $server_url "Fall 2003/2004"] {

        # Admin page of one class
        do_request $admin_url

        # Add forum form
        link follow ~u forum-new

        form find ~n forum
        field fill "This is a general discussion forum where teachers, assistants, and students can come together to discuss the subject of the class or practical matters surrounding exams, assignments, project work etc." ~n charter
        form submit        
    }    
}

proc add_member_applet_to_classes { server_url } {

    foreach admin_url [get_class_admin_urls $server_url "Fall 2003/2004"] {

        # Only add the members applet to computing classes so that we can
        # demo adding it to other classes manually
        if { [regexp -nocase {comput} $admin_url match] } {

            # Admin page of the class
            do_request $admin_url
        
            # Manage Applets
            link follow ~u {applets$}

            # Add the Members Info applet
            link follow ~u {applet-add.*applet_key=dotlrn_members}
        }
    }
}

proc add_class_news_items { server_url } {

    set news_item_list [get_news_items]

    set class_counter 0
    foreach admin_url [get_class_admin_urls $server_url "Fall 2003/2004"] {

        # We want the professor of the class to post the news item
        # TODO
        #set email [get_professor_for_class $admin_url]
        #login_user $email [get_user_password $email]

        # Admin page of the class
        do_request $admin_url

        # News item add
        link follow ~u {news/+item-create}

        set news_item [get_random_news_item $news_item_list $class_counter]

        form find ~a preview
        set publish_title [lindex $news_item 0]
        set publish_body [lindex $news_item 1]
        field fill $publish_title ~n publish_title
        field fill $publish_body ~n publish_body
        field check ~n permanent_p
        form submit

        # confirm
        form find ~a {item-create-3}

        form submit
        
        incr class_counter
    }

    # Re-login the site-wide admin
    login_site_wide_admin
}

proc get_random_news_item { news_list counter } {

    set item_index [expr $counter % [llength $news_list]]

    return [lindex $news_list $item_index]
}

proc get_news_items {} {

    set news_item_list [list]

    lappend news_item_list {{The exam is postponed by one week} {The final exam previously planned for the 20:th of December will be on the 3:d of January instead - the calendar has been updated}}
    
    lappend news_item_list {{Recommended Reading for friday workshop} {For the friday workshop reading up on chapter three of the course materials is strongly recommended. See you on friday!}}

    lappend news_item_list {{Class Assistants Needed} {We need more people to assist with the seminar on tuesday - let me know if you are interested!}}

    lappend news_item_list {{Changed Schedule} {We have decided to adjust the schedule slightly by moving section 6 and 8 of the of the text book to be treated in december.}}

    lappend news_item_list {{Deadline for assignment II on thursday} {We need to have the homework assignments handed in for review no later than this thursday}}

    lappend news_item_list {{Project Group Meeting} {We will hold an extra project group meeting on next wednesday to plan and discuss the various topics that have been suggested.}}

    return $news_item_list
}

proc subcommunity_properties_list {} {

    set property_list [list]

    foreach letter {A B} {
        set pretty_name "Project Group $letter"
        lappend property_list $pretty_name
        lappend property_list "Workspace for people working in $pretty_name"
        lappend property_list "Needs Approval"    
    }

    return $property_list
}

proc add_class_members { email_list role } {
    foreach email $email_list {
        add_class_member $email $role
    }
}

proc add_class_member { email role } {

    if { [empty_string_p $email] } {
        return
    }

    # Search for the student to add
    form find ~a member-add
    field find ~n search_text
    field fill $email
    form submit

    # Pick the user (there should be only one)
    link follow ~u member-add-2

    # add as student (default)
    form find ~a "member-add-3"

    field find ~n rel_type
    field select $role
    form submit
}

proc setup_communities { server_url } {

    add_community $server_url "Tennis Club" "Community for the university tennis club with tournaments and other events, also helps you find people to play with." "Open"
    add_community $server_url "Business Alumni Class of 1997" "Alumni community for the Business Administration graduates from the class of 1997." "Closed"
    add_community $server_url "Business Administration Program" "Community for all students following the Business Administration Program" "Closed"
    add_community $server_url "Star Trek Fan Club" "Community for die-hard fans of Star Trek" "Needs Approval"
}

proc add_community { server_url name description policy } {
    
    do_request "${server_url}/dotlrn/admin/club-new"    

    form find ~n add_club

    field find ~n pretty_name
    field fill $name
    field find ~n description
    field fill $description
    field find ~n join_policy
    field select $policy

    form submit
}

proc add_site_wide_admin_to_dotlrn { server_url } {

    global __admin_last_name

    # Goto users page
    do_request "$server_url/dotlrn/admin/users?type=pending"

    # Goto the community page for the site-wide admin (assuming he's first in the list)
    link follow ~u {user\?user_id=}

    # Follow the add to dotlrn link
    link follow ~u "user-new-2"

    # Use defaults (external with full access)
    form find ~a "user-new-2"
    form submit
}

proc crawl_links {} {

    global __url_history

    set start_url [lindex $__url_history end]

    # Return if given start URL is external
    global __server_url
    set absolute_url [tclwebtest::absolute_link $start_url]
    if { [string first $__server_url $absolute_url] == -1 } {
        #puts "not following link to external url $absolute_url"
        return
    }

    # Also return if this is the logout link
    if { [regexp {/register/logout} $start_url match] } {
        #puts "not following logout link"
        return
    }

    do_request $start_url

    set errno 0
    while { $errno == "0" } {
	set errno [catch {
            array set link_array [link find -next]} error]

         if { [string equal $errno "0"] } {
            set url $link_array(url)

            # Don't revisit URL:s we have already tested
            # Don't follow relative anchors on pages - can't get them to work with TclWebtest
            if { [lsearch -exact $__url_history $url] == -1 && [string range $url 0 0] != "#" } {
                #puts "$start_url following url $url"

                lappend __url_history $url

                crawl_links
            } else {
                #puts "$start_url skipping url $url as visited before"
            }
         }
   }
}
