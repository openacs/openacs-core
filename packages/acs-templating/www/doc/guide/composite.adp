
<property name="context">{/doc/acs-templating/ {ACS Templating}} {Templating System User Guide: Composite Page}</property>
<property name="doc(title)">Templating System User Guide: Composite Page</property>
<master>
<style>
div.sect2 > div.itemizedlist > ul.itemizedlist > li.listitem {margin-top: 16px;}
div.sect3 > div.itemizedlist > ul.itemizedlist > li.listitem {margin-top: 6px;}
</style>              
<h2>Assembling a Page from Components</h2>
<a href="..">Templating System</a>
 : <a href="../developer-guide">Developer Guide</a>
 : <a href="">User
Guide</a>
 : Composite
<p>A typical page served to a browser is made up from several
component pages. The idea is to have reusable parts (widgets,
skins), a bit like in a programming language where code that may be
used more than once makes up a procedure. The complete page may
have the following structure.</p>
<center><table cellpadding="5" cellspacing="0"><tr><td bgcolor="#FFCCCC">
<strong>master</strong><table cellpadding="5" cellspacing="8">
<tr><td bgcolor="#CCCCFF" valign="top"><strong>top</strong></td></tr><tr><td height="120" bgcolor="#CCCC99" valign="top">
<strong>root
(main)</strong><p> </p><table cellpadding="5" cellspacing="8"><tr><td width="120" bgcolor="#CCFFCC" valign="top"><strong>widget</strong></td></tr></table>
</td></tr><tr><td bgcolor="#99CCFF" valign="top"><strong>bottom</strong></td></tr>
</table>
</td></tr></table></center>
<p>The "root" page includes the "widget" and
wraps itself in the "master". That page in turn includes
the "top" and "bottom".</p>
<h3>Overall structure</h3>
<p>The parts are put together with the <code>&lt;<a href="../tagref/include">include</a>&gt;</code> tag (in the diagram
below, black links going right) and the <code>&lt;<a href="../tagref/master">master</a>&gt;</code> tag (brown link going
left); and the concept is similar to a procedure call. The
structure of the composite page looks like this as a graph.</p>
<center><table cellpadding="0" cellspacing="0" border="0">
<tr>
<td colspan="10" rowspan="3"></td><th colspan="7">root</th>
</tr><tr><td><img src="/image/clear.gif" width="1" height="5"></td></tr><tr>
<td bgcolor="#CCCC99"> code </td><td width="1"><img src="/images/clear.gif"></td><td bgcolor="#CCCC99" colspan="5"> template </td>
</tr><tr>
<td colspan="12"></td><td><img src="/images/clear.gif" width="20" height="20"></td><td bgcolor="#990000" width="1"><img src="/images/clear.gif" width="1" height="20"></td><td><img src="/images/clear.gif" width="20" height="20"></td><td bgcolor="#000000" width="1"><img src="/images/clear.gif" width="1" height="20"></td><td><img src="/images/clear.gif" height="20"></td>
</tr><tr>
<td colspan="3" rowspan="2"></td><td colspan="11" height="1" bgcolor="#990000">
<img src="/images/clear.gif" width="1" height="1"><!-- no space-->
</td><td height="1"><img src="/images/clear.gif" width="1" height="1"></td><td colspan="5" height="1" bgcolor="#000000"><img src="/images/clear.gif" width="1" height="1"></td>
</tr><tr>
<td bgcolor="#990000" width="1"><img src="/images/clear.gif" width="1" height="20"></td><td colspan="15"></td><td bgcolor="#000000" width="1"><img src="/images/clear.gif" width="1" height="20"></td>
</tr><tr>
<th>master</th><td><img src="/images/clear.gif" width="8"></td><td bgcolor="#FFCCCC"> code </td><td width="1"><img src="/images/clear.gif"></td><td bgcolor="#FFCCCC" colspan="5"> template </td><td colspan="9"></td><td bgcolor="#CCFFCC"> code </td><td width="1"><img src="/images/clear.gif"></td><td bgcolor="#CCFFCC"> template </td><td><img src="/images/clear.gif" width="8"></td><th>widget</th>
</tr><tr>
<td colspan="4" rowspan="4"></td><td rowspan="4"><img src="/images/clear.gif" width="20" height="20"></td><td bgcolor="#000000" width="1" rowspan="3"><img src="/images/clear.gif" width="1" height="20"></td><td rowspan="2"><img src="/images/clear.gif" width="20" height="20"></td><td bgcolor="#000000" width="1"><img src="/images/clear.gif" width="1" height="20"></td><td><img src="/images/clear.gif" height="20"></td>
</tr><tr><td bgcolor="#000000" colspan="13"><img src="/images/clear.gif" width="1" height="1"></td></tr><tr>
<td colspan="13" height="8"><img src="/images/clear.gif"></td><td rowspan="3" bgcolor="#000000"><img src="/images/clear.gif"></td>
</tr><tr><td colspan="7" bgcolor="#000000"><img src="/images/clear.gif"></td></tr><tr>
<td colspan="11"></td><td bgcolor="#000000" height="20"><img src="/images/clear.gif"></td>
</tr><tr>
<td colspan="10" rowspan="3"></td><td bgcolor="#CCCCFF"> code </td><td width="1"><img src="/images/clear.gif"></td><td bgcolor="#CCCCFF" colspan="5"> template </td><td rowspan="3"><img src="/images/clear.gif" width="8"></td><td bgcolor="#99CCFF"> code </td><td width="1"><img src="/images/clear.gif"></td><td bgcolor="#99CCFF"> template </td>
</tr><tr><td><img src="/image/clear.gif" width="1" height="5"></td></tr><tr>
<th colspan="7">top</th><th colspan="3">bottom</th>
</tr>
</table></center>
<p>Any (sub)page can have 0 or 1 master and 0 or more included
pages. Each page has its own <em>separate</em> scope for variables.
Arguments can be passed to dependent pages as attributes to
<code>&lt;include&gt;</code>, or as properties to
<code>&lt;master&gt;</code>. The directed graph of pages will often
be be acyclic, as in the example, but this is not required.</p>
<h3>Evaluation Order</h3>
<p>Sometimes it is of interest in which order the different parts
are evaluated. The "code" always runs first, followed by
the template. The <code>&lt;include&gt;</code> tag causes the
subpage to be evaluated at this point of the template, and the rest
of the including template is evaluated after that&#39;s done. This
is like a procedure call. In contrast, the
<code>&lt;master&gt;</code> tag is deferred until the whole slave
page ("root" in the example) is done. For our example,
the following order results.</p>
<center><table>
<tr>
<td colspan="3" bgcolor="#CCCC99"><strong>root.tcl</strong></td><td></td>
</tr><tr>
<td colspan="3" bgcolor="#CCCC99"><strong>root.adp</strong></td><td>(beginning and middle)</td>
</tr><tr>
<td rowspan="2" width="15" bgcolor="#CCCC99"> </td><td colspan="2" bgcolor="#CCFFCC"><strong>widget.tcl</strong></td><td></td>
</tr><tr>
<td colspan="2" bgcolor="#CCFFCC"><strong>widget.adp</strong></td><td></td>
</tr><tr>
<td colspan="3" bgcolor="#CCCC99"><strong>root.adp</strong></td><td>(end)</td>
</tr><tr>
<td rowspan="8" width="15" bgcolor="#CCCC99"> </td><td colspan="2" bgcolor="#FFCCCC"><strong>master.tcl</strong></td><td></td>
</tr><tr>
<td colspan="2" bgcolor="#FFCCCC"><strong>master.adp</strong></td><td>(beginning)</td>
</tr><tr>
<td rowspan="2" width="15" bgcolor="#FFCCCC"> </td><td bgcolor="#CCCCFF"><strong>top.tcl</strong></td><td></td>
</tr><tr>
<td bgcolor="#CCCCFF"><strong>top.adp</strong></td><td></td>
</tr><tr>
<td colspan="2" bgcolor="#FFCCCC"><strong>master.adp</strong></td><td>(middle, containing <code>&lt;slave&gt;</code> tag)</td>
</tr><tr>
<td rowspan="2" width="15" bgcolor="#FFCCCC"> </td><td bgcolor="#99CCFF"><strong>bottom.tcl</strong></td><td></td>
</tr><tr>
<td bgcolor="#99CCFF"><strong>bottom.adp</strong></td><td></td>
</tr><tr>
<td colspan="2" bgcolor="#FFCCCC"><strong>master.adp</strong></td><td>(end)</td>
</tr>
</table></center>
<p>Here we assume the ACS/Tcl situation, where the "code"
is a Tcl script in a .tcl file. The template is a .adp file.</p>
<h3>Variants of Page Nodes</h3>
<p>The graph of the overall structure has five nodes, shown as a
code/template pair. This is the standard situation, where the
"code" part sets up datasources and the template uses
them. In some situations, the following facility can help to reduce
duplication or to handle special situations more effectively.</p>
<p>The "code" part can divert to another page by calling
<code>template::set_file</code> to modify the filename stub of the
page being processed. For convenience,
<code>ad_return_template</code> can be used with the same effect;
it is a wrapper for <code>template::set_file</code>, and it
supplies the current file as the reference path. Neither affects
the flow of control; the script runs to completion. If at the end
the name is changed, the template of the original page is not used;
instead the new page is processed, code first, then template. As
that page&#39;s code can call <code>set_file</code> again, we get
the following picture.</p>
<center><table cellspacing="0" cellpadding="0" border="0">
<tr>
<td bgcolor="#FFCC99">code A</td><td width="1"><img src="/images/clear.gif"></td><td align="right"><font color="gray">(template A
ignored)</font></td>
</tr><tr><td align="center"><img src="down.gif" width="7" height="15"></td></tr><tr>
<td bgcolor="#FFCC99">code B</td><td></td><td align="right"><font color="gray">(template B
ignored)</font></td>
</tr><tr><td align="center"><img src="down.gif" width="7" height="15"></td></tr><tr><td align="center">...</td></tr><tr><td align="center"><img src="down.gif" width="7" height="15"></td></tr><tr>
<td bgcolor="#FFCC99" align="center">code Z</td><td></td><td bgcolor="#FFCC99" align="center">template Z</td>
</tr>
</table></center>
<p>This assumes page "A" was originally wanted. An arrow
(<img src="down.gif" width="7" height="15" align="top">) exits from
code which calls <code>template::set_file</code> (directly or
through <code>ad_return_template</code>). All scripts and the
template are executed in the <em>same</em> scope, i.e., they share
variables.</p>
<p>Furthermore, either of the final files can be omitted if it is
not needed, giving three basic possibilities.</p>
<center><table cellspacing="0" cellpadding="0" border="0">
<tr>
<td width="50">a)</td><td bgcolor="#FFCC99" align="center">code</td><td width="1"><img src="/images/clear.gif"></td><td bgcolor="#FFCC99" align="center">template</td>
</tr><tr><td> </td></tr><tr>
<td>b)</td><td><font color="gray">(no code)</font></td><td></td><td bgcolor="#FFCC99" align="center">template</td>
</tr><tr><td> </td></tr><tr>
<td>c)</td><td bgcolor="#FFCC99" align="center">code</td><td></td><td><font color="gray">(no template)</font></td>
</tr>
</table></center>
<p>It is an error to omit both parts; this is a special case
intended to speed up debugging.</p>
<hr>
<!-- <a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a> -->