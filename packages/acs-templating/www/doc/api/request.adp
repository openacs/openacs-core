
<property name="context">{/doc/acs-templating {Templating}} {Templating System API: Page Request}</property>
<property name="doc(title)">Templating System API: Page Request</property>
<master>
<h2>Page Request</h2>
<h3>Summary</h3>
<p>Transform, validate and report errors in the query parameters
associated with a page request.</p>
<p>This API is an alternative to <code>ad_page_contract</code>
which should usually be preferred if you have ACS installed.</p>
<h3>Methods</h3>
<pre>
template::request create
</pre>
<p>Initialize the data structure to store request parameters.
Should be called at the start of any page that takes request
parameters.</p>
<pre>
template::request set_param <em>name 
                            -datatype datatype
                            -multiple
                            -optional
                            -validate { { expression } { message } }</em>
</pre>
<p>Validates request parameter values and then sets a local
variable. Values are transformed if a transformation procedure
exists for the specified datatype (i.e. the components of a
<tt>date</tt> are assembled into a single structure).</p>
<ul>
<li>Options for <tt>datatype</tt> are the same as for form
elements.</li><li>The <tt>multiple</tt> switch indicates that more than one value
may be submitted. The local variable set by the procedure will be a
list.</li><li>The <tt>optional</tt> switch indicates that the parameter value
may be empty or missing. A value is assumed to be required if this
switch is not specified.</li><li>The <tt>validate</tt> switch may be used to perform simple
custom validation of each parameter value. <tt>expression</tt> must
be a block of arbitrary Tcl code that evaluates to 1 (valid) or 0
(not valid). The variable <tt>$value</tt> may be used in the
expression to reference the parameter value. <tt>message</tt> is
simply a string containing a message to return to the user if
validation fails. The variables <tt>$value</tt> and <tt>$label</tt>
may be used in the message to reference the parameter value and
label (or name if no label is supplied).</li>
</ul>
<pre>
template::request get_param <em>name</em>
</pre>
<p>Returns the value (or values if the <tt>multiple</tt> is used)
of the named parameter.</p>
<pre>
template::request is_valid <em>error_url</em>
</pre>
<p>Boolean procedure for determining whether any validation errors
occurred while setting request parameters.</p>
<ul><li>
<tt>error_url</tt> is the location of the template to use for
reporting request errors. The default is
<tt>/ats/templates/messages/request-error</tt> if no URL is
specified. To report request errors in the template of the page
itself, use <tt>self</tt> for the URL.</li></ul>
<h3>Example</h3>
<pre>
request create

request set_param state_abbrev -datatype keyword -validate {
  { regexp {CA|HI|NV} $value } 
  { Invalid state abbreviation $value. }
}

request set_param start_date -datatype date
request set_param user_id -datatype integer -multiple

if { ! [request is_valid "/mytemplates/request-error"] } { return }

...
</pre>
<h3>Note(s)</h3>
<ul>
<li>Error reporting templates may reference the
<tt>requesterror</tt> array to access error messages for each
parameter.</li><li>The request API provides a simple mechanism for processing
request parameters. It is not intended as a replacement to
<tt>ad_page_contract</tt> for sites built on the ArsDigita
Community System.</li>
</ul>
<hr>
<a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a>
