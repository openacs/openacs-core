
<property name="context">{/doc/acs-templating {ACS Templating}} {}</property>
<property name="doc(title)"></property>
<master>
<h2>Namespace doc::util</h2>
<h3>Method Summary</h3>

Listing of public methods:<br>
<blockquote>The namespace doc::util currently contains no public
methods.</blockquote>
<h3>Method Detail</h3>
<p align="right">
<font color="red">*</font> indicates required</p>
<p>
<strong>Private Methods</strong>:<br>
</p>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="set split_name $see_name doc::util::text_divider split_name :: set name_length [llength $split_name] set see_namespace [join [lrange $split_name 0 [expr $name_length - 2]] \" set="" url=""><font size="+1" weight="bold">set split_name
$see_name doc::util::text_divider split_name :: set name_length
[llength $split_name] set see_namespace [join [lrange $split_name 0
[expr $name_length - 2]] \"\"] set url
\"[doc::util::dbl_colon_fix $see_namespace].html#[set
see_name]\"</font></a></td></tr><tr><td><blockquote>procedure to deal with \@see comments</blockquote></td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td>
<blockquote>divides a string variable into a list of strings, all
but the first element beginning with the indicated text {marker;}
the first element of the created list contains all of the string
preceding the first occurrence of the text marker</blockquote><dl>
<dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>text</code><font color="red">*</font>
</td><td align="left">name of string variable (not the string value
itself)</td>
</tr><tr>
<td align="right">
<code>marker</code><font color="red">*</font>
</td><td align="left">the string indicating text division</td>
</tr>
</table>
</dd><dt><strong>See Also:</strong></dt><dd>proc - <a href="doc__util">doc::util::find_marker_indices</a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td><blockquote>escapes out all square brackets</blockquote></td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td>
<blockquote>given a body of text and a text marker, returns a list
of position indices for each occurrence of the text
marker</blockquote><dl>
<dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>text</code><font color="red">*</font>
</td><td align="left">body of text to be searched through</td>
</tr><tr>
<td align="right">
<code>marker</code><font color="red">*</font>
</td><td align="left">the text-divider mark</td>
</tr>
</table>
</dd><dt><strong>Returns:</strong></dt><dd>list of indices of the position immediately preceding each
occurrence of the text marker; if there are no occurrences of the
text marker, returns a zero-element list</dd><dt><strong>See Also:</strong></dt><dd>namespace - <a href="doc">doc</a><br>
</dd><dd>proc - <a href="doc">doc::parse_file</a><br><a href="doc">doc::parse_namespace</a><br><a href="doc__util">doc::util::text_divider</a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td><blockquote>puts a space after all closing curly brackets, does not
add a space when brackets are already followed by a
space</blockquote></td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td>
<blockquote>used to sort the see list, which has structure {[name}
name type type url url \]</blockquote><dl><dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>element1</code><font color="red">*</font>
</td><td align="left">the first of the two list elements to be
compared</td>
</tr><tr>
<td align="right">
<code>element2</code><font color="red">*</font>
</td><td align="left">the second of the two elements to be compared</td>
</tr>
</table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td></td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td></td></tr>
</table>
<p align="right">
<font color="red">*</font> indicates required</p>
