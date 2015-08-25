
<property name="context">{/doc/acs-templating {Templating}} {Templating System User Guide: Integrating Forms into a
Wizard}</property>
<property name="doc(title)">Templating System User Guide: Integrating Forms into a
Wizard</property>
<master>
<h2>Integrating Forms into a Wizard</h2>
<p>This document outlines the steps necessary to build a dynamic
form wizard in Tcl code.</p>
<a href="wizard-procs-doc">Updated documentation of
wizards</a>
<h3>Create a wizard</h3>
<p>Use the <tt>wizard create</tt> command to initialize a wizard,
declaring any wizard state variables in the <tt>-params</tt>
option:</p>
<pre>
wizard create make_sandwich -params { sandwich_id }
</pre>
<p>See the <a href="/api-doc/proc-view?proc=template%3a%3awizard%3a%3acreate">wizard
API</a> for optional parameters to this command.</p>
<h3>Add steps</h3>
<p>Once the wizard is created, use the <tt>wizard create</tt>
command to add steps to it:</p>
<pre>
wizard add make_sandwich -label "Add the lettuce" -url "add-lettuce"
</pre>
<p>In auto-generated wizards, the wizard steps appear in the order
they were created. See the <a href="/api-doc/proc-view?proc=template%3a%3awizard%3a%3acreate">wizard
API</a> for optional parameters to this command. Alternatively,
wizard steps can be created in the <tt>wizard create</tt> statement
with the <tt>-steps</tt> option:</p>
<pre>
wizard create make_sandwich -action "eat-sandwich.acs?sandwich_id=$sandwich_id" -params { 
  sandwich_id 
} -steps { 
  1 -label "Add Meat"    -url "add-meat" -repeat
  2 -label "Add Lettuce" -url "add-lettuce"
  3 -label "Add Cheese"  -url "add-cheese" -repeat
}
</pre>
<h3>Setting wizard state variables</h3>
<p>Most likely, a wizard will store one or more state variables
using the <tt>-params</tt> option in the <tt>wizard create</tt>
statement. At any point in the wizard process, a state variable's
value can be updated using the <tt>wizard set_param</tt>
command.</p>
<pre>
# check to see if a sandwich_id has been passed in by the wizard
request set_param sandwich_id -datatype integer -optional

# if not, then set the sandwich_id
if { [template::util::is_nil sandwich_id] } {

  set db [ns_db gethandle]
  query sandwich_id onevalue "select sandwich_id_seq.nextval from dual" -db $db
  ns_db releasehandle $db

  wizard set_param sandwich_id $sandwich_id
}
</pre>
<h3>Integrating forms into the wizard</h3>

Integrating forms into the wizard involves augmenting the standard
ATS form by:
<ul>
<li>Adding wizard submit buttons to the form in place of the
standard form submit button:
<p>In the .tcl file:</p><pre>
if { [wizard exists] } {
  wizard submit form_name -buttons { 
    { previous "Back" } repeat { next "Continue" } { finish Save } 
  }
} else {
  element create form_name submit -datatype keyword -widget submit
}
</pre><p>In the .adp file:</p><pre>
&lt;formtemplate id=\@form_name\@ style=wizard&gt;
</pre>
</li><li>Advancing the wizard with the <tt>wizard forward</tt> command.
The page the wizard forwards to depends on which wizard submit
button was pressed (next, repeat, previous, finish):
<pre>
if { [wizard exists] } {
  # go to the next wizard step
  wizard forward
} else {
  template::forward "http://cms.arsdigita.com"
}
</pre>
</li>
</ul>
<hr>
<a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a>
