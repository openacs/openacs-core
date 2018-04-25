
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {How Internationalization/Localization works in
OpenACS}</property>
<property name="doc(title)">How Internationalization/Localization works in
OpenACS</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="i18n-overview" leftLabel="Prev"
			title="
Chapter 14. Internationalization"
			rightLink="i18n-convert" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="i18n-introduction" id="i18n-introduction"></a>How Internationalization/Localization
works in OpenACS</h2></div></div></div><p>This document describes how to develop internationalized OpenACS
packages, including writing new packages with internationalization
and converting old packages. Text that users might see is
"localizable text"; replacing monolingual text and
single-locale date/time/money functions with generic functions is
"internationalization"; translating first generation text
into a specific language is "localization." At a minimum,
all packages should be internationalized. If you do not also
localize your package for different locales, volunteers may use a
public "localization server" to submit suggested text.
Otherwise, your package will not be usable for all locales.</p><p>The main difference between monolingual and internationalized
packages is that all user-visible text in the code of an
internationalized package are coded as "message keys."
The message keys correspond to a message catalog, which contains
versions of the text for each available language. Script files
(.adp and .tcl and .vuh), database files (.sql), and APM parameters
are affected.</p><p>Other differences include: all dates read or written to the
database must use internationalized functions. All displayed dates
must use internationalized functions. All displayed numbers must
use internationalized functions.</p><p>Localizable text must be handled in ADP files, in Tcl files, and
in APM Parameters. OpenACS provides two approaches, message keys
and localized ADP files. For ADP pages which are mostly code,
replacing the message text with message key placeholders is
simpler. This approach also allows new translation in the database,
without affecting the file system. For ADP pages which are static
and mostly text, it may be easier to create a new ADP page for each
language. In this case, the pages are distinguished by a file
naming convention.</p><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="i18n-content" id="i18n-content"></a>User
Content</h3></div></div></div><p>OpenACS does not have a general system for supporting multiple,
localized versions of user-input content. This document currently
refers only to internationalizing the text in the package user
interface.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="i18n-locale-templates" id="i18n-locale-templates"></a>Separate Templates for each Locale</h3></div></div></div><p>If the request processor finds a file named <code class="computeroutput">filename.locale.adp</code>, where locale matches
the user&#39;s locale, it will process that file instead of
<code class="computeroutput">filename.adp</code>. For example, for
a user with locale <code class="computeroutput">tl_PH</code>, the
file <code class="computeroutput">index.tl_PH.adp</code>, if found,
will be used instead of <code class="computeroutput">index.adp</code>. The locale-specific file should
thus contain text in the language appropriate for that locale. The
code in the page, however, should still be in English. Message keys
are processed normally.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="i18n-message-catalog" id="i18n-message-catalog"></a>Message Catalogs</h3></div></div></div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="i18n-message-catalog-adps" id="i18n-message-catalog-adps"></a>Message Keys in Template Files (ADP
Files)</h4></div></div></div><p>Internationalizing templates is about replacing human readable
text in a certain language with internal message keys, which can
then be dynamically replaced with real human language in the
desired locale. Message keys themselves should be in ASCII English,
as should all code. Three different syntaxes are possible for
message keys.</p><p>"Short" syntax is the recommended syntax and should be
used for new development. When internationalizing an existing
package, you can use the "temporary" syntax, which the
APM can use to auto-generate missing keys and automatically
translate to the short syntax. The "verbose" syntax is
useful while developing, because it allows default text so that the
page is usable before you have done localization.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p>The <span class="strong"><strong>short</strong></span>:
<code class="computeroutput">#<em class="replaceable"><code>package_key.message_key</code></em>#</code>
</p><p>The advantage of the short syntax is that it&#39;s short.
It&#39;s as simple as inserting the value of a variable. Example:
<code class="computeroutput">#<em class="replaceable"><code>forum.title</code></em>#</code>
</p>
</li><li class="listitem">
<p>The <span class="strong"><strong>verbose</strong></span>:
<code class="computeroutput">&lt;trn key="<em class="replaceable"><code>package_key.message_key</code></em>"
locale="<em class="replaceable"><code>locale</code></em>"&gt;<em class="replaceable"><code>default text</code></em>&lt;/trn&gt;</code>
</p><p>The verbose syntax allows you to specify a default text in a
certain language. This syntax is not recommended anymore, but it
can be convenient for development, because it still works even if
you haven&#39;t created the message in the message catalog yet,
because what it&#39;ll do is create the message key with the
default text from the tag as the localized message. Example:
<span class="emphasis"><em>&lt;trn key="forum.title"
locale="en_US"&gt;Title&lt;/trn&gt;</em></span>
</p>
</li><li class="listitem">
<p>The <span class="strong"><strong>temporary</strong></span>:
<code class="computeroutput">&lt;#<em class="replaceable"><code>message_key</code></em><em class="replaceable"><code>original text</code></em>#&gt;</code>
</p><p>This syntax has been designed to make it easy to
internationalize existing pages. This is not a syntax that stays in
the page. As you&#39;ll see later, it&#39;ll be replaced with the
short syntax by a special feature of the APM. You may leave out the
message_key by writing an underscore (_) character instead, in
which case a message key will be auto-generated by the APM.
Example: <span class="emphasis"><em>&lt;_ Title&gt;</em></span>
</p>
</li>
</ul></div><p>We recommend the short notation for new package development.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="i18n-message-catalog-tcl" id="i18n-message-catalog-tcl"></a>Message Keys in Tcl Files</h4></div></div></div><p>In adp files message lookups are typically done with the syntax
<code class="computeroutput">\#package_key.message_key\#</code>. In
Tcl files all message lookups *must* be on either of the following
formats:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Typical static key lookup: <code class="computeroutput">[_
package_key.message_key]</code> - The message key and package key
used here must be string literals, they can&#39;t result from
variable evaluation.</p></li><li class="listitem"><p>Static key lookup with non-default locale: <code class="computeroutput">[lang::message::lookup $locale
package_key.message_key]</code> - The message key and package key
used here must be string literals, they can&#39;t result from
variable evaluation.</p></li><li class="listitem"><p>Dynamic key lookup: <code class="computeroutput">[lang::util::localize
$var_with_embedded_message_keys]</code> - In this case the message
keys in the variable <code class="computeroutput">var_with_embedded_message_keys</code> must appear
as string literals <code class="computeroutput">\#package_key.message_key\#</code> somewhere in
the code. Here is an example of a dynamic lookup: <code class="computeroutput">set message_key_array { dynamic_key_1
\#package_key.message_key1\# dynamic_key_2
\#package_key.message_key2\# } set my_text [lang::util::localize
$message_key_array([get_dynamic_key])]</code>
</p></li>
</ul></div><p>Translatable texts in page Tcl scripts are often found in page
titles, context bars, and form labels and options. Many times the
texts are enclosed in double quotes. The following is an example of
grep commands that can be used on Linux to highlight translatable
text in Tcl files:</p><pre class="screen">
# Find text in double quotes
<strong class="userinput"><code>find -iname '*.tcl'|xargs egrep -i '"[a-z]'</code></strong>

# Find untranslated text in form labels, options and values
<strong class="userinput"><code>find -iname '*.tcl'|xargs egrep -i '\-(options|label|value)'|egrep -v '&lt;#'|egrep -v '\-(value|label|options)[[:space:]]+\$[a-zA-Z_]+[[:space:]]*\\?[[:space:]]*$'</code></strong>

# Find text in page titles and context bars
<strong class="userinput"><code>find -iname '*.tcl'|xargs egrep -i 'set (title|page_title|context_bar) '|egrep -v '&lt;#'</code></strong>

# Find text in error messages
<strong class="userinput"><code>find -iname '*.tcl'|xargs egrep -i '(ad_complain|ad_return_error)'|egrep -v '&lt;#'</code></strong>
</pre><p>You may mark up translatable text in Tcl library files and Tcl
pages with temporary tags on the &lt;#key text#&gt; syntax. If you
have a sentence or paragraph of text with variables and or
procedure calls in it you should in most cases try to turn the
whole text into one message in the catalog (remember that
translators is made easier the longer the phrases to translate
are). In those cases, follow these steps:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>For each message call in the text, decide on a variable name and
replace the procedure call with a variable lookup on the syntax
%var_name%. Remember to initialize a Tcl variable with the same
name on some line above the text.</p></li><li class="listitem"><p>If the text is in a Tcl file you must replace variable lookups
(occurrences of $var_name or ${var_name}) with %var_name%</p></li><li class="listitem"><p>You are now ready to follow the normal procedure and mark up the
text using a tempoarary message tag (&lt;#_
text_with_percentage_vars#&gt;) and run the action replace tags
with keys in the APM.</p></li>
</ul></div><p>The variable values in the message are usually fetched with
upvar, here is an example from dotlrn: <code class="computeroutput">ad_return_complaint 1 "Error: A
[parameter::get -parameter classes_pretty_name] must have
&lt;em&gt;no&lt;/em&gt;[parameter::get -parameter
class_instances_pretty_plural] to be deleted"</code> was
replaced by: <code class="computeroutput">set subject
[parameter::get -localize -parameter classes_pretty_name] set
class_instances [parameter::get -localize -parameter
class_instances_pretty_plural] ad_return_complaint 1 [_
dotlrn.class_may_not_be_deleted]</code>
</p><p>This kind of interpolation also works in adp files where adp
variable values will be inserted into the message.</p><p>Alternatively, you may pass in an array list of the variable
values to be interpolated into the message so that our example
becomes:</p><pre class="screen"><strong class="userinput"><code>set msg_subst_list [list subject [parameter::get -localize -parameter classes_pretty_name] class_instances [parameter::get -localize -parameter class_instances_pretty_plural]]

ad_return_complaint 1 [_ dotlrn.class_may_not_be_deleted $msg_subst_list]
</code></strong></pre><p>When we were done going through the Tcl files we ran the
following commands to check for mistakes:</p><pre class="screen">
# Message tags should usually not be in curly braces since then the message lookup may not be
# executed then (you can usually replace curly braces with the list command). Find message tags 
# in curly braces (should return nothing, or possibly a few lines for inspection)
<strong class="userinput"><code>find -iname '*.tcl'|xargs egrep -i '\{.*&lt;#'</code></strong>

# Check if you&#39;ve forgotten space between default key and text in message tags (should return nothing)
<strong class="userinput"><code>find -iname '*.tcl'|xargs egrep -i '&lt;#_[^ ]'</code></strong>

# Review the list of Tcl files with no message lookups
<strong class="userinput"><code>for tcl_file in $(find -iname '*.tcl'); do egrep -L '(&lt;#|\[_)' $tcl_file; done</code></strong>
</pre><p>When you feel ready you may vist your package in the <a class="ulink" href="/acs-admin/apm" target="_top">package manager</a> and
run the action "Replace tags with keys and insert into
catalog" on the Tcl files that you&#39;ve edited to replace
the temporary tags with calls to the message lookup procedure.</p><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="i18n-date-time-number" id="i18n-date-time-number"></a>Dates, Times, and Numbers in Tcl
files</h5></div></div></div><p>Most date, time, and number variables are calculated in Tcl
files. Dates and times must be converted when stored in the
database, when retrieved from the database, and when displayed. All
dates are stored in the database in the server&#39;s timezone,
which is an APM Parameter set at <code class="computeroutput">/acs-lang/admin/set-system-timezone</code> and
readable at <code class="computeroutput">lang::system::timezone.</code>. When retrieved
from the database and displayed, dates and times must be localized
to the user&#39;s locale.</p>
</div>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="i18n-message-apm-params" id="i18n-message-apm-params"></a>APM Parameters</h4></div></div></div><p>Some parameters contain text that need to be localized. In this
case, instead of storing the real text in the parameter, you should
use message keys using the short notation above, i.e. <span class="strong"><strong>#<span class="emphasis"><em>package_key.message_key</em></span>#</strong></span>.</p><p>In order to avoid clashes with other uses of the hash character,
you need to tell the APM that the parameter value needs to be
localized when retrieving it. You do that by saying: <span class="strong"><strong>parameter::get -localize</strong></span>.</p><p>Here are a couple of examples. Say we have the following two
parameters, taken directly from the dotlrn package.</p><div class="informaltable"><table class="informaltable" cellspacing="0" border="1">
<colgroup>
<col class="c1"><col class="c2">
</colgroup><thead><tr>
<th>Parameter Name</th><th>Parameter Value</th>
</tr></thead><tbody>
<tr>
<td>class_instance_pages_csv</td><td>
<code class="computeroutput">#<em class="replaceable"><code>dotlrn.class_page_home_title</code></em>#</code>,Simple
2-Column;<code class="computeroutput">#<em class="replaceable"><code>dotlrn.class_page_calendar_title</code></em>#</code>,Simple
1-Column;<code class="computeroutput">#<em class="replaceable"><code>dotlrn.class_page_file_storage_title</code></em>#</code>,Simple
1-Column</td>
</tr><tr>
<td>departments_pretty_name</td><td><code class="computeroutput">#<em class="replaceable"><code>departments_pretty_name</code></em>#</code></td>
</tr>
</tbody>
</table></div><p>Then, depending on how we retrieve the value, here&#39;s what we
get:</p><div class="informaltable"><table class="informaltable" cellspacing="0" border="1">
<colgroup>
<col class="c1"><col class="c2">
</colgroup><thead><tr>
<th>Command used to retrieve Value</th><th>Retrieved Value</th>
</tr></thead><tbody>
<tr>
<td>parameter::get <span class="strong"><strong>-localize</strong></span> -parameter
class_instances_pages_csv</td><td>Kurs Startseite,Simple 2-Column;Kalender,Simple
1-Column;Dateien,Simple 1-Column</td>
</tr><tr>
<td>parameter::get <span class="strong"><strong>-localize</strong></span> -parameter
departments_pretty_name</td><td>Abteilung</td>
</tr><tr>
<td>parameter::get -parameter departments_pretty_name</td><td><code class="computeroutput">#<em class="replaceable"><code>departments_pretty_name</code></em>#</code></td>
</tr>
</tbody>
</table></div><p>The value in the rightmost column in the table above is the
value returned by an invocation of parameter::get. Note that for
localization to happen you must use the -localize flag.</p><p>The locale used for the message lookup will be the locale of the
current request, i.e. lang::conn::locale or ad_conn locale.</p><p>Developers are responsible for creating the keys in the message
catalog, which is available at <code class="computeroutput">/acs-lang/admin/</code>
</p>
</div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="i18n-overview" leftLabel="Prev" leftTitle="Internationalization and Localization
Overview"
			rightLink="i18n-convert" rightLabel="Next" rightTitle="How to Internationalize a
Package"
			homeLink="index" homeLabel="Home" 
			upLink="i18n" upLabel="Up"> 
		    