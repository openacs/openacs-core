ad_page_contract {
    Sends an email to the user with user_id = sendto
    
    @author Miguel Marin (miguelmarin@viaro.net) Viaro Networks (www.viaro.net)
} {
    sendto:notnull
    {return_url ""}
} -properties {
    context:onevalue
}

set user_id [auth::require_login -account_status closed]
set page_title "\#acs-subsite.Send_email_to_this_user\#"
set context [list [list [ad_pvt_home] [ad_pvt_home_name]] "Send Email"]


if {$return_url eq ""} {
    set return_url [ad_pvt_home]
}

db_1row user_to_info { *SQL* }
set from [email_image::get_email -user_id $user_id]

ad_form -name send-email -export {sendto return_url} -form {
    {from:text(text),optional
        {label "From:"}
        {html {{disabled ""} {size 40}}}
        {value $from}
    }
    {subject:text(text)
        {label "Subject:"}
        {html {size 70}}
    }
    {body:text(textarea),nospell
        {label "Body:"}
        {html {rows 10 cols 55}}
        {value ""}
    }
} -on_submit {

    set to [email_image::get_email -user_id $sendto]

    if {[catch {acs_mail_lite::send -send_immediately -to_addr $to -from_addr $from -subject $subject -body $body} errmsg]} {
        ad_return_error "Mail Failed" "<p>The system was unable to send email.  Please notify the user personally. This problem is probably caused by a misconfiguration of your email system.  Here is the error:</p>
                    <div><code> [ad_quotehtml $errmsg] </code></div>"
    }
    
} -after_submit {
    ad_returnredirect $return_url
}
