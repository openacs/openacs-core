
<property name="context">{/doc/acs-templating {ACS Templating}} {Template Markup Tag Reference}</property>
<property name="doc(title)">Template Markup Tag Reference</property>
<master>
<h2>Template Markup Tag Reference</h2>
<a href="..">Templating System</a>
 : <a href="../designer-guide">Designer Guide</a>
 : Tag Reference
<h3>Overview</h3>
<p>The publishing system implements a small number of special
markup tags that allow template authors to add dynamic features to
their work. The tags allow authors to accomplish four basic tasks
that are not possible with standard HTML:</p>
<ul>
<li>Embed a dynamic variable in a template (<a href="variable">variables</a>).</li><li>Repeat a template section for each object in a dynamic list of
objects (<kbd>multiple</kbd>, <kbd>grid</kbd>).</li><li>Output different template sections depending on the value of
one or more dynamic variables (<kbd>if</kbd>).</li><li>Provide a mechanism for building complete pages from multiple
component templates (<kbd>include</kbd>).</li>
</ul>
<h3>Available Tags</h3>
<ul>
<li><a href="variable">Variables</a></li><li><code>&lt;<a href="multiple">multiple</a>&gt;</code></li><li><code>&lt;<a href="group">group</a>&gt;</code></li><li><code>&lt;<a href="grid">grid</a>&gt;</code></li><li><code>&lt;<a href="list">list</a>&gt;</code></li><li><code>&lt;<a href="if">if&gt;,&lt;elseif&gt;,&lt;else&gt;</a>
</code></li><li><code>&lt;<a href="switch">switch&gt;,&lt;case&gt;,&lt;default&gt;</a>
</code></li><li><code>&lt;<a href="include">include</a>&gt;</code></li><li><code>&lt;<a href="include-optional">include-optional</a>&gt;</code></li><li><code>&lt;<a href="property">property</a>&gt;</code></li><li><code>&lt;<a href="noparse">noparse</a>&gt;</code></li><li><code>&lt;<a href="master">master</a>&gt;</code></li><li><code>&lt;<a href="slave">slave</a>&gt;</code></li><li><code>&lt;<a href="formtemplate">formtemplate</a>&gt;</code></li><li><code>&lt;<a href="formwidget">formwidget</a>&gt;</code></li><li><code>&lt;<a href="formgroup">formgroup</a>&gt;</code></li><li><code>&lt;<a href="formerror">formerror</a>&gt;</code></li><li><code>&lt;<a href="listtemplate">listtemplate</a>&gt;</code></li><li><code>&lt;<a href="listtemplate">listfilters</a>&gt;</code></li>
</ul>
<h3>Notes</h3>
<ul>
<li><p>Template tags are processed by the server each time a page is
requested. The end result of this processing is a standard HTML
page that is delivered to the user. Users do not see template tags
in the HTML source code of the delivered page.</p></li><li>
<p>With normal usage, the use of dynamic tags tends to increase the
amount of whitespace in the final HTML as compared to the template.
This usually does not affect how browsers display the page.
However, if a page layout depends on the presence or absence of
whitespace between HTML tags for proper display, then special care
must be taken with dynamic tags to avoid adding whitespace.</p><p>When placed on a line by themselves, tags that are containers
for template sections (<kbd>grid</kbd>, <kbd>if</kbd>, and
<kbd>multiple</kbd>) will cause newlines to be added to the page at
the beginning and end of the section. This can be avoided by
crowding the start and end tags like so:</p><pre>
&lt;td&gt;&lt;if %x% eq 5&gt;&lt;img src="five.gif"&gt;&lt;/if&gt;
&lt;else&gt;&lt;img src="notfive.gif"&gt;&lt;/else&gt;&lt;/td&gt;
        </pre><p>Note that this should not be done unless necessary, since it
reduces the legibility of the template to others who need to edit
the template later.</p>
</li>
</ul>
<hr>
<address><a href="mailto:christian\@arsdigita.com">Christian
Brechbühler</a></address>
<!-- Created: Fri Sep 15 15:05:44 EDT 2000 -->
Last modified: $&zwnj;Id: index.html,v 1.5 2017/08/07 23:48:03 gustafn
Exp $
