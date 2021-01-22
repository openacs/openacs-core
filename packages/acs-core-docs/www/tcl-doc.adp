
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Documenting Tcl Files: Page Contracts and Libraries}</property>
<property name="doc(title)">Documenting Tcl Files: Page Contracts and Libraries</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="rp-design" leftLabel="Prev"
		    title="
Chapter 15. Kernel Documentation"
		    rightLink="bootstrap-acs" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="tcl-doc" id="tcl-doc"></a>Documenting Tcl Files: Page Contracts and
Libraries</h2></div></div></div><div class="authorblurb">
<p>By <a class="ulink" href="mailto:jsalz\@mit.edu" target="_top">Jon Salz</a> on 3 July 2000</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;"><li class="listitem"><p>Tcl procedures:
/packages/acs-kernel/tcl-documentation-procs.tcl</p></li></ul></div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="tcl-doc-bigpicture" id="tcl-doc-bigpicture"></a>The Big Picture</h3></div></div></div><p>In versions of the OpenACS prior to 3.4, <a class="ulink" href="/doc/standards" target="_top">the standard place</a> to document
Tcl files (both Tcl pages and Tcl library files) was in a comment
at the top of the file:</p><pre class="programlisting">
#
# <span class="emphasis"><em>path from server home</em></span>/<span class="emphasis"><em>filename</em></span>
#
# <span class="emphasis"><em>Brief description of the file&#39;s purpose</em></span>
#
# <span class="emphasis"><em>author&#39;s email address</em></span>, <span class="emphasis"><em>file creation date</em></span>
#
# <a class="ulink" href="http://www.loria.fr/~molli/cvs/doc/cvs_12.html#SEC93" target="_top">$&zwnj;Id: tcl-doc.xml,v 1.7 2006/07/17 05:38:38 torbenb Exp $</a>
#
</pre><p>In addition, the inputs expected by a Tcl page (i.e., form
variables) would be enumerated in a call to <code class="computeroutput">ad_page_variables</code>, in effect, documenting
the page&#39;s argument list.</p><p>The problem with these practices is that the documentation is
only accessible by reading the source file itself. For this reason,
ACS 3.4 introduces a new API for documenting Tcl files and, on top
of that, a web-based user interface for browsing the
documentation:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>
<span class="strong"><strong><code class="computeroutput"><a class="link" href="tcl-doc" title="ad_page_contract">ad_page_contract</a></code></strong></span>:
Every Tcl page has a <span class="strong"><strong>contract</strong></span> that explicitly defines
what inputs the page expects (with more precision than <code class="computeroutput">ad_page_variables</code>) and incorporates
metadata about the page (what used to live in the top-of-page
comment). Like <code class="computeroutput">ad_page_variables</code>, <code class="computeroutput">ad_page_contract</code> also sets the specified
variables in the context of the Tcl page.</p></li><li class="listitem"><p>
<span class="strong"><strong><code class="computeroutput"><a class="link" href="tcl-doc" title="ad_library">ad_library</a></code></strong></span>: To be called at
the top of every library file (i.e., all files in the <code class="computeroutput">/tcl/</code> directory under the server root and
<code class="computeroutput">*-procs.tcl</code> files under
<code class="computeroutput">/packages/</code>).</p></li>
</ul></div><p>This has the following benefits:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Facilitates automatic generation of human-readable
documentation.</p></li><li class="listitem"><p>Promotes security, by introducing a standard and automated way
to check inputs to scripts for correctness.</p></li><li class="listitem"><p>Allows graphical designers to determine easily how to customize
sites' UIs, e.g., what properties are available in
templates.</p></li><li class="listitem"><p>Allows the request processor to be intelligent: a script can
specify in its contract which type of abstract document it returns,
and the request processor can transform it automatically into
something useful to a particular user agent. (Don&#39;t worry about
this for now - it&#39;s not complete for ACS 3.4.)</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="tcl-doc-ad-page-contract" id="tcl-doc-ad-page-contract"></a>ad_page_contract</h3></div></div></div><p>Currently <code class="computeroutput">ad_page_contract</code>
serves mostly as a replacement for <code class="computeroutput">ad_page_variables</code>. Eventually, it will be
integrated closely with the documents API so that each script&#39;s
contract will document precisely the set of properties available to
graphical designers in templates. (Document API integration is
subject to change, so we don&#39;t decsribe it here yet; for now,
you can just consider <code class="computeroutput">ad_page_contract</code> a newer, better,
documented <code class="computeroutput">ad_page_variables</code>.)</p><p>Let&#39;s look at an example usage of <code class="computeroutput">ad_page_contract</code>:</p><pre class="programlisting">

# /packages/acs-kernel/api-doc/www/package-view.tcl
ad_page_contract {
    version_id:integer
    public_p:optional
    kind
    { format "html" }
} {
    Shows APIs for a particular package.

    \@param version_id the ID of the version whose API to view.
    \@param public_p view only public APIs?
    \@param kind view the type of API to view. One of &lt;code&gt;procs_files&lt;/code&gt;,
        &lt;code&gt;procs&lt;/code&gt;, &lt;code&gt;content&lt;/code&gt;, &lt;code&gt;types&lt;/code&gt;, or
        &lt;code&gt;gd&lt;/code&gt;.
    \@param format the format for the documentation. One of &lt;code&gt;html&lt;/code&gt; or &lt;code&gt;xml&lt;/code&gt;.

    \@author Jon Salz (jsalz\@mit.edu)
    \@creation-date 3 Jul 2000
    \@cvs-id $&zwnj;Id$
}

</pre><p>Note that:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>
<span class="strong"><strong>By convention, <code class="computeroutput">ad_page_contract</code> should be preceded by a
comment line containing the file&#39;s path</strong></span>. The
comment is on line 1, and the contract starts on line 2.</p></li><li class="listitem"><p>
<span class="strong"><strong><code class="computeroutput">ad_page_contract</code></strong></span>'s
first argument is the list of expected arguments from the HTTP
query (<code class="computeroutput">version_id</code>, <code class="computeroutput">public_p</code>, <code class="computeroutput">kind</code>, and <code class="computeroutput">format</code>). Like <code class="computeroutput">ad_page_variables</code>, <code class="computeroutput">ad_page_contract</code> sets the corresponding Tcl
variables when the page is executed.</p></li><li class="listitem"><p>
<span class="strong"><strong>Arguments can have
defaults</strong></span>, specified using the same syntax as in the
Tcl <code class="computeroutput">proc</code> (a two-element list
where the first element is the parameter name and the second
argument is the default value).</p></li><li class="listitem">
<p>
<span class="strong"><strong>Arguments can have
flags</strong></span>, specified by following the name of the query
argument with a colon and one or more of the following strings
(separated by commas):</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>
<span class="strong"><strong><code class="computeroutput">optional</code></strong></span>: the query
argument doesn&#39;t need to be provided; if it&#39;s not, the
variable for that argument simply won&#39;t be set. For instance,
if I call the script above without a <code class="computeroutput">public_p</code> in the query, then in the page
body <code class="computeroutput">[info exists public_p]</code>
will return 0.</p></li><li class="listitem"><p>
<span class="strong"><strong><code class="computeroutput">integer</code></strong></span>: the argument must
be an integer (<code class="computeroutput">ad_page_contract</code>
will fail and display and error if not). This flag, like the next,
is intended to prevent clients from fudging query arguments to
trick scripts into executing arbitrary SQL.</p></li><li class="listitem"><p>
<span class="strong"><strong><code class="computeroutput">sql_identifier</code></strong></span>: the
argument must be a SQL identifier (i.e., <code class="computeroutput">[string is wordchar $the_query_var]</code> must
return true).</p></li><li class="listitem"><p>
<span class="strong"><strong><code class="computeroutput">trim</code></strong></span>: the argument will be
[string trim]'ed.</p></li><li class="listitem">
<p>
<span class="strong"><strong><code class="computeroutput">multiple</code></strong></span>: the argument may
be specified arbitrarily many times in the query string, and the
variable will be set to a list of all those values (or an empty
list if it&#39;s unspecified). This is analogous to the
<code class="computeroutput">-multiple-list</code> flag to
<code class="computeroutput">ad_page_variables</code>, and is
useful for handling form input generated by <code class="computeroutput">&lt;SELECT MULTIPLE&gt;</code> tags and
checkboxes.</p><p>For instance, if <code class="computeroutput">dest_user_id:multiple</code> is specified in the
contract, and the query string is</p><pre class="programlisting">

?dest_user_id=913&amp;dest_user_id=891&amp;dest_user_id=9

</pre><p>then <code class="computeroutput">$dest_user_id</code> is set to
<code class="computeroutput">[list 913 891 9]</code>.</p>
</li><li class="listitem">
<p>
<span class="strong"><strong><code class="computeroutput">array</code></strong></span>: the argument may be
specified arbitrarily many times in the query string, with
parameter names with suffixes like <code class="computeroutput">_1</code>, <code class="computeroutput">_2</code>,
<code class="computeroutput">_3</code>, etc. The variable is set to
a list of all those values (or an empty list if none are
specified).</p><p>For instance, if <code class="computeroutput">dest_user_id:array</code> is specified in the
contract, and the query string is</p><pre class="programlisting">

?dest_user_id_0=913&amp;dest_user_id_1=891&amp;dest_user_id_2=9

</pre><p>then <code class="computeroutput">$dest_user_id</code> is set to
<code class="computeroutput">[list 913 891 9]</code>.</p>
</li>
</ul></div>
</li><li class="listitem">
<p>
<span class="strong"><strong>You can provide structured,
HTML-formatted documentation for your contract</strong></span>.
Note that format is derived heavily from Javadoc: a general
description of the script&#39;s functionality, followed optionally
by a series of named attributes tagged by at symbols (<code class="computeroutput">\@</code>). You are encouraged to provide:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>A description of the functionality of the page. If the
description contains more than one sentence, the first sentence
should be a brief summary.</p></li><li class="listitem">
<p>A <span class="strong"><strong><code class="computeroutput">\@param</code></strong></span> tag for each
allowable query argument. The format is</p><pre class="programlisting">

\@param <span class="emphasis"><em>parameter-name</em></span><span class="emphasis"><em>description...</em></span>
</pre>
</li><li class="listitem"><p>An <span class="strong"><strong><code class="computeroutput">\@author</code></strong></span> tag for each
author. Specify the author&#39;s name, followed his or her email
address in parentheses.</p></li><li class="listitem"><p>A <span class="strong"><strong><code class="computeroutput">\@creation-date</code></strong></span> tag
indicating when the script was first created.</p></li><li class="listitem"><p>A <span class="strong"><strong><code class="computeroutput">\@cvs-id</code></strong></span> tag containing the
page&#39;s CVS identification string. Just use <code class="computeroutput">$&zwnj;Id: tcl-documentation.html,v 1.2 2000/09/19
07:22:35 ron Exp $</code> when creating the file, and CVS will
substitute an appropriate string when you check the file in.</p></li>
</ul></div><p>These <code class="computeroutput">\@</code> tags are optional,
but highly recommended!</p>
</li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="tcl-doc-ad-library" id="tcl-doc-ad-library"></a>ad_library</h3></div></div></div><p>
<code class="computeroutput">ad_library</code> provides a
replacement for the informal documentation (described above) found
at the beginning of every Tcl page. Instead of:</p><pre class="programlisting">

# /packages/acs-kernel/00-proc-procs.tcl
#
# Routines for defining procedures and libraries of procedures (-procs.tcl files).
#
# jsalz\@mit.edu, 7 Jun 2000
#
# $&zwnj;Id: tcl-doc.xml,v 1.7 2006/07/17 05:38:38 torbenb Exp $

</pre><p>you&#39;ll now write:</p><pre class="programlisting">

# /packages/acs-kernel/00-proc-procs.tcl
ad_library {

    Routines for defining procedures and libraries of procedures (&lt;code&gt;-procs.tcl&lt;/code&gt;
    files).

    \@creation-date 7 Jun 2000
    \@author Jon Salz (jsalz\@mit.edu)
    \@cvs-id $&zwnj;Id$

}

</pre><p>Note that format is derived heavily from Javadoc: a general
description of the script&#39;s functionality, followed optionally
by a series of named attributes tagged by at symbols (<code class="computeroutput">\@</code>). HTML formatting is allowed. You are
encouraged to provide:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>An <span class="strong"><strong><code class="computeroutput">\@author</code></strong></span> tag for each
author. Specify the author&#39;s name, followed his or her email
address in parentheses.</p></li><li class="listitem"><p>A <span class="strong"><strong><code class="computeroutput">\@creation-date</code></strong></span> tag
indicating when the script was first created.</p></li><li class="listitem"><p>A <span class="strong"><strong><code class="computeroutput">\@cvs-id</code></strong></span> tag containing the
page&#39;s CVS identification string. Just use <code class="computeroutput">$&zwnj;Id: tcl-documentation.html,v 1.2 2000/09/19
07:22:35 ron Exp $</code> when creating the file, and CVS will
substitute an appropriate string when you check the file in.</p></li>
</ul></div><div class="cvstag">($&zwnj;Id: tcl-doc.xml,v 1.7 2006/07/17 05:38:38
torbenb Exp $)</div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="rp-design" leftLabel="Prev" leftTitle="Request Processor Design"
		    rightLink="bootstrap-acs" rightLabel="Next" rightTitle="Bootstrapping OpenACS"
		    homeLink="index" homeLabel="Home" 
		    upLink="kernel-doc" upLabel="Up"> 
		