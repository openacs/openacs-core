
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {OpenACS Edit This Page Templates}</property>
<property name="doc(title)">OpenACS Edit This Page Templates</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="tutorial-cvs" leftLabel="Prev"
			title="Chapter 10. Advanced
Topics"
			rightLink="tutorial-comments" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="tutorial-etp-templates"></a>OpenACS Edit This Page Templates</h2></div></div></div><span style="color: red">&lt;authorblurb&gt;</span><p><span style="color: red">by <a class="ulink" href="mailto:ncarroll\@ee.usyd.edu.au" target="_top">Nick
Carroll</a>
</span></p><span style="color: red">&lt;/authorblurb&gt;</span><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="goals"></a>Goals</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Learn about the OpenACS templating system.</p></li><li class="listitem"><p>Learn about subsites and site-map administration.</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="introduction"></a>Introduction</h3></div></div></div><p>The OpenACS templating system allows you to give your site a
consistent look and feel. It also promotes code maintainability in
the presentation layer, by allowing presentation components to be
reused across multiple pages. If you need to change the layout for
some reason, then you only need to make that change in one
location, instead of across many files.</p><p>In this problem set you will familiarise yourself with the
templating system in openacs. This will be achieved through
customising an existing edit-this-page application template.</p><p>Before proceeding, it is strongly advised to read the templating
documentation on your OpenACS installation
(http://localhost:8000/doc/acs-templating). The documentation lists
the special tags available for ADP files.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="exercise1"></a>Exercise 1: Create a
Subsite</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Create a subsite called pset3.</p></li><li class="listitem">
<p>A subsite is simply a directory or subdirectory mounted at the
end of your domain name. This can be done in one of two places:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>http://localhost:8000/admin/site-map</p></li><li class="listitem"><p>or the subsite admin form on the main site, which is available
when you login to your OpenACS installation.</p></li>
</ul></div>
</li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="exercise2"></a>Exercise 2: Checkout and
Install edit-this-page (ETP)</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p>Checkout ETP from CVS:</p><pre class="screen">cd ~/openacs/packages
            cvs -d:pserver:anonymous\@openacs.org:/cvsroot login
            cvs -d:pserver:anonymous\@openacs.org:/cvsroot co edit-this-page</pre>
</li><li class="listitem"><p>Go to the package manager at http://yoursite/acs-admin/apm. And
install the new package: edit-this-page.</p></li><li class="listitem"><p>Or use the "Add Application" form available on the
Main site.</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="exercise3"></a>Change ETP
Application</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Work out how to change the ETP application.</p></li><li class="listitem">
<p>Investigate each of the available ETP templates:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>Default</p></li><li class="listitem"><p>News</p></li><li class="listitem"><p>FAQ</p></li>
</ul></div>
</li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="exercise4"></a>Exercise 4: Create a New
ETP Template</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p>Browse the files for each of the above ETP templates at:</p><pre class="screen">
cd ~/openacs/packages/edit-this-page/templates</pre>
</li><li class="listitem">
<p>Use the article template as the basis of our new col2
template.</p><pre class="screen">cp article-content.adp col2-content.adp
            cp article-content.tcl col2-content.tcl
            cp article-index.adp col2-index.adp
            cp article-index.tcl col2-index.tcl</pre>
</li><li class="listitem">
<p>The template should provide us with the following ETP
layout:</p><div class="table">
<a name="idp140682185689992"></a><p class="title"><strong>Table 10.1. table showing ETP
layout</strong></p><div class="table-contents"><table class="table" summary="table showing ETP layout" cellspacing="0" border="1" width="250">
<colgroup>
<col align="left" class="c1"><col width="2" align="left" class="c2">
</colgroup><tbody>
<tr><td colspan="2" align="center">Header</td></tr><tr height="200">
<td align="left">Sidebar</td><td align="left">Main Content Pane</td>
</tr>
</tbody>
</table></div>
</div><br class="table-break">
</li><li class="listitem"><p>The "Main Content" pane should contain the editable
content that ETP provides.</p></li><li class="listitem"><p>The "Header" should display the title of the page that
you set in ETP.</p></li><li class="listitem"><p>The "Sidebar" should display the extlinks that you add
as a content item in ETP.</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="exercise5"></a>Exercise 5: Register the
col2 Template with ETP</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p>Need to register your template with ETP so that it appears in
the drop-down menu that you would have seen in Exercise 3.</p><pre class="screen">cd ~/openacs/packages/edit-this-page/tcl
            emacs etp-custom-init.tcl</pre>
</li><li class="listitem">
<p>Use the function etp::define_application to register your
template with ETP</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>Uncomment the "asc" definition</p></li><li class="listitem"><p>Set allow_extlinks to true, the rest should be false.</p></li>
</ul></div>
</li><li class="listitem"><p>Restart your server for the changes to take effect.</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="exercise6"></a>Exercise 6: Configure ETP
to use the col2 Template</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Configure your ETP instance at /lab4/index to use the col2
template.</p></li><li class="listitem"><p>Create external links to link to other mounted ETP
instances.</p></li><li class="listitem"><p>Check that your external links show up in the sidebar when you
view your ETP application using the col2 template.</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="end"></a>Who Wrote This and When</h3></div></div></div><p>This problem set was originally written by Nick Carroll in
August 2004 for the <a class="ulink" href="http://www.usyd.edu.au" target="_top">University of Sydney</a> Course EBUS5002.</p><p>This material is copyright 2004 by Nick Carroll. It may be
copied, reused, and modified, provided credit is given to the
original author.</p><p><span class="cvstag">($&zwnj;Id: tutorial-advanced.xml,v 1.54
2017/12/24 13:15:07 gustafn Exp $)</span></p>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="tutorial-cvs" leftLabel="Prev" leftTitle="Add the new package to CVS"
			rightLink="tutorial-comments" rightLabel="Next" rightTitle="Adding Comments"
			homeLink="index" homeLabel="Home" 
			upLink="tutorial-advanced" upLabel="Up"> 
		    <a name="comments"></a>
