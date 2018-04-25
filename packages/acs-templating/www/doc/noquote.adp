
<property name="context">{/doc/acs-templating {ACS Templating}} {HTMLQuoting as Part of the Templating System -
Requirements}</property>
<property name="doc(title)">HTMLQuoting as Part of the Templating System -
Requirements</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="" leftLabel=""
			title=""
			rightLink="" rightLabel="">
		    <div class="sect1" lang="en">
<div class="titlepage">
<div><h2 class="title" style="clear: both">
<a name="noquote-requirements" id="noquote-requirements"></a>HTMLQuoting as
Part of the Templating System - Requirements</h2></div><hr>
</div><div class="sect2" lang="en">
<div class="titlepage"><div><h3 class="title">
<a name="The_Templating_System" id="The_Templating_System"></a>The Templating System.</h3></div></div><p>Templating systems, as deployed by most web software, serve to
distinguish the programming logic of the system from the
presentation that is output to the user.</p><p>Before introduction of a templating systems to ACS, pages were
built by outputting HTML text directly from Tcl code. Therefore it
was hard for a designer or a later reviewer to change the
appearance of the page. "Change the color of the table? How do
I do that when I cannot even find the body tag?" At this point
some suggest to embed Tcl code in the document rather than the
other way around, like PHP does. But it doesn&#39;t solve the
problem, because the code is still tightly coupled with the markup,
requiring programmer-level understanding for every change. The only
workable solution is to try to uncouple the presentation from the
design as much as possible.</p><p>ACS 4.0 addressed the problem by introducing a custom-written
templating system loosely based on the already-present capabilities
of the AolServer, the ADP pages. Unlike the ADP system, which
allowed the coder to register his own tags to encapsulate
often-used functionality, the new templating system came with a
pre-programmed set of tags that performed the basic transformations
needed to process the page, and some additional value.</p><p>Comparing ACS templating to other templating systems, it is my
impression that the former was designed to be useful in real life
rather than minimalistic -- which is only makes sense given the
tight deadlines most ArsDigita projects have to face. Besides the
if tag, multiple tag and \@variable\@ variable substitution, which
are sufficient to implement any template-based page, it also
includes features like including one template in another,
customizing site- or module-wide look using the master templates,
directly importing query results to the template, facilities for
building grid-tables, and more. This utilitarian approach to
templating urges us to consider the quoting issues as integral part
of the system.</p>
</div><div class="sect2" lang="en">
<div class="titlepage"><div><h3 class="title">
<a name="Quoting" id="Quoting"></a>Quoting.</h3></div></div><p>In the context of HTML, we define quoting as transforming text
in such a way that the HTML-rendered version of the transformed
text is identical to the original text. Thus one way to quote the
text "&lt;i&gt;" is to transform it to
"&amp;lt;i&amp;gt;". When a browser renders the
transformed text, entities &amp;lt; and &amp;gt; are converted back
to &lt; and &gt;, which makes the rendered version of the
transformation equal to the original.</p><p>The easiest way to guarantee correct transformation in all cases
is to "escape" ("quote") all the characters
that HTML considers special. In the minimalistic case, it is enough
to transform &amp;, &lt;, and &gt; into their quoted equivalents,
&amp;amp;, &amp;lt;, and &amp;gt; respectively. For additional
usefulness in quoted fields, it&#39;s a good idea to also quote
double and single quotes into &amp;quot; and &amp;#39;
respectively.</p><p>All of this assumes that the text to be quoted is not meant to
be rendered as HTML in the first place. So if your text contains
"&lt;i&gt;word&lt;/i&gt;", and you expect the word to
show up in italic, you should not quote that entire string.
However, if word in fact comes from the database and you don&#39;t
want it to, for instance, close the &lt;i&gt; behind your back, you
should quote it, and then enclose it between &lt;i&gt; and
&lt;/i&gt;.</p><p>The ACS has a procedure that performs HTML quoting,
ns_quotehtml. It accepts the string that needs to be quoted, and
returns the quoted string. In ACS 3.x, properly written code was
expected to call ns_quotehtml every time it published a string to a
web page. For example:</p><pre class="programlisting">
doc_body_append "&lt;ul&gt;\n"
set db [ns_db gethandle]
set selection [ns_db select $db {SELECT name FROM bboard_forums}]
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    doc_body_append "&lt;li&gt;Forum: &lt;tt&gt;[ns_quotehtml $name]&lt;/tt&gt;\n"
}
doc_body_append "&lt;/ul&gt;\n"
</pre><p>Obviously, this was very error-prone, and more often than not,
the programmers would forget to quote the variables that come from
the database or from the user. This would "usually" work,
but in some cases it would lead to broken pages and even pose a
security problem. For instance, one could imagine a
mathematicians' forum being named "0 &lt; 1", or an
HTML designers' forum being named "The Woes of
&lt;h1&gt;".</p><p>In some cases the published variable must not be quoted.
Examples for that are the bboard postings that are posted in HTML,
or variables containing the result of export_form_vars. All in all,
the decision about when to quote had to be made by the programmer
on a case-by-case basis, and many programmers simply enjoyed the
issue because the resulting code happened to work in 95% of the
cases.</p><p>Then came ACS 4. One hoped that ACS 4, with its advanced
templating system, would provide an easy and obvious solution for
the (lack of) quoting problem. It turned out that this did not
happen, partly because no easy solution exists, and partly because
the issue was ignored or postponed.</p><p>Let&#39;s review the ACS 3.x code from above. The most important
change is that it comes in two parts: the presentation template,
and the programming logic code. The template will look like
this:</p><pre class="programlisting">
&lt;ul&gt;
  &lt;multiple name=forums&gt;
    &lt;li&gt;Forum: &lt;tt&gt;\@forums.name\@&lt;/tt&gt;
  &lt;/multiple&gt;
&lt;/ul&gt;
</pre><p>Once you understand the (simple) workings of the multiple tag,
this version strikes you as much more readable than the old one.
But we&#39;re not done yet: we need to write the Tcl code that
grabs forum names from the database. The db_multirow proc is
designed exactly for this; it retrieves rows from the database and
assigns variables from each row to template variables in each pass
of a multiple of our choice.</p><pre class="programlisting">
db_multirow forums get_forum_names {
  SELECT name FROM forums
}
</pre><p>At this point the careful reader will wonder at which point the
forum name gets quoted, and if so, how does the templating system
know whether the forum name needs to be quoted or not? The answer
is amazingly blunt: no quoting happens anywhere in the process. If
a forum name contains HTML special characters, you have a
problem.</p><p>There are two remedies for this situation, and neither is
particularly appealing. One can rewrite the nice db_multirow with a
db_foreach loop, manually create a multirow, and feed it the quoted
data in the loop. That is ugly and error-prone because it is more
typing and it requires you to explicitly name the variables you
wish to export at several points. It is exactly the kind of ugly
code that db_multirow was designed to avoid.</p><p>The alternative approach means less typing, but it&#39;s even
uglier in its own subtle way. The trick is to remember that our
templating still supports all the ADP features, including embedding
Tcl code in the template. Thus instead of referring to the multirow
variable with the \@forums.name\@ variable substitutions, we use
&lt;%= [ns_quotehtml \@forums.name\@] %&gt;. This
works correctly, but obviously breaks the abstraction barrier
between ADP and Tcl syntaxes. The practical result of breaking the
abstraction is that every occurrence of Tcl code in an ADP template
will have to be painstakingly reviewed and converted once ADPs
start being invoked by Java code rather than Tcl.</p><p>At this point, most programmers simply give up and <span class="emphasis"><em>don&#39;t quote their variables at all</em></span> .
Quoting is handled only in the areas where it is really crucial and
where not handling it would quote immediate and visible breakage,
such as in the case of displaying the bodies of bboard articles.
This is not exaggeration; it has been proven by auditing the ACS
4.0, both manually and through grepping for ns_quotehtml.
Strangely, this otherwise sad fact allows us to deploy a very
radical but much more robust solution to the problem.</p>
</div><div class="sect2" lang="en">
<div class="titlepage"><div><h3 class="title">
<a name="Quote_Always,_Except_When_Told_Not_to" id="Quote_Always,_Except_When_Told_Not_to"></a>Quote Always, Except
When Told Not to.</h3></div></div><p>At the time when we came to realize how serious the quoting
deficiencies of ACS 4.0 were, we were about two weeks away from the
release of a project for the German Bank. There was simply no time
to hunt all the places where a variable needs to be quoted and
implement one of the above quoting tricks.</p><p>While examining the ADPs, we noticed that most substituted
variable fall into one of three categories:</p><div class="orderedlist"><ol type="1">
<li><p>Those that need to be quoted -- names and descriptions of
objects, and in general stuff that ultimately comes from the
user.</p></li><li><p>Those for which it doesn&#39;t make a difference whether they
are quoted or not -- e.g. all the database IDs.</p></li><li><p>Those that must not be quoted -- e.g. exported form vars stored
to a variable.</p></li><li><p>Finally we also remembered the fact that almost none of the
variables are quoted in the current source base.</p></li>
</ol></div><p>Our reasoning went further: if it is a fact that most variables
are not quoted, and if the majority of variables either require
quoting or are not harmed by it, then we are in a much better
position if we make the templating system <span class="emphasis"><em>quote all variables</em></span> by default! That way
the variables from the first and the second category will be
handled correctly, and the variables from the third category will
need to be marked as noquote to function correctly. But even those
should not be a problem, because HTML code that ends up quoted in
the page is immediately visible, and all you need to do to fix it
is add the marker.</p><p>We decided to test whether the idea will work by attempting to
convert our system to work that way. I spent several minutes making
the change to the templating system. Then we went through all the
ADPs and replaced the instances of \@foo\@ where foo contained HTML
code with \@foo;noquote\@.</p><p>The change took two people less than one day for the system that
consisted of core ACS 4.0.1, and modules bboard, news, chat, and
bookmarks. (We were also doing other things, so it&#39;s hard to
measure correctly.) During two of the following days, we would find
a broken page from time to time, typically by spotting the
obviously visible HTML markup. Such a page would get fixed it in a
matter of seconds by appending ;noquote to the name of the
offending variable.</p><p>We launched successfully within schedule.</p>
</div><div class="sect2" lang="en">
<div class="titlepage"><div><h3 class="title">
<a name="Porting_the_quoting_changes_to_the_ACS" id="Porting_the_quoting_changes_to_the_ACS"></a>Porting the quoting
changes to the ACS.</h3></div></div><p>After some discussion, it was decided that these changes will be
included into the next ACS release. Since the change is
incompatible, it will be announced to module owners and the general
public. Explanation on how to port your existing modules and the
"gotchas" that one can expect follows in a <a href="">separate document</a> .</p>
&gt;
<p><span class="emphasis"><em><a href="mailto:hniksic\@xemacs.org" target="_top">Hrvoje Niksic</a></em></span></p>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="" leftLabel="" leftTitle=""
			rightLink="" rightLabel="" rightTitle=""
			homeLink="" homeLabel="" 
			upLink="" upLabel=""> 
		    