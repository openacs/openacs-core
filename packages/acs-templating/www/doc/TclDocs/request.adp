
<property name="context">{/doc/acs-templating {ACS Templating}} {}</property>
<property name="doc(title)"></property>
<master>
<h2>Namespace request</h2>
<blockquote>The request commands provide a mechanism for managing
the query parameters to a page. The request is simply a special
instance of a form object, and is useful for the frequent cases
when data must be passed from page to page to determine display or
page flow, rather than perform a transaction based on user input
via a form.</blockquote>
<p>Also see:</p>
<dl>
<dt>form</dt><dd><a href="">element</a></dd>
</dl>
<h3>Method Summary</h3>

Listing of public methods:<br>
<blockquote>
<a href="#"></a><br><a href="#"></a><br><a href="#"></a><br><a href="#"></a><br><a href="#"></a><br>
</blockquote>
<h3>Method Detail</h3>
<p align="right">
<font color="red">*</font> indicates required</p>
<strong>Public Methods:</strong>
<br>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td>
<blockquote>Checks for any param errors. If errors are found, sets
the display template to the specified URL (a system-wide request
error page by default).</blockquote><dl>
<dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>url</code><font color="red">*</font>
</td><td align="left">The URL of the template to use to display error
messages. The special value { self} may be used to indicate that
the template for the requested page itself will handle reporting
error conditions.</td>
</tr></table>
</dd><dt><strong>Returns:</strong></dt><dd>1 if no error conditions exist, 0 otherwise.</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td>
<blockquote>Create the request data structure. Typically called at
the beginning of the code for any page that accepts query
parameters.</blockquote><dl>
<dt><strong>Options:</strong></dt><dd><table><tr>
<td align="right"><code>params</code></td><td align="left">A block of parameter declarations, separated by
newlines. Equivalent to calling set_param for each parameter, but
requiring slightly less typing.</td>
</tr></table></dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td>
<blockquote>Declares a query parameter as part of the page request.
Validates the values associated with the parameter, in the same
fashion as for form elements.</blockquote><dl>
<dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>name</code><font color="red">*</font>
</td><td align="left">The name of the parameter to declare.</td>
</tr></table>
</dd><dt><strong>Options:</strong></dt><dd><table>
<tr>
<td align="right"><code>name</code></td><td align="left">The name of parameter in the query (may be
different from the reference name).</td>
</tr><tr>
<td align="right"><code>multiple</code></td><td align="left">A flag indicating that multiple values may be
specified for this parameter.</td>
</tr><tr>
<td align="right"><code>datatype</code></td><td align="left">The name of a datatype for the element values.
Valid datatypes must have a validation procedure defined in the
<kbd>template::data::validate</kbd> namespace.</td>
</tr><tr>
<td align="right"><code>optional</code></td><td align="left">A flag indicating that no value is required for
this element. If a default value is specified, the default is used
instead.</td>
</tr><tr>
<td align="right"><code>validate</code></td><td align="left">A list of custom validation blocks in the form {
name { expression } { message } \ name { expression } { message }
...} where name is a unique identifier for the validation step,
expression is a block to Tcl code that evaluates to 1 or 0, and
message is to be displayed to the user when the validation step
fails.</td>
</tr>
</table></dd><dt><strong>See Also:</strong></dt><dd>element::create - <a href=""></a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td>
<blockquote>Manually report request error(s) by setting error
messages and then calling is_valid to handle display. Useful for
conditions not tied to a single query parameter. The arguments to
the procedure may be any number of name-message
combinations.</blockquote><dl><dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>name</code><font color="red">*</font>
</td><td align="left">A unique identifier for the error condition, which
may be used for layout purposes.</td>
</tr><tr>
<td align="right">
<code>msg</code><font color="red">*</font>
</td><td align="left">The message text associated with the
condition.</td>
</tr>
</table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td>
<blockquote>Retrieves the value(s) of the specified
parameter.</blockquote><dl>
<dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>name</code><font color="red">*</font>
</td><td align="left">The name of the parameter.</td>
</tr></table>
</dd><dt><strong>Returns:</strong></dt><dd>The value of the specified parameter.</dd>
</dl>
</td></tr>
</table>
<p align="right">
<font color="red">*</font> indicates required</p>
