
<property name="context">{/doc/acs-templating {ACS Templating}} {Templating System User Guide: Creating and Populating
Forms}</property>
<property name="doc(title)">Templating System User Guide: Creating and Populating
Forms</property>
<master>
<h2>Creating and Populating Forms</h2>
<a href="..">Templating System</a>
 : <a href="../developer-guide">Developer Guide</a>
 : User Guide
<p>This document outlines the steps necessary to build a dynamic
form in Tcl code.</p>
<p>
<strong>Important Note:</strong> The <kbd><a href="http://openacs.org//api-doc/proc-view?proc=ad%5fform">ad_form</a></kbd>
function has been written to be a more consistent, easier way to
create and manage dynamic forms. Behind the scenes it uses the
templating system&#39;s form builder, but it hides much of its
complexity. You should definitely look at it and at the pages that
use it in the survey package.</p>
<h3>Create a form</h3>
<p>Use the <kbd>form create</kbd> command to initialize a form:</p>
<pre>
form create add_user
</pre>
<p>See the <a href="../api/form">form API</a> for optional
parameters to this command.</p>
<h3>Add elements</h3>
<p>Once the form is created, use the <kbd>element create</kbd>
command to add elements to it:</p>
<pre>
element create add_user first_name -datatype text \ 
                                   -label "First Name" \
                                   -html { size 30 }
</pre>
<p>In auto-generated forms, elements appear in the order they were
created. See the <a href="../api/element">element API</a> for
optional parameters to this command.</p>
<h3>Set values</h3>
<p>Self-validating forms should check whether a request or
submission is currently being processed. If a request is being
processed, then form elements may need to be initialized with their
appropriate values.</p>
<pre>
if { [template::form is_request add_user] } {

  set db [ns_db gethandle]

  set query "select ad_template_sample_users_seq.nextval from dual"
  template::query user_id onevalue $query -db $db

  ns_db releasehandle $db

  template::element set_properties add_user user_id -value $user_id
}
</pre>
<p>This may also be done using the <kbd>value</kbd> option to
<kbd>element create</kbd>. In this case the value is set separately
to avoid the additional database query during a submission.</p>
<hr>
<!-- <a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a> -->