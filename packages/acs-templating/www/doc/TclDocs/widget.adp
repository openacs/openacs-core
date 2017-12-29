
<property name="context">{/doc/acs-templating {ACS Templating}} {}</property>
<property name="doc(title)"></property>
<master>
<h2>Namespace widget</h2>
<blockquote>Procedures for generating and processing metadata form
widgets, editing attribute widgets</blockquote>
<h3>Method Summary</h3>

Listing of public methods:<br>
<blockquote>
<a href="#widget::param_element_create">widget::param_element_create</a><br>
</blockquote>
<h3>Method Detail</h3>
<p align="right">
<font color="red">*</font> indicates required</p>
<strong>Public Methods:</strong>
<br>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="widget::param_element_create" id="widget::param_element_create"><font size="+1" weight="bold">widget::param_element_create</font></a></td></tr><tr><td>
<blockquote>Dipatches subprocs to generate the form elements for
setting an attribute widget param</blockquote><dl><dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>form</code><font color="red">*</font>
</td><td align="left">Name of the form in which to generate the form
elements</td>
</tr><tr>
<td align="right">
<code>param</code><font color="red">*</font>
</td><td align="left">Name of the form widget param for which to
generate a form element</td>
</tr><tr>
<td align="right">
<code>order</code><font color="red">*</font>
</td><td align="left">The order that the param form widget will appear
in the form</td>
</tr><tr>
<td align="right">
<code>param_id</code><font color="red">*</font>
</td><td align="left">The ID of the form widget param</td>
</tr><tr>
<td align="right">
<code>default</code><font color="red">*</font>
</td><td align="left">The default value of the form widget param</td>
</tr><tr>
<td align="right">
<code>is_required</code><font color="red">*</font>
</td><td align="left">Flag indicating whether the form widget param is
optional or required</td>
</tr><tr>
<td align="right">
<code>param_source</code><font color="red">*</font>
</td><td align="left">The default source of the value of the form widget
param. One of literal, eval, query</td>
</tr>
</table>
</dd></dl>
</td></tr>
</table>
<p>
<strong>Private Methods</strong>:<br>
</p>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF">
<a name="widget::create_options_param" id="widget::create_options_param"><font size="+1" weight="bold">widget::create_options_param</font></a><br><small><em>  by Michael Pih</em></small>
</td></tr><tr><td>
<blockquote>Create the options param form widget for adding/editing
metadata form widgets</blockquote><dl><dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>form</code><font color="red">*</font>
</td><td align="left">The name of the form</td>
</tr><tr>
<td align="right">
<code>order</code><font color="red">*</font>
</td><td align="left">The order of placement of the form widget within
the form</td>
</tr><tr>
<td align="right">
<code>default</code><font color="red">*</font>
</td><td align="left">The default value of the form widget param
value</td>
</tr><tr>
<td align="right">
<code>is_required</code><font color="red">*</font>
</td><td align="left">A flag indicating whether the form widget param
value is mandatory</td>
</tr><tr>
<td align="right">
<code>param_source</code><font color="red">*</font>
</td><td align="left">The default param source for the form widget param
value (literal, query, eval)</td>
</tr>
</table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF">
<a name="widget::create_param_source" id="widget::create_param_source"><font size="+1" weight="bold">widget::create_param_source</font></a><br><small><em>  by Michael Pih</em></small>
</td></tr><tr><td>
<blockquote>Create default param_source form widget for
adding/editing metadata form widgets</blockquote><dl><dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>form</code><font color="red">*</font>
</td><td align="left"></td>
</tr><tr>
<td align="right">
<code>order</code><font color="red">*</font>
</td><td align="left">The order of placement of the form widget within
the form</td>
</tr><tr>
<td align="right">
<code>param_source</code><font color="red">*</font>
</td><td align="left">The default param source of the metadata widget
(literal, query, eval)</td>
</tr>
</table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF">
<a name="widget::create_param_type" id="widget::create_param_type"><font size="+1" weight="bold">widget::create_param_type</font></a><br><small><em>  by Michael Pih</em></small>
</td></tr><tr><td>
<blockquote>Create default param_type form widget for
adding/editing metadata form widgets</blockquote><dl><dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>form</code><font color="red">*</font>
</td><td align="left">The name of the form</td>
</tr><tr>
<td align="right">
<code>order</code><font color="red">*</font>
</td><td align="left">The order of placement of the form widget within
the form</td>
</tr>
</table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF">
<a name="widget::create_param_value" id="widget::create_param_value"><font size="+1" weight="bold">widget::create_param_value</font></a><br><small><em>  by Michael Pih</em></small>
</td></tr><tr><td>
<blockquote>Create default param_value form widget for
adding/editing metadata form widgets</blockquote><dl><dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>form</code><font color="red">*</font>
</td><td align="left">The name of the form</td>
</tr><tr>
<td align="right">
<code>order</code><font color="red">*</font>
</td><td align="left">The order of placement of the form widget within
the form</td>
</tr><tr>
<td align="right">
<code>is_required</code><font color="red">*</font>
</td><td align="left">A flag indicating whether the value of the form
widget param is mandatory</td>
</tr>
</table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF">
<a name="widget::create_text_param" id="widget::create_text_param"><font size="+1" weight="bold">widget::create_text_param</font></a><br><small><em>  by Michael Pih</em></small>
</td></tr><tr><td>
<blockquote>Create default text param form widget for
adding/editing metadata form widgets</blockquote><dl><dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>form</code><font color="red">*</font>
</td><td align="left">The name of the form</td>
</tr><tr>
<td align="right">
<code>default</code><font color="red">*</font>
</td><td align="left">The default value for the form widget param
value</td>
</tr><tr>
<td align="right">
<code>is_required</code><font color="red">*</font>
</td><td align="left">A flag indicating whether the value of the form
widget param is mandatory</td>
</tr><tr>
<td align="right">
<code>param_source</code><font color="red">*</font>
</td><td align="left">The default param source for the form widget param
value (literal, query, eval)</td>
</tr>
</table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF">
<a name="widget::create_values_param" id="widget::create_values_param"><font size="+1" weight="bold">widget::create_values_param</font></a><br><small><em>  by Michael Pih</em></small>
</td></tr><tr><td>
<blockquote>Create the values param form widget for adding/editing
metadata widgets</blockquote><dl><dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>form</code><font color="red">*</font>
</td><td align="left">The name of the form</td>
</tr><tr>
<td align="right">
<code>order</code><font color="red">*</font>
</td><td align="left">The order of placement of the form widget within
the metadata form</td>
</tr><tr>
<td align="right">
<code>default</code><font color="red">*</font>
</td><td align="left">The default value of the form widget param
value</td>
</tr><tr>
<td align="right">
<code>is_required</code><font color="red">*</font>
</td><td align="left">A flag indicating whether the form widget param
value is mandatory</td>
</tr><tr>
<td align="right">
<code>param_source</code><font color="red">*</font>
</td><td align="left">The default param_source for the form widget param
value (literal, query, eval)</td>
</tr>
</table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF">
<a name="widget::process_param" id="widget::process_param"><font size="+1" weight="bold">widget::process_param</font></a><br><small><em>  by Michael Pih</em></small>
</td></tr><tr><td>
<blockquote>Edits a metadata form widget parameter from the
form</blockquote><dl><dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>db</code><font color="red">*</font>
</td><td align="left">A database handle</td>
</tr><tr>
<td align="right">
<code>form</code><font color="red">*</font>
</td><td align="left">The name of the form</td>
</tr><tr>
<td align="right">
<code>order</code><font color="red">*</font>
</td><td align="left">The order of placement of the param form widgets
within the form</td>
</tr><tr>
<td align="right">
<code>content_type</code><font color="red">*</font>
</td><td align="left">The content type to which the attribute
belongs</td>
</tr><tr>
<td align="right">
<code>attribute_name</code><font color="red">*</font>
</td><td align="left">The name of the attribute</td>
</tr>
</table>
</dd></dl>
</td></tr>
</table>
<p align="right">
<font color="red">*</font> indicates required</p>
