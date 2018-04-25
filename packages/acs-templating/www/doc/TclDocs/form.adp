
<property name="context">{/doc/acs-templating {ACS Templating}} {}</property>
<property name="doc(title)"></property>
<master>
<h2>Namespace form</h2>
<blockquote>Commands for managing dynamic templated
forms.</blockquote>
<h3>Method Summary</h3>

Listing of public methods:<br>
<blockquote>
<a href="#"></a><br><a href="#"></a><br><a href="#"></a><br><a href="#"></a><br><a href="#"></a><br><a href="#"></a><br><a href="#"></a><br><a href="#"></a><br><a href="#"></a><br><a href="#"></a><br><a href="#"></a><br>
</blockquote>
<h3>Method Detail</h3>
<p align="right">
<font color="red">*</font> indicates required</p>
<strong>Public Methods:</strong>
<br>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td>
<blockquote>Convenience procedure to set individual values of a
form (useful for simple update forms). Typical usage is to query a
onerow data source from database and pass the resulting array
reference to set_values for setting default values in an update
form.</blockquote><dl><dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>id</code><font color="red">*</font>
</td><td align="left">The form identifier</td>
</tr><tr>
<td align="right">
<code>array_ref</code><font color="red">*</font>
</td><td align="left">The name of a local array variable whose keys
correspond to element identifiers in the form</td>
</tr>
</table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td>
<blockquote>Determine whether a form exists by checking for its
data structures.</blockquote><dl>
<dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>id</code><font color="red">*</font>
</td><td align="left">The ID of an ATS form object.</td>
</tr></table>
</dd><dt><strong>Returns:</strong></dt><dd>1 if a form with the specified ID exists. 0 if it does
not.</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td>
<blockquote>Generates hidden input tags for all values in a form
submission. Typically used to create a confirmation page following
an initial submission.</blockquote><dl>
<dt><strong>Returns:</strong></dt><dd>A string containing hidden input tags for inclusion in a
form.</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td>
<blockquote>Initialize the data structures for a form.</blockquote><dl>
<dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>id</code><font color="red">*</font>
</td><td align="left">A keyword identifier for the form, such as {
add_user} or { edit_item} . The ID must be unique in the context of
a single page.</td>
</tr></table>
</dd><dt><strong>Options:</strong></dt><dd><table>
<tr>
<td align="right"><code>method</code></td><td align="left">The standard METHOD attribute to specify in the
HTML FORM tag at the beginning of the rendered form. Defaults to
POST.</td>
</tr><tr>
<td align="right"><code>html</code></td><td align="left">A list of additional name-value attribute pairs to
include in the HTML FORM tag at the beginning of the rendered form.
Common attributes include JavaScript event handlers and multipart
form encoding. For example, { -html { enctype multipart/form-data
onSubmit validate() } }</td>
</tr><tr>
<td align="right"><code>elements</code></td><td align="left">A block of element specifications.</td>
</tr>
</table></dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td>
<blockquote>Return a list which represents the result of getting
combined values from multiple form elements</blockquote><dl><dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>id</code><font color="red">*</font>
</td><td align="left">The form identifier</td>
</tr><tr>
<td align="right">
<code>args</code><font color="red">*</font>
</td><td align="left">A list of element identifiers. Each identifier may
be a regexp. For example, form get_combined_values { foo.*} will
combine the values of all elements starting with { foo}</td>
</tr><tr>
<td align="right">
<code>return</code><font color="red">*</font>
</td><td align="left">The combined list of values</td>
</tr>
</table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td>
<blockquote>Return the number of elements in a form</blockquote><dl><dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>id</code><font color="red">*</font>
</td><td align="left">The form identifier</td>
</tr></table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td>
<blockquote>Return true if a submission in progress. The submission
may or may not be valid.</blockquote><dl>
<dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>id</code><font color="red">*</font>
</td><td align="left">The form identifier</td>
</tr></table>
</dd><dt><strong>Returns:</strong></dt><dd>1 if true or 0 if false</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td>
<blockquote>Return true if preparing a form for an initial request
(as opposed to repreparing a form that is returned to the user due
to validation problems). This command is used to conditionally set
default values for form elements.</blockquote><dl>
<dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>id</code><font color="red">*</font>
</td><td align="left">The form identifier</td>
</tr></table>
</dd><dt><strong>Returns:</strong></dt><dd>1 if true or 0 if false</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td>
<blockquote>Return true if submission in progress and submission
was valid. Typically used to conditionally execute DML and redirect
to the next page, as opposed to returning the form back to the user
to report validation errors.</blockquote><dl>
<dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>id</code><font color="red">*</font>
</td><td align="left">The form identifier</td>
</tr></table>
</dd><dt><strong>Returns:</strong></dt><dd>1 if true or 0 if false</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td>
<blockquote>Set local variables for form variables (assume they are
all single values). Typically used when processing the form
submission to prepare for DML or other type of
transaction.</blockquote><dl><dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>id</code><font color="red">*</font>
</td><td align="left">The form identifier</td>
</tr><tr>
<td align="right">
<code>args</code><font color="red">*</font>
</td><td align="left">A list of element identifiers. If the list is
empty, retrieve all form elements</td>
</tr>
</table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td>
<blockquote>Set the name of the current section of the form. A form
may be divided into any number of sections for layout purposes.
Elements are tagged with the current section name as they are added
to the form. A form style template may insert a divider in the form
whenever the section name changes.</blockquote><dl><dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>id</code><font color="red">*</font>
</td><td align="left">The form identifier.</td>
</tr><tr>
<td align="right">
<code>section</code><font color="red">*</font>
</td><td align="left">The name of the current section.</td>
</tr>
</table>
</dd></dl>
</td></tr>
</table>
<p>
<strong>Private Methods</strong>:<br>
</p>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td>
<blockquote>Auto-generate the template for a form</blockquote><dl>
<dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>id</code><font color="red">*</font>
</td><td align="left">The form identifier</td>
</tr><tr>
<td align="right">
<code>style</code><font color="red">*</font>
</td><td align="left">The style template to use when generating the
form. Form style templates must be placed in the forms subdirectory
of the ATS resources directory.</td>
</tr>
</table>
</dd><dt><strong>Returns:</strong></dt><dd>A string containing a template for the body of the form.</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td><blockquote>Helper procedure used to access the basic data
structures of a form object. Called by several of the form
commands.</blockquote></td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td>
<blockquote>Iterates over all declared elements, checking for
hidden widgets and rendering those that have not been rendered yet.
Called after rendering a custom form template as a debugging
aid.</blockquote><dl><dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>id</code><font color="red">*</font>
</td><td align="left">The form identifier</td>
</tr></table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td>
<blockquote>Render the HTML FORM tag along with a hidden element
that identifies the form object.</blockquote><dl>
<dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>id</code><font color="red">*</font>
</td><td align="left">The form identifier</td>
</tr><tr>
<td align="right">
<code>tag_attributes</code><font color="red">*</font>
</td><td align="left">A name-value list of special attributes to add to
the FORM tag, such as JavaScript event handlers.</td>
</tr>
</table>
</dd><dt><strong>Returns:</strong></dt><dd>A string containing the rendered tags.</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td>
<blockquote>Render the finished HTML output for a dynamic
form.</blockquote><dl>
<dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>id</code><font color="red">*</font>
</td><td align="left">The form identifier</td>
</tr><tr>
<td align="right">
<code>style</code><font color="red">*</font>
</td><td align="left">The style template to use when generating the
form. Form style templates must be placed in the forms subdirectory
of the ATS resources directory.</td>
</tr>
</table>
</dd><dt><strong>Returns:</strong></dt><dd>A string containing the HTML for the body of the form.</dd>
</dl>
</td></tr>
</table>
<p align="right">
<font color="red">*</font> indicates required</p>
