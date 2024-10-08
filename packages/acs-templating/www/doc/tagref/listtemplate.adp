
<property name="context">{/doc/acs-templating/ {ACS Templating}} {Templating System Tag Reference: Listtemplate}</property>
<property name="doc(title)">Templating System Tag Reference: Listtemplate</property>
<master>
<style>
div.sect2 > div.itemizedlist > ul.itemizedlist > li.listitem {margin-top: 16px;}
div.sect3 > div.itemizedlist > ul.itemizedlist > li.listitem {margin-top: 6px;}
</style>              
<h2>Listtemplate</h2>
<a href="..">Templating System</a>
 : <a href="../designer-guide">Designer Guide</a>
 : <a href="index">Tag Reference</a>
 : Listtemplate
<h3>Summary</h3>
<p>The <kbd>listtemplate</kbd> tag is used to embed a multirow list
template. The name of the multirow is passed to the template.
Optionally, also <kbd>listfilters</kbd> can be specified that can
be used to filter the displayed elements.</p>
<h3>Usage</h3>
<pre>
  &lt;table&gt;
  &lt;tr&gt;
    &lt;td class="list-filter-pane"&gt;
       &lt;listfilters name="notes"&gt;&lt;/listfilters&gt;
    &lt;/td&gt;
    &lt;td class="list-list-pane"&gt;
       &lt;listtemplate name="notes"&gt;&lt;/listtemplate&gt;
    &lt;/td&gt;
  &lt;/tr&gt;
  &lt;/table&gt;
</pre>
<h3>Notes</h3>
<p>Both, the <kbd>listtemplate</kbd> and the <kbd>listfilters</kbd>
can be tailored with an optional <kbd>style</kbd> attribute. If no
<kbd>style</kbd> attribute is specified, the package parameters
<kbd>DefaultListStyle</kbd> and <kbd>DefaultListFilterStyle</kbd>
of acs-templating are used as default values.</p>
<p>See the <a href="/doc/acs-templating/demo/#listbuilder"><kbd>listbuilder
demos</kbd></a> for more detailed examples.</p>
<hr>
<!-- <a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a> -->