
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {ACS File Naming and Formatting Standards}</property>
<property name="doc(title)">ACS File Naming and Formatting Standards</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="eng-standards-constraint-naming" leftLabel="Prev"
		    title="
Chapter 12. Engineering Standards"
		    rightLink="eng-standards-plsql" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="eng-standards-filenaming" id="eng-standards-filenaming"></a>ACS
File Naming and Formatting Standards</h2></div></div></div><div class="authorblurb">
<p>By Michael Yoon and Aurelius Prochazka</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><p>To ensure consistency (and its collateral benefit,
maintainability), we define and adhere to standards in the
following areas:</p><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="eng-standards-filenaming-nomenclature" id="eng-standards-filenaming-nomenclature"></a>File
Nomenclature</h3></div></div></div><p>Usually we organize our files so that they mainly serve one of
the following three purposes:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>displaying objects and their properties</p></li><li class="listitem"><p>manipulating or acting on objects in some way (by creating,
editing, linking, etc)</p></li><li class="listitem"><p>housing procedures, packages, data models and other prerequisite
code Essentially, we want our files named in a fashion that
reflects their purpose.</p></li>
</ul></div><p>Under the page root:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p>For naming files that enable a specific action on an object, use
this format:</p><div class="blockquote"><blockquote class="blockquote"><p><span class="emphasis"><em><code class="computeroutput">object-verb.extension</code></em></span></p></blockquote></div><p>For example, the page to erase a user&#39;s portrait from the
database is <code class="computeroutput">/admin/users/portrait-erase.tcl</code>.</p>
</li><li class="listitem">
<p>However, modules typically deal with only one primary type of
object - e.g., the Bookmarks module deals mainly with bookmarks -
and so action-type files in modules don&#39;t need to be specified
by the object they act on. Example: the user pages for the
Bookmarks module live in the <code class="computeroutput">/bookmarks/</code> directory, and so there is no
need to name the bookmark editing page with a redundant url:
<code class="computeroutput">/bookmarks/bookmark-edit.tcl</code>.
Instead, we omit the object type, and use this convention:</p><div class="blockquote"><blockquote class="blockquote"><p><span class="emphasis"><em><code class="computeroutput">verb.extension</code></em></span></p></blockquote></div><p>Thus, the page to edit a bookmark is <code class="computeroutput">/bookmarks/edit.tcl</code>.</p>
</li><li class="listitem">
<p>For naming files that display the properties of a primary object
- such as the bookmark object within the bookmark module - use this
convention:</p><div class="blockquote"><blockquote class="blockquote"><p><code class="computeroutput">one.extension</code></p></blockquote></div><p>For example, the page to view one bookmark is <code class="computeroutput">/bookmarks/one.tcl</code>. Note that no verb is
necessary for display-type files.</p>
</li><li class="listitem">
<p>Otherwise, if the object to be displayed is not the primary
feature of a module, simply omit the verb and use the object
name:</p><div class="blockquote"><blockquote class="blockquote"><p><span class="emphasis"><em><code class="computeroutput">object.extension</code></em></span></p></blockquote></div><p>For example, the page to view the properties of an ecommerce
product is <code class="computeroutput">/ecommerce/product.tcl</code>.</p>
</li><li class="listitem">
<p>For naming files in a page flow, use the convention:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>
<span class="emphasis"><em><code class="computeroutput">foobar.extension</code></em></span> (Step 1)</p></li><li class="listitem"><p>
<span class="emphasis"><em><code class="computeroutput">foobar-2.extension</code></em></span> (Step 2)</p></li><li class="listitem"><p>...</p></li><li class="listitem"><p>
<span class="emphasis"><em><code class="computeroutput">foobar-N.extension</code></em></span> (Step N)</p></li>
</ul></div><p>where <span class="emphasis"><em><code class="computeroutput">foobar</code></em></span> is determined by the
above rules.</p><p>Typically, we use a three-step page flow when taking user
information:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>Present a form to the user</p></li><li class="listitem"><p>Present a confirmation page to the user</p></li><li class="listitem"><p>Perform the database transaction, then redirect</p></li>
</ol></div>
</li><li class="listitem">
<p>Put data model files in <code class="computeroutput">/www/doc/sql</code>, and name them for the modules
towards which they are used:</p><div class="blockquote"><blockquote class="blockquote"><p>
<span class="emphasis"><em><code class="computeroutput">module</code></em></span><code class="computeroutput">.sql</code>
</p></blockquote></div>
</li>
</ul></div><p>In the Tcl library directory:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p>For files that contain module-specific procedures, use the
convention:</p><div class="blockquote"><blockquote class="blockquote"><p>
<span class="emphasis"><em><code class="computeroutput">module</code></em></span><code class="computeroutput">-procs.tcl</code>
</p></blockquote></div>
</li><li class="listitem">
<p>For files that contain procedures that are part of the core ACS,
use the convention:</p><div class="blockquote"><blockquote class="blockquote"><p>
<code class="computeroutput">ad-</code><span class="emphasis"><em>description</em></span><code class="computeroutput">-procs.tcl</code>
</p></blockquote></div>
</li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="eng-standards-filenaming-urls" id="eng-standards-filenaming-urls"></a>URLs</h3></div></div></div><p>File names also appear <span class="emphasis"><em>within</em></span> pages, as linked URLs and form
targets. When they do, always use <a class="ulink" href="rp-design" target="_top">abstract URLs</a> (e.g., <code class="computeroutput">user-delete</code> instead of <code class="computeroutput">user-delete.tcl</code>), because they enhance
maintainability.</p><p>Similarly, when linking to the index page of a directory, do not
explicitly name the index file (<code class="computeroutput">index.tcl</code>, <code class="computeroutput">index.adp</code>, <code class="computeroutput">index.html</code>, etc.). Instead, use just the
directory name, for both relative links (<code class="computeroutput">subdir/</code>) and absolute links (<code class="computeroutput">/top-level-dir/</code>). If linking to the
directory in which the page is located, use the empty string
(<code class="computeroutput">""</code>), which browsers
will resolve correctly.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="eng-standards-filenaming-headers" id="eng-standards-filenaming-headers"></a>File Headers and Page
Input</h3></div></div></div><p>Include the appropriate standard header in all scripts. The
first line should be a comment specifying the file path relative to
the ACS root directory. e.g.</p><div class="blockquote"><blockquote class="blockquote"><p><code class="computeroutput"># /www/index.tcl</code></p></blockquote></div><p>or</p><div class="blockquote"><blockquote class="blockquote"><p><code class="computeroutput"># /tcl/module-defs.tcl</code></p></blockquote></div><p>For static content files (html or adp), include a CVS
identification tag as a comment at the top of the file, e.g.</p><pre class="programlisting">
&lt;!-- file-standards.html,v 1.2 2000/09/19 07:22:45 ron Exp --&gt;
</pre><p>In addition, all static HTML files, documentation and other
pages should have a visible CVS ID stamp, at least during
development. These can be removed at release times. This should
take the form of a line like this:</p><pre class="programlisting">
&lt;p&gt;
Last Modified: file-standards.html,v 1.2 2000/09/19 07:22:45 ron Exp
&lt;/p&gt;
</pre><p>This can be at the top or bottom of the file.</p><div>Using ad_page_contract</div><p>For non-library Tcl files (those not in the private Tcl
directory), use <a class="link" href="tcl-doc" title="ad_page_contract"><code class="computeroutput">ad_page_contract</code></a> after the file path
comment (this supersedes set_the_usual_form_variables and
ad_return_complaint). Here is an example of using ad_page_contract,
which serves both documentation and page input validation
purposes:</p><pre class="programlisting">
# www/register/user-login-2.tcl

ad_page_contract {
    Verify the user&#39;s password and issue the cookie.
    
    \@param user_id The user&#39;s id in users table.
    \@param password_from_from The password the user entered.
    \@param return_url What url to return to after successful login.
    \@param persistent_cookie_p Specifies whether a cookie should be set to keep the user logged in forever.
    \@author John Doe (jdoe\@example.com)
    \@cvs-id file-standards.html,v 1.2 2000/09/19 07:22:45 ron Exp
} {
    user_id:integer,notnull
    password_from_form:notnull
    {return_url {[ad_pvt_home]}}
    {persistent_cookie_p f}
}
</pre><p>Salient features of <code class="computeroutput">ad_page_contract</code>:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>A mandatory documentation string is the first argument. This has
the standard form with javadoc-style \@author, \@cvs-id, etc, and
should contain a short description of the received variables and
any necessary explanations.</p></li><li class="listitem"><p>The second argument specifies the page inputs. The syntax for
switches/flags (e.g. multiple-list, array, etc.) uses a colon (:)
followed by any number of flags separated by commas (,), e.g.
<code class="computeroutput">foo:integer,multiple,trim</code>. In
particular, <code class="computeroutput">multiple</code> and
<code class="computeroutput">array</code> are the flags that
correspond to the old <code class="computeroutput">ad_page_variables</code> flags.</p></li><li class="listitem"><p>There are new flags: <code class="computeroutput">trim</code>,
<code class="computeroutput">notnull</code> and <code class="computeroutput">optional</code>. They do what you&#39;d expect;
values will not be trimmed, unless you mark them for it; empty
strings are valid input, unless you specify notnull; and a
specified variable will be considered required, unless you declare
it optional.</p></li><li class="listitem"><p>
<code class="computeroutput">ad_page_contract</code> can do
validation for you: the flags <code class="computeroutput">integer</code> and <code class="computeroutput">sql_identifier</code> will make sure that the
values supplied are integers/sql_identifiers. The <code class="computeroutput">integer</code> flag will also trim leading zeros.
Note that unless you specify <code class="computeroutput">notnull</code>, both will accept the empty
string.</p></li><li class="listitem"><p>Note that <code class="computeroutput">ad_page_contract</code>
does not generate QQvariables, which were automatically created by
ad_page_variables and set_the_usual_form_variables. The use of bind
variables makes such previous variable syntax obsolete.</p></li>
</ul></div><div>Using ad_library</div><p>For shared Tcl library files, use <a class="link" href="tcl-doc" title="ad_library"><code class="computeroutput">ad_library</code></a> after the file path comment.
Its only argument is a doc_string in the standard (javadoc-style)
format, like <code class="computeroutput">ad_page_contract</code>.
Don&#39;t forget to put the \@cvs-id in there. Here is an example of
using ad_library:</p><pre class="programlisting">
# tcl/wp-defs.tcl

ad_library {
    Provides helper routines for the Wimpy Point module.

    \@author John Doe (jdoe\@example.com)
    \@cvs-id file-standards.html,v 1.2 2000/09/19 07:22:45 ron Exp
}
</pre><div>Non-Tcl Files</div><p>For SQL and other non-Tcl source files, the following file
header structure is recommended:</p><pre class="programlisting">
-- <span class="emphasis"><em>path relative to the ACS root directory</em></span>
--
-- <span class="emphasis"><em>brief description of the file&#39;s purpose</em></span>
--
-- <span class="emphasis"><em>author</em></span>
-- <span class="emphasis"><em>created</em></span>
--
-- <a class="ulink" href="http://www.loria.fr/~molli/cvs/doc/cvs_12.html#SEC93" target="_top">$&zwnj;Id$</a>
</pre><p>Of course, replace "<code class="computeroutput">--</code>" with the comment delimiter
appropriate for the language in which you are programming.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="eng-standards-filenaming-pages" id="eng-standards-filenaming-pages"></a>Page Construction</h3></div></div></div><p>Construct the page as one Tcl variable (name it <code class="computeroutput">page_content</code>), and then send it back to the
browser with one call to <code class="computeroutput">doc_return</code>, which will call
db_release_unused_handles prior to executing ns_return, effectively
combining the two operations.</p><p>For example:</p><pre class="programlisting">
set page_content "<span class="emphasis"><em>Page Title</em></span>]

&lt;h2&gt;<span class="emphasis"><em>Page Title</em></span>&lt;/h2&gt;

&lt;hr&gt;

&lt;ul&gt;
"

db_foreach get_row_info {
    select row_information 
    from bar
} {
    append page_content "&lt;li&gt;<span class="emphasis"><em>row_information</em></span>\n"
}

append page_content "&lt;/ul&gt;

[ad_footer]"

doc_return 200 text/html $page_content
</pre><p>The old convention was to call <code class="computeroutput">ReturnHeaders</code> and then <code class="computeroutput">ns_write</code> for each distinct chunk of the
page. This approach has the disadvantage of tying up a scarce and
valuable resource (namely, a database handle) for an unpredictable
amount of time while sending packets back to the browser, and so it
should be avoided in most cases. (On the other hand, for a page
that requires an expensive database query, it&#39;s better to call
<code class="computeroutput">ad_return_top_of_page</code> first, so
that the user is not left to stare at an empty page while the query
is running.)</p><p>Local procedures (i.e., procedures defined and used only within
one page) should be prefixed with "<span class="emphasis"><em><code class="computeroutput">module_</code></em></span>" and should be
used rarely, only when they are exceedingly useful.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="eng-standards-filenaming-tcllib" id="eng-standards-filenaming-tcllib"></a>Tcl Library Files</h3></div></div></div><p>Further standards for Tcl library files are under discussion; we
plan to include naming conventions for procs.</p><div class="cvstag">($&zwnj;Id: filenaming.xml,v 1.7.2.3 2017/04/21
15:07:52 gustafn Exp $)</div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="eng-standards-constraint-naming" leftLabel="Prev" leftTitle="Constraint naming standard"
		    rightLink="eng-standards-plsql" rightLabel="Next" rightTitle="PL/SQL Standards"
		    homeLink="index" homeLabel="Home" 
		    upLink="eng-standards" upLabel="Up"> 
		