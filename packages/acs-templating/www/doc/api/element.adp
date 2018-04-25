
<property name="context">{/doc/acs-templating {ACS Templating}} {Templating System API: Form Element}</property>
<property name="doc(title)">Templating System API: Form Element</property>
<master>
<h2>Form Element</h2>
<strong>
<a href="../index">Templating System</a> : API
Reference</strong>
<h3>Summary</h3>
<h3>Methods</h3>
<pre>
template::element create <em>form_name element_name \
                        -widget widget \
                        -datatype datatype \
                        -html { attribute value attribute value ... } \
                        -validate { \
                          name { expression } { message } \
                          name { expression } { message } \
                          ... } \
                        -options { { label value } { label value } ... } \
                        -maxlength maxlength \
                        -value value \
                        -values { value value ... }
                        </em>
</pre>
<p>Append a new element to the specified form.</p>
<ul>
<li>The <kbd>html</kbd> switch may be used to include additional
HTML attributes in the <kbd>input</kbd>, <kbd>select</kbd>, or
<kbd>textarea</kbd> tag used to ultimately render the element.</li><li>The <kbd>validate</kbd> switch may be used to perform simple
custom validation of each element value. <kbd>type</kbd> is a
keyword for the type of validation being performed. This same
keyword must be referenced by the <kbd><a href="../tagref/formerror">formerror</a></kbd> tag to customize the
presentation and layout of the error message for this validation
step. <kbd>expression</kbd> must be a block of arbitrary Tcl code
that evaluates to 1 (valid) or 0 (not valid). The variable
<kbd>$value</kbd> may be used in the expression to reference the
element value. <kbd>message</kbd> is simply a string containing a
message to return to the user if validation fails. The variables
<kbd>$value</kbd> and <kbd>$label</kbd> may be used in the message
to reference the parameter value and label (or name if no label is
supplied).</li>
</ul>
<pre>
template::element set_properties <em>form_name element_name
                                 </em>
</pre>
<pre>
template::element get_value <em>form_name element_name</em>
</pre>
<h3>Example</h3>
<pre></pre>
<pre>
template::element get_values <em>form_name element_name</em>
</pre>
<h3>Note(s)</h3>
<hr>
<!-- <a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a> -->