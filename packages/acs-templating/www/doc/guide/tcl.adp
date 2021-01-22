
<property name="context">{/doc/acs-templating {ACS Templating}} {Templating System User Guide: Embedding Code in
Templates}</property>
<property name="doc(title)">Templating System User Guide: Embedding Code in
Templates</property>
<master>
<h2>Embedding Code in Templates</h2>
<a href="..">Templating System</a>
 : <a href="../developer-guide">Developer Guide</a>
 : User Guide
<p>There are various ways to use Tcl in ADPs like ASP or JSP.</p>
<p>You can use the <code>&lt;% ... %&gt;</code> and <code>&lt;%=
... %&gt;</code> tags just as in an ADP page handled by the
AOLserver. For examples, see the section "embedded tcl"
on the <a href="../demo">demonstration page</a>.</p>
<p>Generally, avoid putting escaped Tcl code in adp files, or
generating HTML fragments in Tcl procedures. It subverts the
separation of code and layout, one of the benefits of templating.
Embedded Tcl makes templates non-portable to ACS/Java.</p>
<hr>
<!-- <a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a> -->