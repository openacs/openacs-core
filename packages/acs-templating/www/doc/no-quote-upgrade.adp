
<property name="context">{/doc/acs-templating {ACS Templating}} {Upgrading existing ADPs to noquote templating}</property>
<property name="doc(title)">Upgrading existing ADPs to noquote templating</property>
<master>
<h2>Upgrading existing ADPs to noquote templating</h2>
<h3>Introduction.</h3>

The variable substitution in the templating has been changed to
become more friendly towards quoting. The rationale for the change
and the definition of terms like <em>quoting</em>
 are present in
<a href="noquote">the quoting article</a>
. As it discusses these
concepts in some depths, we see no reason to repeat them here.
Instead, we will assume that you have read the previous article and
focus on the topic of this one: the changes you need to apply to
make your module conformant to the new quoting rules.
<p>This text is written as a result of our efforts to make the ACS
installation for the German Bank project work, therefore it is
based on field experience rather than academic discussion. We hope
you will find it useful.</p>
<h3>Recap of the Theory.</h3>

The change to the templating system can be expressed in one
sentence:
<blockquote>All variables are now quoted by default, except those
explicitly protected by <kbd>;noquote</kbd> or
<kbd>;literal;</kbd>.</blockquote>

This means that the only way your code can fail is if the new code
quotes a variable which is not meant to be quoted. Which is where
<kbd>;noquote</kbd>
 needs to be added. That&#39;s all porting
effort that is required. Actually, the variables are subject to
HTML-quoting and internationalization. The suffix
<kbd>;noquote</kbd>
 means that the variable&#39;s content will be
internationalized, but not HTML-quoted, while <kbd>;no18n</kbd>

means quote, but don&#39;t internationalize. Finally
<kbd>;literal</kbd>
 means: don&#39;t quote and don&#39;t
internationalize.
<p>This is not hard because most variables will not be affected by
this change. Most variables either need to be quoted (those
containing textual data that comes from the database or from the
user) or are unaffected by quoting (numerical database IDs, etc.)
The variables where this behavior is undesired are <strong>those
that contain HTML</strong> which is expected to be included as part
of the page, and <strong>those that are already quoted</strong> by
Tcl code. Such variables should be protected from quoting by the
<kbd>;noquote</kbd> modifier.</p>
<h3>The Most Common Cases.</h3>

The most common cases where you need to add <kbd>;noquote</kbd>
 to
the variable name are easy to recognize and identify.
<p>
<strong>Hidden form variables.</strong><br>
Also known as "hidden input fields", hidden form
variables are form fields with pre-defined values which are not
shown to the user. These days they are used for transferring
internal state across several form pages. In HTML, hidden form
variables look like this:</p>
<blockquote><pre>
&lt;form&gt;
  &lt;input name=var1 value="value1"&gt;
  &lt;input name=var2 value="value2"&gt;
  ... real form stuff ...
&lt;/form&gt;
      </pre></blockquote>

ACS has a convenience function for creating hidden form variables,
<kbd>export_form_vars</kbd>
. It accepts a list of variables and
returns the HTML code containing the hidden input tags that map
variable names to variable values, as found in the Tcl environment.
In that case, the Tcl code would set the HTML code to a variable:
<blockquote><pre>
set form_vars [export_vars -form {var1 var2}]
      </pre></blockquote>

The ADP will simply refer to the <kbd>form_vars</kbd>
 variable:
<blockquote><pre>
&lt;form&gt;
  \@form_vars\@              &lt;!-- WRONG!  Needs noquote --&gt;
  ... real form stuff ...
&lt;/form&gt;
      </pre></blockquote>

This will no longer work as intended because <kbd>form_vars</kbd>

will be, like any other variable, quoted, and the user will end up
seeing raw HTML text of the hidden variables. Even worse, the
browser will not be aware of these form fields, and the page will
not work. After protecting the variable with <kbd>;noquote</kbd>
,
everything works as expected:
<blockquote><pre>
&lt;form&gt;
  \@form_vars;noquote\@
  ... real form stuff ...
&lt;/form&gt;
      </pre></blockquote>
<p>
<strong>Snippets of HTML produced by Tcl code, a.k.a.
<em>widgets</em>
</strong>.<br>
Normally we try to fit all HTML code into the ADP template and have
the Tcl code handle the "logic" of the program. And yet,
sometimes pieces of relatively convoluted HTML need to be included
in many templates. In such cases, it makes sense to generate the
<em>widget</em> programmatically and include it into the template
as a variable. A typical widget is a date entry widget which
provides the user the input and selection boxes for year, month,
and day, all of which default to the current date.</p>
<p>Another example of widgets is the <em>context bar</em> often
found on top of ACS pgages.</p>
<p>Obviously, all widgets should be treated as HTML and therefore
adorned with the <kbd>;noquote</kbd> qualifier. This also assumes
that the routines that <em>build</em> the widget are correctly
written and that they will quote the <em>components</em> used to
build the widget.</p>
<p>
<strong>Pieces of text that are already quoted.</strong><br>
This quoting is usually part of a more general preparation for HTML
rendering of the text. For instance, a bboard posting can be either
HTML or text. If it is HTML, we transmit it as is; if not, we
perform quoting, word-wrapping, etc. In both cases it is obvious
that quoting performed by the templating system would be redundant,
so we must be careful to add <kbd>;noquote</kbd> to the ADP.</p>
<h3>The <kbd>property</kbd> and <kbd>include</kbd> Gotchas.</h3>

Transfer of parameters between included ADPs often requires manual
addition of <kbd>;noquote</kbd>
. Let&#39;s review why.
<p>The <kbd>property</kbd> tag is used to pass a piece of
information to the master template. This is used by the ADP whose
writer consciously chose to let the master template handle a
variable given by the Tcl code. Typically page titles, headings,
and context bars are handled this way. For example:</p>
<blockquote>
<strong>master:</strong><pre>
&lt;head&gt;
  &lt;title&gt;\@title\@&lt;/title&gt;
&lt;/head&gt;
&lt;body bgcolor="#ffffff"&gt;
  &lt;h1&gt;\@heading\@&lt;/h1&gt;
  &lt;slave&gt;
&lt;/body&gt;
      </pre><strong>slave:</strong><pre>
&lt;master&gt;
&lt;property name="title"&gt;\@title\@&lt;/property&gt;
&lt;property name="heading"&gt;\@title\@&lt;/property&gt;
...
      </pre>
</blockquote>

The obvious intention of the master is to allow its slave templates
to provide a "title" and a "heading" of the
page in a standardized fashion. The obvious intention of our slave
template is to allow its corresponding Tcl code to set a single
variable, <kbd>title</kbd>
, which will be used for both title and
heading. What&#39;s wrong with this code?
<p>The problem is that title gets quoted <em>twice</em>, once by
the slave template, and once by the master template. This is the
result of how the templating system works: <em>every</em>
occurrence of <kbd>\@<var>variable</var>\@</kbd> is converted to
<kbd>[ad_quotehtml $<var>variable</var>]</kbd>, even when it
is used only to set a property and you would expect the quoting to
be suppressed.</p>
<blockquote><font size="-1">Implementation note: Ideally, the
templating system should avoid this pitfall by quoting the variable
(or not) only once, at the point where the value is passed from the
Tcl code to the templating system. However, no such point in time
exists because what in fact happens is that the template gets
compiled into code that simply <em>takes</em> what it needs from
the environment and <em>then</em> does the quoting. Properties are
passed to the master so that all the property variables are shoved
into an environment; by the time the master template is executed,
all information on which variable came from where and whether it
might have already been quoted is lost.</font></blockquote>
<p>This occurrence is often referred to as <em>over-quoting</em>.
Over-quoting is sometimes hard to detect because things seem to
work fine in most cases. To notice the problem in the example above
(and in any other over-quoting example), the title needs to contain
one of the characters <kbd>&lt;</kbd>, <kbd>&gt;</kbd> or
<kbd>&amp;</kbd>. If it does, they will appear quoted to the user
instead of appearing as-is.</p>
<p>Over-quoting is resolved by adding <kbd>;noquote</kbd> to one of
the variables. We strongly recommend that you add
<kbd>;literal</kbd> inside the <kbd>property</kbd> tag rather than
in the master. The reason is that, first, it makes sense to do so
because conceptually the master is the one that "shows"
the variable, so it makes sense that it gets to quote it. Secondly,
a <kbd>property</kbd> tag is supposed to merely <em>transfer</em> a
piece of text to the master; it is much cleaner and more
maintainable if this transfer is defined to be non-lossy. This
becomes important in practice when there is a hierarchy of
<kbd>master</kbd> templates -- e.g. one for the package and one for
the whole site.</p>
<p>To reiterate, a bug-free version of the slave template looks
like this:</p>
<blockquote>
<strong>slave sans over-quoting:</strong><pre>
&lt;master&gt;
&lt;property name="doc(title)"&gt;\@title;literal\@&lt;/property&gt;
&lt;property name="heading"&gt;\@title;literal\@&lt;/property&gt;
...
      </pre>
</blockquote>
<p>The exact same problems when the <kbd>include</kbd> statement
passes some text. Here is an example:</p>
<blockquote>
<strong>Including template:</strong><pre>
&lt;include src="user-kick-form" id=\@kicked_id\@ reason=\@default_reason\@&gt;
      </pre><strong>Included template:</strong><pre>
&lt;form action="do-kick" method=POST&gt;
  Kick user \@name\@.&lt;br&gt;
  Reason: &lt;textarea name=reason&gt;\@reason\@&lt;/textarea&gt;&lt;br&gt;
  &lt;input type="submit" value="Kick"&gt;
&lt;/form&gt;
      </pre>
</blockquote>

Here an include statement is used to include an HTML form widget
parts of which are defined with Tcl variables <kbd>$id</kbd>
 and
<kbd>$default_reason</kbd>
 whose values presumably come from the
database.
<p>What happens is that <var>reason</var> that prefills the
<kbd>textarea</kbd> is over-quoted. The reasons are the same as in
the last example: it gets quoted once by the includer, and the
second time by the included page. The fix is also similar: when you
transfer non-constant text to an included page, make sure to add
<kbd>;literal</kbd>.</p>
<blockquote>
<strong>Including template, sans over-quoting:</strong><pre>
&lt;include src="user-kick-form" id=\@kicked_id;literal\@ reason=\@default_reason;literal\@&gt;
      </pre>
</blockquote>
<h3>Upgrade Overview.</h3>

Upgrading a module to handle the new quoting rules consists of
applying the process mentioned above to every ADP in the module.
Using the knowledge gained above, we can specify exactly what needs
to be done for each template. The items are sorted approximately by
frequency of occurrence of the problem.
<ol>
<li>Audit the template for variables that export form variables and
add <kbd>;noquote</kbd> to them.</li><li>More generally, audit the template for variables that are known
to contain HTML, e.g. those that contain widgets or HTML content
provided by the user. Add <kbd>;noquote</kbd> to them.</li><li>Add <kbd>;literal</kbd> to variables used inside the
<kbd>property</kbd> tag.</li><li>Add <kbd>;noquote</kbd> to textual variables whose values are
attributes to the <kbd>include</kbd> tag.</li><li>Audit the template for occurrences of
<kbd>&lt;%= [ns_quotehtml \@<var>variable</var>\@] =&gt;</kbd>
and replace them with <kbd>\@<var>variable</var>\@</kbd>.</li><li>Audit the Tcl code for occurrences of <kbd>ns_quotehtml</kbd>.
If it is used to build an HTML component, leave it, but take note
of the variable the result gets saved to. Otherwise, remove the
quoting.</li><li>Add <kbd>;noquote</kbd> to the "HTML component"
variables noted in the previous step.</li>
</ol>

After that, test that the template behaves as it should, and
you&#39;re done.
<h3>Testing.</h3>

Fortunately, most of the problems with automatic quoting are very
easy to diagnose. The most important point for testing is that it
covers as many cases as possible: ideally testing should cover all
the branches in all the templates. But regardless of the quality of
your coverage, it is important to know how to conduct proper
testing for the quoting changes. Here are the cases you need to
watch out for.
<ul>
<li>
<strong>HTML junk appearing in the page.</strong><br>
Literal HTML visible to the user typically comes from an
"<kbd>export_form_vars</kbd>" or a widget variable that
lacks <kbd>;noquote</kbd>. To fix the problem, simply add
<kbd>;noquote</kbd> to the variable.</li><li>
<strong>Over-quoting and under-quoting.</strong><br>
To detect quoting defects, you need to assume an active role in
naming your objects. The best way to do it is to create objects
(bboard forums, messages, news items, etc.) with names that contain
the representation of an entity, e.g.
"<kbd>&amp;copy;</kbd>". This looks like the copyright
SGML entity, and intentionally so. The testing consists of checking
that the browser prints exactly what you typed in as the name. Thus
if your forum/message/etc. is listed as
"<kbd>&amp;copy;</kbd>", everything is OK. If it is
listed as "<kbd>&amp;amp;copy;</kbd>", it means that the
string was quoted twice, i.e. over-quoted. Finally, if the entity
is interpreted (shown as ©), it means that the string lacks
quoting, i.e. it is under-quoted.
<p>To get rid of over-quoting, make sure that the variables
don&#39;t get quoted in <em>transport</em>, such as in the
<kbd>property</kbd> tag or as an attribute of the
<kbd>include</kbd> tag. Also, make sure that your Tcl code is not
quoting the variable name.</p><p>To get rid of under-quoting, make sure that your variable gets
quoted exactly once. This can be achieved either by removing a
(presumably overzealous) <kbd>;noquote</kbd> or by quoting the
string from Tcl. The latter is necessary when building HTML
components, such as a context bar, from strings that come from the
database or from the user.</p>
</li>
</ul>
<hr>
<address><a href="mailto:hniksic\@xemacs.org">Hrvoje
Niksic</a></address>
<!-- Created: Mon Feb 26 12:12:00 CET 2001 --><!-- hhmts start -->Last modified: Thu Aug 20 18:38:05 CEST 2015 
<!-- hhmts end -->