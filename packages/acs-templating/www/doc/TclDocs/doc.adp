
<property name="context">{/doc/acs-templating {ACS Templating}} {}</property>
<property name="doc(title)"></property>
<master>
<h2>Namespace doc</h2>
<h3>Method Summary</h3>

Listing of public methods:<br>
<blockquote>The namespace doc currently contains no public
methods.</blockquote>
<h3>Method Detail</h3>
<p align="right">
<font color="red">*</font> indicates required</p>
<p>
<strong>Private Methods</strong>:<br>
</p>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF">
<a name=""></a><br><small><em>  by simon</em></small>
</td></tr><tr><td>
<blockquote>called by parse_file, this procedure is given the body
of text between two namespace markers in a Tcl library file and
parses out procedure source and comments</blockquote><dl><dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>text_lines</code><font color="red">*</font>
</td><td align="left">namespace text body</td>
</tr></table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td><blockquote>Parse API documentation from a Tcl page API
documentation is parsed as follows: Document is scanned until a
\@namespace directive is encountered. The remainder of the file is
scanned for \@private or \@public directives. When one of these
directives is encountered, the file is scanned up to a proc
declaration and the text in between is parsed as documentation for
a single procedure. The text between the initial \@private or
\@public directive and the next directive is considered a general
comment on the procedure Valid directives in a procedure doc
include: - \@author - \@param (for hard parameters) - \@see (should
have the form namespace::procedure. A reference to an entire
namespace should be namespace::. By convention the API for each
namespace should be in a file of the same name, so that a link can
be generated automatically). - \@option (for switches such as -foo)
- \@return</blockquote></td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td>
<blockquote>called by parse_comment_text</blockquote><dl><dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>comment_text</code><font color="red">*</font>
</td><td align="left">this should include the source text</td>
</tr></table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td>
<blockquote>called by parse_namespace</blockquote><dl><dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>comment_text</code><font color="red">*</font>
</td><td align="left">body of comment text to be parsed through</td>
</tr><tr>
<td align="right">
<code>source_text</code><font color="red">*</font>
</td><td align="left">source text of the procedure</td>
</tr>
</table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td>
<blockquote>takes the absolute path of the Tcl library directory
and parses through it</blockquote><dl>
<dt><strong>Returns:</strong></dt><dd>a long lists of lists of lists, each list element contains a
three-element list of the format { {info} {public procedures
listing } {private procedures listing} }</dd><dt><strong>See Also:</strong></dt><dd>namespace - <a href="util">util</a><br>
</dd><dd>proc - <a href="doc">doc::parse_file</a><br><a href="util">template::util::comment_text_normalize</a><br>
</dd>
</dl>
</td></tr>
</table>
<p align="right">
<font color="red">*</font> indicates required</p>
