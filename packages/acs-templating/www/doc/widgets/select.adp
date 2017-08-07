
<property name="context">{/doc/acs-templating {ACS Templating}} {Templating System Widget Reference: Select}</property>
<property name="doc(title)">Templating System Widget Reference: Select</property>
<master>
<h2>The Input Widgets</h2>
<strong>
<a href="../index">Templating System</a> : <a href="index">Widget Reference</a> : Select</strong>
<h3>Overview</h3>
<p>These widgets provide the single-selection and
multiple-selection HTML controls; their usage is demonstrated in
the <a href="../demo/index">acs-templating demo</a>.</p>
<h3>The Select Widget</h3>
<p>This widget creates a list of choices, only one of which may be
selected at any given time, using the HTML
<code>&lt;select&gt;</code> control. Similarly to the <a href="input">button group</a> widgets, the Select widget has one
required parameter, <code>-option</code> <em>option_list</em>,
which specifies all the possible choices. The <em>option_list</em>
is a list of label-value pairs. For example,</p>
<blockquote><pre>
template::element create pizza_form topping \
 -label "Pizza Topping" -datatype keyword <strong>-widget select</strong> \
 -options { 
    {Pepperoni pepperoni} 
    {Sausage sausage} 
    {{Canadian Bacon} cbacon} 
  }
</pre></blockquote>

will create a widget with 3 choices: "Pepperoni",
"Sausage" and "Canadian Bacon". By default, the
widget looks like a drop-down "picklist", however, it can
be forced to look like a scrollable vertical list of <em>n</em>

elements by using the
<code>-html { size <em>n</em> }</code>

parameter.
<p>The value of the Select widget is the value of the currently
selected choice. If no choice is selected, the value will be the
empty string. However, if the widget happens to look like a
picklist, most Web browsers automatically select the first option
on the list. This behavior may be changed by supplying an extra
"null" option. For example, the options for the pizza
topic selection widget shown above could be changed to</p>
<blockquote><pre>
template::element create pizza_form topping \
 -label "Pizza Topping" -datatype keyword -widget select \
 -options { 
    <strong>{{No Topping} {}}</strong>
    {Pepperoni pepperoni} 
    {Sausage sausage} 
    {{Canadian Bacon} cbacon} 
  }
</pre></blockquote>
<h3>The Multiselect Widget</h3>
<p>This widget is similar to the Select widget, but it allows
multiple values to be selected. Because of this, the Multiselect
widget cannot look like a picklist. By default, the widget looks
like a scrollable list of items, which grows up to 8 items in size
(in other words, up to 8 items will be shown without the need to
scroll). This size can be overwritten with the
<code>-html { size <em>n</em> }</code>
parameter.</p>
<p>The <code>values</code> (plural) property of the corresponding
element contains a list of all the selected choices; the
<code>value</code> (singular) property contains the first selected
choice.</p>
<hr>
<!-- <a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a> -->