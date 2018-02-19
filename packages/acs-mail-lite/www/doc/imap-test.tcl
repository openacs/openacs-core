ad_page_contract {
    Provies a framework for manually testing acs_mail_lite procs
    A dummy mailbox value provided to show example of what is expected.
} {
    {user ""}
    {password ""}
    {mailbox {{or97.net}inbox}}
}
set user_id [ad_conn user_id]
set package_id [ad_conn package_id]
set admin_p [permission::permission_p \
                 -party_id $user_id \
                 -object_id $package_id \
                 -privilege admin ]
if { !$admin_p } {
    set content "Requires admin permission"
    ad_script_abort
}

#proc email_parse {struct_list {ref ""} } {
#    foreach {n v} $struct_list {
#        if { [string match {part.[0-9]*} $n] } {
#            set subref $ref
#            append subref [string range $n 4 end]
#            #puts "\n test1 '${v}' '${subref}'"          
#            email_parse $v $subref
# 
#        } else {
#            #puts "\t ${ref} > ${n} : ${v}"
#        }
#    }
#    return 1
#}
#
set content "acs-mail-lite/www/doc/imap.tcl start \n\n"
#ns_log Notice "$content"
# acs_mail_lite::imap_conn_go
set fl_list [list ]
ns_log Notice "test ns_imap open\n"
set mailbox_host [string range $mailbox 1 [string first "\}" $mailbox]-1]

ns_log Notice "0. mailbox '${mailbox}'"

set conn_id [ns_imap open -mailbox ${mailbox} -user $user -password $password ]
ns_log Notice "conn_id '${conn_id}'"

# ACL RIGHTS by hub cyrus: kxten 
# from: https://tools.ietf.org/html/rfc4314.html#page-5
# k = create mailboxes
# x delete mailbox
# t delete messages
# e perform expunge as a part of close
# n (obsolete) write shared annotations


# Session only Options are:
set status_list [ns_imap status $conn_id]
ns_log Notice "ns_imap status $conn_id = '${status_list}'"
append content "\n status_list '${status_list}'"

set ping [ns_imap ping $conn_id]
ns_log Notice "ns_imap ping $conn_id = '${ping}'"

set check_ct [ns_imap check $conn_id]
ns_log Notice "ns_imap check $conn_id = '${check_ct}'"

set n_msgs_ct [ns_imap n_msgs $conn_id]
ns_log Notice "ns_imap n_msgs $conn_id = '${n_msgs_ct}'"
append content "\nn_msgs_ct '${n_msgs_ct}'"

set n_recent_ct [ns_imap n_recent $conn_id]
ns_log Notice "ns_imap n_recent $conn_id = '${n_recent_ct}'"

if { ![f::even_p [llength $status_list] ] } {
    lappend status_list ""
}
array set status_arr $status_list
#set unseen_idx [lsearch -nocase -exact $status_list "unseen"]
#set unseen_ct [lindex $status_list $unseen_idx+1]
append content "\narray get status_arr '[array get status_arr]'"
set last [expr { $status_arr(Uidnext) - 1 }]
set first [expr { $last - $status_arr(Messages) + 1 } ]
set range $first
append range ":" $last
append content "\nfirst $first last $last range $range"
ns_log Notice "first $first last $last range $range"

#set check [ns_imap check $conn_id]
#ns_log Notice "ns_imap check $conn_id = '${check}'"

#should be:
#ns_imap list #s ref pattern ?substr?
# see example:  https://apple.stackexchange.com/questions/105145/what-are-the-default-special-folder-names-for-imap-accounts-in-mail-app-like-dr

# a session from osx terminal:

# A1 LIST "" "%"
# * LIST (\HasNoChildren) "." "Sent Messages"
# * LIST (\HasNoChildren) "." "Junk"
# * LIST (\HasNoChildren) "." "Archive"
# * LIST (\HasNoChildren) "." "Deleted Messages"
# * LIST (\HasNoChildren) "." "Notes"
# * LIST (\HasNoChildren) "." "Drafts"
# * LIST (\HasNoChildren) "." "INBOX"
# A1 OK List completed.

# also Example of an IMAP LIST in rfc6154: 
# https://tools.ietf.org/html/rfc6154#page-7
# ns_imap list $conn_id $mailbox pattern(* or %) substr

#set list [ns_imap list $conn_id $mailbox_host {}]
# returns: '{} noselect'  When logged in is not successful..
# set list [ns_imap list $conn_id $mailbox_host {*}]
# returns 'INBOX {} INBOX.Trash {} INBOX.sent-mail {}' when really logged in
# and mailbox_name part of mailbox is "", and mailbox is in form {{mailbox_host}}
# set list [ns_imap list $conn_id $mailbox_host {%}]
# returns 'INBOX {}' when really logged in
# and mailbox_name part of mailbox is ""
# If mailbox_name exists and is included in mailbox_host, returns '' 
# If mailbox_name separate from mailbox_host, and exists and in place of %, returns 'mailbox {}'
# for example 'INBOX.Trash {}'



#set expunge [ns_imap expunge $conn_id]
#ns_log Notice "ns_imap expunge $conn_id = '${expunge}'"


# ns_imap status #s 
# ns_imap error #s  ???
# ns_imap expunge #s ???
# ns_imap ping #s
# ns_imap check #s
# ns_imap list #s  list of mailbox using reference and pattern.
#                    glob with * for all mailboxes or % for * w/o ones in tree
# ns_imap lsub #s is ns_imap list for only subscribed mailboxes


# Options with #session and mailbox or other params
# ns_imap append #s mailbox text
# ns_imap copy #s sequence mailbox
# ns_imap move #s sequence mailbox
# ns_imap m_create #s mailbox
# ns_imap m_delete #s mailbox
# ns_imap  m_rename #s mailbox newname
# ns_imap search # searchCriteria (IMap2 criteria only)
# ns_imap subscribe #s mailbox
# ns_imap unsubscribe #s mailbox
# ns_imap sort #s criteria reverse -flags

#other 
# ns_imap parsedate datestring
# ns_imap getquote #s root
# ns_imap setquota #s root size
# ns_imap setacl #s mailbox user value

set messages1_list [ns_imap search $conn_id ""]
ns_log Notice "messages1_list' '${messages1_list}'"
#set messages2_lists [ns_imap sort $conn_id "date" 0 ]
#ns_log Notice "messages2_lists' '${messages2_lists}'"


#set test [ns_imap body $conn_id 1 1]
#ns_log Notice "imap-test.tcl: test '${test}'"
#ad_script_abort

foreach msgno $messages1_list {

    set struct_list [ns_imap struct $conn_id $msgno]
    ns_log Notice "ns_imap struct $msgno: '${struct_list}'"
    append content "</br></br>"
    append content "struct_list $struct_list </br>"
    # example value:
    #  'uid 6 flags {} size 3226 internaldate.day 17 internaldate.month 8 internaldate.year 2017 internaldate.hours 9 internaldate.minutes 25 internaldate.seconds 9 internaldate.zoccident 0 internaldate.zhours 0 internaldate.zminutes 0 type multipart encoding 7bit subtype REPORT body.report-type delivery-status body.boundary 1F5D214C96DE.1502961909/or97.net part.1 {type text encoding 7bit subtype PLAIN description Notification lines 15 bytes 589 body.charset us-ascii} part.2 {type message encoding 7bit subtype DELIVERY-STATUS description {Delivery report} bytes 449} part.3 {type message encoding 7bit subtype RFC822 description {Undelivered Message} lines 28 bytes 1134 message {type text encoding 7bit subtype PLAIN lines 3 bytes 10 body.charset utf-8 body.format flowed}} part.count 3 msgno 5'
    array unset hh_arr
    array unset pp_arr
    acs_mail_lite::imap_email_parse \
        -headers_arr_name hh_arr \
        -parts_arr_name pp_arr \
        -conn_id $conn_id \
        -msgno $msgno \
        -struct_list $struct_list

    #    append content "\n hh_arr [array get hh_arr] \n"
    #    append content "\n pp_arr [array get pp_arr] \n"

    
    #    set bodystruct_list [ns_imap bodystruct $conn_id $msgno]
    #    ns_log Notice "ns_imap bodystruct $msgno: '${bodystruct_list}'"
    # have we read it before?  check again uid's processed
    
    #array set headers_arr $struct_list
    #    ns_imap headers $conn_id $msgno -array headers_arr
    ##    ns_log Notice "array names headers_arr '[array names headers_arr]'"
    ##    ns_log Notice "array get headers_arr '[array get headers_arr]'"
    #    array set headers_arr $struct_list
    #    set type [acs_mail_lite::email_type -header_arr_name headers_arr]
    #    ns_log Notice "type '${type}'"
    # ns_imap headers #s msgno ?-array arr_name
    # ns_imap header #s msgno hdrname
    #ns_imap text $conn_id $msgno -flags UID/PEEK/INTERNAL (peek doesn't set \Seen flag)


    #    set msg_txt [ns_imap text $conn_id $msgno]
    #    set msg_start_max [expr { 72 * 15 } ]
    #    set msg_txtb [string range $msg_txt 0 $msg_start_max]
    #    if { [string length $msg_txt] > $msg_start_max + 400 } {
    #        set msg_txte [string range $msg_txt end-$msg_start_max end]
    #    } elseif { [string length $msg_txt] > $msg_start_max + 144 } {
    #        set msg_txte [string range $msg_txt end-144 end]
    #    } else {
    #        set msg_txte ""
    #    }
    #    ns_log Notice "ns_imap text $conn_id $msgno msg_txt: \
        # ${msg_txtb} ...  ${msg_txte}"

    # ns_imap body #s msgno part -flags UID/PEEK/INTERNAL
    #    set msg_list [ns_imap body $conn_id $msgno part -flags UID/PEEK/INTERNAL



}

#email specific
#ns_imap uid #s msgno   (gets UID of msgno)
# ns_imap headers #s msgno arr_name
# ns_imap header #s msgno hdrname
# ns_imap text #s msgno -flags UID/PEEK/INTERNAL (peek doesn't set \Seen flag)
# ns_imap body #s msgno part -flags UID/PEEK/INTERNAL


# ns_imap bodystruct #s msgno part -flags  (a subset of ns_imap struct)
# ns_imap delete #s sequence -flags
# ns_imap undelete #s sequence flags




ns_log Notice "0. test ns_imap close"
set conn_id [acs_mail_lite::imap_conn_close -conn_id $conn_id]

#append content [ns_imap open -mailbox {{hub.org}mail/INBOX} -testdummyparam -novalidatecert -user support -password "" ]
#set content [acs_mail_lite::imap_conn_go -host ${mailbox} -password $password -user $user]
append content \n \n [clock seconds]

#set struct_list [list uid 12 flags {} size 33487 internaldate.day 28 internaldate.month 1 internaldate.year 2017 internaldate.hours 4 internaldate.minutes 15 internaldate.seconds 7 internaldate.zoccident 0 internaldate.zhours 0 internaldate.zminutes 0 type multipart encoding 7bit subtype MIXED body.boundary ----=_Part_22057419_699298704.1485580507727 part.1 {type multipart encoding 7bit subtype ALTERNATIVE body.boundary ----=_Part_22057420_472295197.1485580507727 part.1 {type text encoding qprint subtype PLAIN lines 87 bytes 2182 disposition INLINE body.charset UTF-8} part.2 {type text encoding qprint subtype X-WATCH-HTML lines 11 bytes 286 disposition INLINE body.charset UTF-8} part.3 {type text encoding qprint subtype HTML lines 703 bytes 26358 disposition INLINE body.charset UTF-8} part.count 3} part.2 {type text encoding base64 subtype CALENDAR lines 13 bytes 1046 disposition ATTACHMENT disposition.filename Apple_Support_Appt.ics} part.count 2 msgno 11 ]

regsub -all -- {\n} $content {</br>} content
