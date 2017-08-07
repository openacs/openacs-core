
<property name="context">{/doc/acs-templating {ACS Templating}} {}</property>
<property name="doc(title)"></property>
<master>
<h2>Namespace util</h2>
<h3>Method Summary</h3>

Listing of public methods:<br>
<blockquote>The namespace util currently contains no public
methods.</blockquote>
<h3>Method Detail</h3>
<p align="right">
<font color="red">*</font> indicates required</p>
<p>
<strong>Private Methods</strong>:<br>
</p>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td><blockquote>a proc used for debugging, just prints out a value to
the error log</blockquote></td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td>
<blockquote>capitalizes the first letter of a string</blockquote><dl>
<dt><strong>Returns:</strong></dt><dd>returns formatted string</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td>
<blockquote>escapes quotes and removes comment tags from a body of
commented text</blockquote><dl>
<dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>text</code><font color="red">*</font>
</td><td align="left"></td>
</tr></table>
</dd><dt><strong>Returns:</strong></dt><dd>text</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td>
<blockquote>just takes a body of text and puts a space behind every
double {quote;} this is done so that the text body can be treated
as a list without causing problems resulting from list elements
being separated by characters other than a space</blockquote><dl>
<dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>text</code><font color="red">*</font>
</td><td align="left">req/none the body of text to be worked on</td>
</tr></table>
</dd><dt><strong>Returns:</strong></dt><dd>same text but with a space behind each quote; double quotes
that are already trailed by a space are unaffected</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td>
<blockquote>takes a .adp template name and the name of the file to
be written and creates the {file;} also puts out a notice
before</blockquote><dl><dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>template</code><font color="red">*</font>
</td><td align="left">the name of the template to be used in making the
file</td>
</tr><tr>
<td align="right">
<code>file_name</code><font color="red">*</font>
</td><td align="left">the name of the file to be created</td>
</tr>
</table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td>
<blockquote>takes an alphabetized list and an entry</blockquote><dl>
<dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>list</code><font color="red">*</font>
</td><td align="left">{let&#39;s see how this parses out} the
alphabetized list</td>
</tr><tr>
<td align="right">
<code>entry</code><font color="red">*</font>
</td><td align="left">req the value to be inserted</td>
</tr>
</table>
</dd><dt><strong>Returns:</strong></dt><dd>either the proper list index for an alphabetized insertion or
-1 if the entry is already in the list</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td><blockquote>used to compare two different elements in a list of
parsed data for public or private procs</blockquote></td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td><blockquote>uses ns_library to find the server root, may not always
be accurate because it essentially asks for the Tcl library path
and strips off the last /tcl directory</blockquote></td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td></td></tr>
</table>
<p align="right">
<font color="red">*</font> indicates required</p>
