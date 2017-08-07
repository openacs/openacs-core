
<property name="context">{/doc/acs-templating {ACS Templating}} {Templating System Widget Reference: Input}</property>
<property name="doc(title)">Templating System Widget Reference: Input</property>
<master>
<h2>The Input Widgets</h2>
<strong>
<a href="../index">Templating System</a> : <a href="index">Widget Reference</a> : Input</strong>
<h3>Overview</h3>
<p>These widgets provide a variety of HTML controls, all of which
are based on <code>&lt;input type="..."&gt;</code>. In
particular, the hidden, text, radio and checkbox widgets are
currently implemented; their use is demonstrated in the <a href="../demo/index">acs-templating demo</a>.</p>
<h3>The Hidden Widget</h3>
<p>This is simply an <code>&lt;input
type="hidden"&gt;</code> widget, which is used for
passing pre-set variables along with the form.</p>
<h3>The Text Widget</h3>
<p>This widget allows the user to enter one line of text. It is
completely identical to the &lt;input type="text"&gt;.
The <code>-html</code> parameter can be used to set its properties
(such as <code>size</code>, <code>maxlength</code>, etc.), as
described in the general widgets <a href="../index">reference</a>. The value of this widget is the text
string.</p>
<h3>The Radio Group Widget</h3>
<p>This widget actually represents a group of radio buttons, at
most one of which can be selected at any given time. The widget has
one required parameter,
<code>-option</code> <em>option_list</em>, which specifies the
radio buttons to display. The <em>option_list</em> is a list of
label-value pairs. For example,</p>
<blockquote><pre>
template::element create test_form cost \
 -label "Car Cost" -datatype number <strong>-widget radio</strong> \
 -options { {Cheap 1000} {Medium 50000} {Expensive 999999} }
</pre></blockquote>

will create a radio button group with 3 options: "Cheap",
whose value is 1000, "Medium", whose value is 50000, and
"Expensive", whose value is 999999. The value of the
entire widget is either the empty string (if the user did not
select any of the radio buttons), or a the value of the currently
selected radio button. For instance, if the user selects
"Medium" in the example above, the value of
<code>cost</code>
 will be <code>50000</code>
.
<p>The default form template renders the Radio Group widget as a
column of radio buttons. Since the Radio Group can consist of many
HTML controls, the usual <a href="/doc/acs-templating/tagref/formwidget">formwidget</a> tag
cannot be used to position the widget; instead, the <a href="/doc/acs-templating/tagref/formgroup">formgroup</a> tag must
be used.</p>
<h3>The Checkbox Group Widget</h3>
<p>This widget is identical in use to the Radio Group widget, but
instead of radio buttons it generates a group of checkboxes, any
number of which can be checked at any given time. The
<code>values</code> (plural) property of the corresponding element
contains a list of all the checked values; the <code>value</code>
(singular) property contains the first element in the list.</p>
<hr>
<!-- <a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a> -->