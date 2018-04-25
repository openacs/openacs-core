
<property name="context">{/doc/acs-templating {ACS Templating}} {Templating System API: Form}</property>
<property name="doc(title)">Templating System API: Form</property>
<master>
<h2>Form</h2>
<strong>
<a href="../index">Templating System</a> : API
Reference</strong>
<h3>Summary</h3>
<p>Building dynamic forms with automated validation.</p>
<h3>Methods</h3>
<pre>
template::form create <em>name \
                      -html { attribute value attribute value }</em>
</pre>
<p>Initialize data structures for a dynamic form. This procedure
must be called before adding elements to the form.</p>
<ul><li>Additional attributes to include in the HTML form tag may be
specified with the <kbd>html</kbd> option.</li></ul>
<pre>template::form is_request <em>name</em>
</pre>
<p>Boolean procedure for determining whether a submission is in
progress. If this procedure returns true, then an initial request
for the form is underway. The code for insert or add forms may thus
query for primary key value(s), and the code for update forms may
query for current data and set the value(s) of form elements
accordingly.</p>
<pre>template::form is_valid <em>name</em>
</pre>
<p>Boolean procedure that returns true if a submission is in
progress <em>and</em> the submission is valid. Database or any
other transactions based on the form submission should only take
place after this procedure has been checked.</p>
<h3>Example</h3>
<pre></pre>
<h3>Note(s)</h3>
<hr>
<!-- <a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a> -->