<master>
  <property name="title">@title;noquote@</property>
  <property name="context">@context;noquote@</property>
  <h1>@title@</h1>
  <p><strong>The information on this page is volatile and likely changed.</strong>
    Refer to API documentation for specifics on existing system.</p>
<p>An incoming email system in general:</p>
  <ol>
	<li>scans for e-mails on a regular basis.</li>
	<li>checks if any email came from an auto mailer.</li>
	<li>Parses new ones, and</li>
	<li>processes them by firing off callbacks.</li>
  </ol>
 


<h2>Legacy implementation notes for OpenACS 5.9</h2>
  <h3>email filters</h3>
  <p>
    Vinod has made a check for auto mailers by using procmail as follows.
    Maybe we could get this dragged into Tcl code (using regexp or a Procmail recipe parser) instead, thereby removing the need for setting up procmail in the first place.
  </p>
  <p>
<a href="/forums/message-view?message%5fid=539009">Revised procmail filters:</a>
</p>

<pre>
    :0 w * ^subject:.*Out of Office AutoReply /dev/null 
    :0 w * ^subject:.*Out of Office /dev/null :0 w * ^subject:.*out of the office /dev/null 
    :0 w * ^subject:.*NDN /dev/null :0 w * ^subject:.*[QuickML] Error: /dev/null 
    :0 w * ^subject:.*autoreply /dev/null :0 w * ^from.*mailer.*daemon /dev/null

</pre>

  <p>
To make things granular a separate parsing procedure should deal with loading the e-mail into the Tcl interpreter and setting variables in an array for further processing.
</p>

  <pre>
    ad_proc parse_email { 
    -file:required
    -array:required
    } { 
    ...
    }

</pre>
<h2>parsing email</h2>
  <p>
    An email is split into several parts: headers, bodies and files.
  </p>
  
  <p>
    The headers consists of a list with header names as keys and their corresponding values.
    All keys are lower case.
  </p>
  
  <p>
    The bodies consists of a list with two elements: content-type and content.
  </p>

  <p>
    The files consists of a list with three elements: content-type, filename and content.
  </p>

  <p>
    An array with all the above data is upvarred to the caller environment.
  </p>

  <p>
    Processing an email should result in an array like this:
  </p>

  <h3>HEADERS</h3>

  <ul>
	<li>message_id</li>
	<li>subject</li>
	<li>from</li>
	<li>to</li>
	<li>date</li>
	<li>received</li>
	<li>references</li>
	<li>in-reply-to</li>
	<li>return-path</li>
	<li>...</li>
  </ul>

  <p>
    X-Headers:
  </p>

  <ul>
	<li>X-Mozilla-Status</li>
	<li>X-Virus Scanned</li>
	<li>...</li>
  </ul>

  <p>
    We do not know which headers are going to be available in the e-mail.
    We set all headers found in the array.
    The callback implementation then checks if a certain header is present or not.
  </p>

<pre>
    #get all available headers
    set keys [mime::getheader $mime -names]
    
    set headers [list]

    # create both the headers array and all headers directly for the email array
    foreach header $keys {
    set value [mime::getheader $mime $header]
    set email([string tolower $header]) $value
    lappend headers [list $header $value]
    }
    set email(headers) $headers
  
</pre>

  <h3>Bodies </h3>

  <p>
    An e-mail usually consists of one or more bodies.
    With the advent of complex_send, OpenACS supports sending of multi-part e-mails.
    Use complex_send when you want to send out and e-mail in text/html and text/plain.
    Some email clients only recognize text/plain.
  </p>

<pre>
    switch [mime::getproperty $part content] {
    &quot;text/plain&quot; {
    lappend bodies [list &quot;text/plain&quot; [mime::getbody $part]]
    }
    &quot;text/html&quot; {
    lappend bodies [list &quot;text/html&quot; [mime::getbody $part]]
    }
    }
  
</pre>

  <h3>Files</h3>

  <p>
    OpenACS supports tcllib mime functions.
    Getting incoming files to work is a matter of looking for a part where there exists a &quot;Content-disposition&quot; part.
    All these parts are file parts.
    Together with scanning for email bodies, code looks something like this:
</p>

<pre>
    set bodies [list]
    set files [list]
    
    #now extract all parts (bodies/files) and fill the email array
    foreach part $all_parts {

    # Attachments have a &quot;Content-disposition&quot; part
    # Therefore we filter out if it is an attachment here
    if {[catch {mime::getheader $part Content-disposition}]} {
    switch [mime::getproperty $part content] {
    &quot;text/plain&quot; {
    lappend bodies [list &quot;text/plain&quot; [mime::getbody $part]]
    }
    &quot;text/html&quot; {
    lappend bodies [list &quot;text/html&quot; [mime::getbody $part]]
    }
    }
    } else {
    set encoding [mime::getproperty $part encoding]
    set body [mime::getbody $part -decode]
    set content  $body
    set params [mime::getproperty $part params]
    if {[lindex $params 0] == &quot;name&quot;} {
    set filename [lindex $params 1]
    } else {
    set filename &quot;&quot;
    }

    # Determine the content_type
    set content_type [mime::getproperty $part content]
    if {$content_type eq &quot;application/octet-stream&quot;} {
    set content_type [ns_guesstype $filename]
    }

    lappend files [list $content_type $encoding $filename $content]
    }
    }
    set email(bodies) $bodies
    set email(files) $files
</pre>

  <p>
    Note that the files ie attachments are actually stored in the /tmp directory from where they can be processed further.
    It is up to the callback to decide if to import the file into OpenACS or not.
    Once all callbacks have been fired files in /tmp will have to be deleted again though.
</p>

  <h2>Firing off callbacks </h2>

  <p>
    Now that we have the e-mail parsed and have an array with all the information, we can fire off the callbacks.
    The firing should happen in two stages.
</p>

  <p>
    The first stage is where we support a syntax like &quot;object_id@yoursite.com&quot;.
</p>

  <p>
    Second, incoming e-mail could look up the object_type, and then call the callback implementation specific to this object_type.
    If object_type = &#39;content_item&#39;, use content_type instead. 
</p>

  <code>
    ad_proc -public -callback acs_mail_lite::incoming_object_email { -array:required -object_id:required } { }
</code>

  <cpde>
    callback acs_mail_lite::incoming_object_email -impl $object_type -array email -object_id $object_id
</cpde>

<pre>
    ad_proc -public -callback acs_mail_lite::incoming_object_email -impl user {

    -array:required

    -object_id:required

    } {

    Implementation of mail through support for incoming emails

    } {

    # get a reference to the email array

    upvar $array email

    # make the bodies an array

    template::util::list_of_lists_to_array $email(bodies) email_body

    if {[exists_and_not_null email_body(text/html)]} {

    set body $email_body(text/html)

    } else {

    set body $email_body(text/plain)

    }

    set reply_to_addr &quot;[party::get_by_email $email(from)]@[ad_url]&quot;

    acs_mail_lite::complex_send \

    -from_addr $from_addr \

    -reply_to $reply_to_addr \

    -to_addr $to_addr \

    -subject $email(subject) \

    -body $body \

    -single_email \

    -send_immediately

    }

</pre>

  <p>
    Object id based implementations are useful for automatically generating &quot;reply-to&quot; addresses.
    With ProjectManager and Contacts object_id is also handy, because Project / TaskID is prominently placed on the website.
    If you are working on a task and you get an e-mail by your client that is related to the task, just forward the email to &quot;$task_id@server.com&quot; and it will be stored along with the task.
    Highly useful :).
  </p>

  <p>
    Obviously you could have implementations for:
  </p>

  <ul>
	<li>
	  <p>
        forums_forum_id: Start a new topic
      </p>
	</li>
	<li>
	  <p>
        forums_message_id: Reply to an existing topic
      </p>
	</li>
	<li>
	  <p>
        group_id: Send an e-mail to all group members
      </p>
	</li>
	<li>
	  <p>
        pm_project_id: add a comment to a project
      </p>
	</li>
	<li>
	  <p>
        pm_task_id: add a comment to a task and store the files in the projects folder (done)
      </p>
	</li>
  </ul>

  <p>
    
  </p>

  <p>
    Once the e-mail is dealt with in an object oriented approach we are either done with the message (an object_id was found in the to address) or we need to process it further.
  </p>
<pre>
    ad_proc -public -callback acs_mail_lite::incoming_email {
    -array:required
    -package_id
    } {
    }
  

</pre>
<pre>
    array set email {}
    
    parse_email -file $msg -array email
    set email(to) [parse_email_address -email $email(to)]
    set email(from) [parse_email_address -email $email(from)]

    # We execute all callbacks now
    callback acs_mail_lite::incoming_email -array email
  

</pre>

  <p>

    For this a general callback should exist which can deal with every leftover e-mail and each implementation will check if it wants to deal with this e-mail.
    How is this check going to happen? As an example, a package could have a prefix, as is the case with bounce e-mails as handled in acs_mail_lite::parse_bounce_address (see below):
</p>

<pre>
    ad_proc -public -callback acs_mail_lite::incoming_email -impl acs-mail-lite {
    -array:required
    -package_id:required
    } {
    @param array        An array with all headers, files and bodies. To access the array you need to use upvar.
    @param package_id   The package instance that registered the prefix
    @return             nothing
    @error
    } {
    upvar $array email

    set to [acs_mail_lite::parse_email_address -email $email(to)]
    ns_log Debug &quot;acs_mail_lite::incoming_email -impl acs-mail-lite called. Recipient $to&quot;

    util_unlist [acs_mail_lite::parse_bounce_address -bounce_address $to] user_id package_id signature
    
    # If no user_id found or signature invalid, ignore message
    # Here we decide not to deal with the message anymore



    if {[empty_string_p $user_id]} {
    if {[empty_string_p $user_id]} {
    ns_log Debug &quot;acs_mail_lite::incoming_email impl acs-mail-lite: No equivalent user found for $to&quot;
    } else {
    ns_log Debug &quot;acs_mail_lite::incoming_email impl acs-mail-lite: Invalid mail signature $signature&quot;
    }
    } else {
    ns_log Debug &quot;acs_mail_lite::incoming_email impl acs-mail-lite: Bounce checking $to, $user_id&quot;
    
    if { ![acs_mail_lite::bouncing_user_p -user_id $user_id] } {
    ns_log Debug &quot;acs_mail_lite::incoming_email impl acs-mail-lite: Bouncing email from user $user_id&quot;
    # record the bounce in the database
    db_dml record_bounce {}
    
    if {![db_resultrows]} {
    db_dml insert_bounce {}
    }
    }
    }
    }
    

  

</pre>

  <p>
    Alternatively we could just check the whole to address for other things, e.g. if the to address belongs to a group (party).
</p>

<pre>
    ad_proc -public -callback acs_mail_lite::incoming_email -impl contacts_group_mail {
    -array:required
    {-package_id &quot;&quot;}
    } {
    Implementation of group support for incoming emails
    
    If the to address matches an address stored with a group then send out the email to all group members

    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
    @creation-date 2005-12-18

    @param array        An array with all headers, files and bodies. To access the array you need to use upvar.
    @return             nothing
    @error
    } {

    # get a reference to the email array
    upvar $array email

    # Now run the simplest mailing list of all
    set to_party_id [party::get_by_email -email $email(to)]
    
    if {[db_string group_p &quot;select 1 from groups where group_id = :to_party_id&quot; -default 0]} {
    # make the bodies an array
    template::util::list_of_lists_to_array $email(bodies) email_body
    
    if {[exists_and_not_null email_body(text/html)]} {
    set body $email_body(text/html)
    } else {
    set body $email_body(text/plain)
    }
    
    acs_mail_lite::complex_send \
    -from_addr [lindex $email(from) 0] \
    -to_party_ids [group::get_members -group_id $to_party_id] \
    -subject $email(subject) \
    -body $body \
    -single_email \
    -send_immediately

    }
    } 
  

</pre>

  <p>
    Or check if the to address follows a certain format.
</p>

<pre>
    ad_proc -public -callback acs_mail_lite::incoming_email -impl contacts_mail_through {
    -array:required
    {-package_id &quot;&quot;}
    } {
    Implementation of mail through support for incoming emails
    
    You can send an e-amil through the system by sending it to user#target.com@yoursite.com
    The email will be send from your system and if mail tracking is installed the e-mail will be tracked.

    This allows you to go in direct communication with a customer using you standard e-mail program instead of having to go to the website.

    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
    @creation-date 2005-12-18
    
    @param array        An array with all headers, files and bodies. To access the array you need to use upvar.
    @return             nothing
    @error
    } {
    # get a reference to the email array
    upvar $array email

    # Take a look if the email contains an email with a &quot;#&quot;
    set pot_email [lindex [split $email(to) &quot;@&quot;] 0]
    if {[string last &quot;#&quot; $pot_email] &gt; -1} {
    ....
    }
    }

</pre>

  <p>
    Alternatives to this are:
  </p>

  <ul>
	<li>${component_name}-bugs@openacs.org (where component_name could be openacs or dotlrn or contacts or whatever), to store a new bug in bug-tracker.</li>
	<li>username@openacs.org (to do mail-through using the user name, which allows you to hide the actual e-mail of the user whom you are contacting).</li>
  </ul>

  <h2>Cleanup</h2>

  <p>
Once all callbacks have been fired off,  e-mails need to be deleted from the Maildir directory and files which have been extracted need to be deleted as well from the /tmp directory. 
</p>
