
<property name="context">{/doc/acs-lang {ACS Localization}} {ACS 4 Globalization Detailed Design}</property>
<property name="doc(title)">ACS 4 Globalization Detailed Design</property>
<master>
<h2>ACS 4 Globalization Detailed Design</h2>

by Henry Minsky
<h3>I. Essentials</h3>

When applicable, each of the following items should receive its own
link:
<ul>
<li>User directory: none</li><li>ACS administrator: acs-lang</li><li>Subsite administrator directory: none</li><li>Tcl script directory: /api-doc</li><li>PL/SQL file:</li><li>Data model:</li><li><a href="i18n-requirements">Requirements document</a></li>
</ul>
<h3>II. Introduction</h3>
<h3>III. Historical Considerations</h3>
<h3>V. Design Tradeoffs</h3>
<ul>
<li>Performance: availability and efficiency
<p>For Internationalization to be effective, it needs to be
integrated into every module in the system. Thus making the
overhead as low as possible is a priority, otherwise developers
will be reluctant to use it in their code.</p><p>Wherever possible, caching in AOLserver shared memory is used to
remove the need to touch the database. Precompiling of template
files should reduce the overhead to zero in most cases for
translation message lookups. The amount of overhead added to the
request processor can be reduced by caching filesystem information
on matching of template files for locales.</p>
</li><li>Flexibility</li><li>Interoperability</li><li>Reliability and robustness</li><li>Usability</li>
</ul>

Areas of interest to developers:
<ul>
<li>Maintainability</li><li>Portability
<p>The ACS Tcl I18N APIs should be as close as possible to the
ultimate Java APIs. This means that using the same templates if
possible, as well as the same message catalogs and format strings
should be a strong goal.</p>
</li><li>Reusability</li><li>Testability
<p>A set of unit tests are included in the <kbd>acs-lang</kbd>
package, to allow automatic testing after installation.</p>
</li>
</ul>
<h3>VI. API</h3>
<h4>VI.A Locale API</h4>
<strong>10.30</strong>
 A Locale object represents a specific
geographical, political, or cultural region. An operation that
requires a Locale to perform its task is called locale-sensitive
and uses the Locale to tailor information for the user. For
example, displaying a number is a locale-sensitive operation--the
number should be formatted according to the customs/conventions of
the user&#39;s native country, region, or culture.
<p>We will refer to a Locale by a combination of a
<em>language</em> and <em>country</em>. In the <a href="http://java.sun.com/products/jdk/1.2/docs/api/java/util/Locale.html">
Java Locale API</a> there is an optional <em>variant</em> which can
be added to a locale, which we will omit in the Tcl API.</p>
<p>The <em>language</em> is a valid <strong>ISO Language
Code</strong>. These codes are the lower-case two-letter codes as
defined by ISO-639. You can find a full list of these codes at a
number of sites, such as:<br><a href="http://www.ics.uci.edu/pub/ietf/http/related/iso639.txt">http://www.ics.uci.edu/pub/ietf/http/related/iso639.txt</a>
</p>
<p>The <em>country</em> is a valid <strong>ISO Country
Code</strong>. These codes are the upper-case two-letter codes as
defined by ISO-3166. You can find a full list of these codes at a
number of sites, such as:<br><a href="http://www.chemie.fu-berlin.de/diverse/doc/ISO_3166.html">http://www.chemie.fu-berlin.de/diverse/doc/ISO_3166.html</a>
</p>
<p>Examples are</p>
<blockquote>
<kbd>en_US</kbd> English US<br><kbd>ja_JP</kbd> Japanese<br><kbd>fr_FR</kbd> France French.</blockquote>
<p>The i18n module figures out the locale for a current request
makes it accessible via the <kbd><strong>ad_locale</strong></kbd>
function:</p>
<pre>
[<strong>ad_locale user <em>locale</em>
</strong>] =&gt; fr_FR
[<strong>ad_locale subsite <em>locale</em>
</strong>] =&gt; en_US
</pre>

It has not yet been decided how the user&#39;s preferred locale
will be initialized. For now, there is a site wide default package
parameter <kbd>[parameter::get -parameter DefaultLocale -default
"en_US"]</kbd>
, and an API for setting the locale with
the preference stored in a session variable: The
<kbd>ad_locale_set</kbd>
 function is used to set the user&#39;s
preferred locale to a desired value. It saves the value in the
current session.
<pre>
<strong>ad_locale_set</strong> locale "en_US"
       <em>will also automatically set [ad_locale user language]
          ( to "en" in this case)</em>

    ad_locale_set timezone "PST"

    
</pre>

The request processor should use the ad_locale API to figure out
the preferred locale for a request (perhaps combining user
preference with subsite defaults in some way). It will make this
information accesible via the <kbd>ad_conn</kbd>
 function:
<pre><strong>ad_conn locale</strong></pre>
<h4>Character Sets and Encodings</h4>

We refer to <em>MIME character set names</em>
 which are the valid
values which can be passed in a MIME header, such as
<pre>
Content-Type: text/html; charset=<strong>iso-8859-1</strong>
</pre>
<p>You can obtain the preferred character set for a locale via the
<kbd>ad_locale</kbd> API shown below:</p>
<pre>
set locale "en_US"
[<strong>ad_locale charset <em>$locale</em>
</strong>] =&gt; "iso-8859-1" or "shift_jis"
</pre>

Returns a case-insensitive name of a MIME character set.
<p>We already have an AOLserver function to convert a MIME charset
name to a Tcl encoding name:</p>
<pre>
[<strong>ns_encodingforcharset</strong> "iso-8859-1"] =&gt; iso8859-1
</pre>
<h3>Templating</h3>

The goal of templates is to separate program logic from data
presentation.
<p>For presenting data in multiple languages, there are two basic
ways to use templates for a given abstract URL. Say we have the URL
"foo", for example. We can provide templates for it in
the following ways:</p>
<ul>
<li>
<strong>Separate template for each target language</strong><p>Have a copy of each template file in each language you support,
e.g., <kbd>foo.en.adp</kbd>, <kbd>foo.fr.adp</kbd>,
<kbd>foo.de.adp</kbd>, etc.</p><p>We will refer to this style of template pages as
<em>language-specific templates</em>.</p>
</li><li>
<strong>A single template file for multiple languages</strong><p>You write your template to contain references to translation
strings either from data sources or using &lt;TRN&gt; tags.</p><p>For example, a site might support multiple languages, but use a
single file <kbd>foo.adp</kbd> which contains no language-specific
content, and would only make use of data sources or &lt;TRN&gt;
tags which in turn use the message catalog to look up
language-specific content.</p><p>We will refer to this style of page as a <em>multilingual
template</em>.</p>
</li>
</ul>

Both styles of authoring templates will probably be used; For pages
which contain a lot of free form text content, then having a
separate template page for each language would be easiest.
<p>But for a page which has a very fixed format, such as a data
entry form, it would mean a lot less redundant work to use a single
template source page to handle all the languages, and to have
<strong>all</strong> language-dependent strings be looked in a
message catalog. We can do this either by creating data sources
which call <kbd>lang_message_lookup</kbd>, or else use the
&lt;TRN&gt; tag to do the same thing from within an ADP file.</p>
<h4>Caching multilingual ADP Templates</h4>

Message catalog lookups can be potentially expensive, if many of
them are done in a page. The templating system can already
precompile and and cache adp pages. This works fine for a page in a
specific language such as <kbd>foo.en.adp</kbd>
, but we need to
modify the caching mechanism if we want to use a single template
file to target multiple languages.
<h4>Computing the <em>Effective Locale</em>
</h4>
<p>Let&#39;s say you have a template file "foo.adp" and
it contains calls to look up message strings using the TRN tag:</p>
<blockquote><pre>
&lt;master&gt;
&lt;trn key=username_prompt&gt;Please enter your username&lt;/tr&gt;
&lt;input type="text" name=username&gt;
&lt;p&gt;
&lt;trn key=password_prompt&gt;Enter Password:&lt;/trn&gt;
&lt;input type=password name=passwd&gt;
</pre></blockquote>

If the user requests the page <kbd>foo</kbd>
, and their
<strong>ad_locale</strong>
 is "en_US" then <em>effective
locale</em>
 is "en_US". Message lookups are done using
the effective locale. If the user&#39;s locale is
"fr_FR", then the effective locale will be
"fr_FR".
<p>If we evaluate the TRN tags at compile time then we need to
associate the <em>effective locale</em> in which the page was
evaluated with the cached compiled page code.</p>
<p>The effective locale of a template page that has an explicit
locale, such as a file named "foo.en.adp" or
"foo.en_US.adp", will be that explicit locale. So for
example, even if a user has a preferred locale of
"fr_FR", if there is only a page named
"foo.en.adp", then that page will be evaluated (and
cached) with an effective locale of en_US.</p>
<h4>VI.B Naming of Template Files To Encode Language and Character
Set</h4>
<strong>10.40</strong>
 The templating system will use the Locale
API to obtain the preferred locale for a page request, and will
attempt to find a template file which most closely matches that
locale.
<p>We will use the following convention for naming template files:
<kbd>filename.<em>locale_or_language</em>.adp</kbd>.</p>
<p>Examples:</p>
<blockquote><pre>
foo.<em>en_US</em>.adp
foo.en.adp

foo.fr_FR.adp
foo.fr.adp

foo.ja_JP.adp
foo.ja.adp

</pre></blockquote>
<p>The user request has a <em>locale</em> which is of the form
<em>language_country</em>. If someone wants English, they will
implicitly be choosing a default, such as en_US or en_GB. The
default locale for a language can be configured in the system
locale tables. So for example the default locale for "en"
could be "en_US".</p>
<p>The algorithm for finding the best matching template for a
request in a given locale is given below:</p>
<ol>
<li>Find the desired target locale using <kbd>[ad_conn
locale]</kbd> NOTE: This will always be a specific Locale (i.e.,
language_COUNTRY)</li><li>Look for a template file whose locale suffix matches exactly.
<p>For example, if the filename in the URL request is simply
<kbd>foo</kbd> and <kbd>[ad_conn locale]</kbd> returns en_US then
look for a file named <kbd>foo.en_US.adp</kbd>.</p>
</li><li>If an exact match is not found, look for template files whose
name matches the language portion of the target locale.
<p>For example, if the URL request name is <kbd>foo</kbd> and
<kbd>[ad_conn locale]</kbd> returns en_US and a file named
<kbd>foo.en_US.adp</kbd> is not found, then look for all templates
matching "en_*" as well as any template which just has
the "en" suffix.</p><p>So for example if the user&#39;s locale en_GB and the following
files exist:</p><p><kbd>foo.en_US.adp</kbd></p><p>then use <kbd>foo.en_US.adp</kbd>
</p><p>If however both <kbd>foo.en_US.adp</kbd> and
<kbd>foo.en.adp</kbd> exist, then use
<kbd>foo.<strong>en</strong>.adp</kbd> preferentially, i.e.,
don&#39;t switch locales if you can avoid it. The reasoning here is
that people can be very touchy about switching locales, so if there
is a generic matching language template available for a language,
use it rather than using an incorrect locale-specific template.</p>
</li><li>If no locale-specific template is found, look for a template
matching just the language
<p>I.e., if the request is for en_US, and there exists a file
<kbd>foo.en.adp</kbd>, use that.</p>
</li><li>If no locale-specific template is found, look for a simple .adp
file, such as <kbd>foo.adp</kbd>.</li>
</ol>
<p>Once a template file is found we must decide what character set
it is authored in, so that we can correctly load it into Tcl (which
converts it to UTF8 internally).</p>
<p>It would be simplest to mandate that all templates are authored
in UTF8, but that is just not a practical thing to enforce at this
point, I believe. Many designers and other people who actually
author the HTML template files will still find it easier to use
legacy tools that author in their "native" character
sets, such as ShiftJIS in Japan, or BIG5 in China.</p>
<p>So we make the convention that the template file is authored in
its <em>effective locale</em>'s character set. For multilingual
templates, we will load the template in the site default character
set as specified by the AOLserver <kbd>OutputCharset</kbd>
initializatoin parameter. For now, we will say that authoring
generic multilingual adp files can and should be done in ASCII.
Eventually we can switch to using UTF8.</p>
<p>A character set corresponding to a locale can be found using the
<kbd>[<strong>ad_locale charset</strong><em>$locale</em>]</kbd>
command. The templating system should call this right after it
computes the effective locale, so it can set up that charset
encoding conversion before reading the template file from disk.</p>
<p>We read the template file using this encoding, and set the
default output character set to it as well. Inside of either the
.adp page or the parent .tcl page, it is possible for the developer
to issue a command to override this default output character set.
The way this is done is currently to stick an explicit content-type
header in the AOLserver output headers, for example to force the
output to ISO-8859-1, you would do</p>
<pre>
ns_set put [ns_conn outputheaders] "content-type" "text/html; charset=iso-8859-1"       
</pre>
<blockquote><font color="green">
<em>design question</em>We should
have an API for this. The hack now is that the adp handler
<strong>adp_parse_ad_locale user_file</strong> looks at the output
headers, and if it sees a content type with an explicit charset, it
passes it along to <strong>ns_return</strong>.</font></blockquote>
<p>The default character set for a template <kbd>.adp</kbd> file
should be the default system encoding.</p>
<h4>VI.C Loading Regular Tcl Script Files</h4>
<strong>10.50</strong>
 By default, tcl and template files in the
system will be loaded using the default system encoding. This is
generally ISO-8859-1 for AOLserver running on Unix systems in
English.
<p>This default can be overridden by setting the AOLserver init
parameter for the MIME type of <kbd>.tcl</kbd> files to include an
explcit character set. If an explicit MIME type is not found,
<kbd>ns_encodingfortype</kbd> will default to the AOLserver init
parameter value <kbd>DefaultCharset</kbd> if it is set.</p>
<p>Example AOLserver .ini configuration file to set default script
file and template file charset to ShiftJIS:</p>
<blockquote><pre>
ns_section {ns/mimetypes }
...
ns_param .tcl {text/plain; charset=shift_jis}
ns_param .adp {text/html; charset=shift_jis}

ns_section ns/parameters
...
# charset hacking
ns_param HackContentType 1
ns_param URLCharset shift_jis
ns_param OutputCharset shift_jis
ns_param HttpOpenCharset shift_jis
ns_param DefaultCharset shift_jis

</pre></blockquote>
<h3>VI.A Message Catalog API</h3>

We want to use something like the Java ResourceBundle, where the
developer can declare a set of resources for a given namespace and
locale.
<p>For AOLserver/TCL, to make the message catalog more manageable,
we will split it into one message catalog per package, plus one
default global message namespace in case we need it. So for
example,</p>
<p>Message lookups are done using a combination of a key string and
a locale or language, as well as an implicit package prefix on the
key string. The API for using the message catalog is as
follows:</p>
<blockquote>
<pre>
<strong>lang_message_lookup</strong><em>locale</em><em>key</em> [default_string]
</pre><code>lang_message_lookup</code> is abbreviated by the procedure
named "<strong><code>_</code></strong>", which is the
convention used by the GNU strings message catalog
package.</blockquote>

The locale arg can actually be a full locale, or else a simple
language abbrev, such as <em>fr</em>
, <em>en</em>
, etc. The lookup
rules for finding strings based on key and locale are tried in
order as follows:
<ol>
<li>Lookup is first tried with the full locale (if present) and
package.key</li><li>Lookup is tried with just the language portion of the locale
and package.key</li><li>Lookup is tried with the full locale and key without package
prefix.</li><li>Lookup is tried with language and key without package
prefix.</li>
</ol>

Example: You are looking up the message string "Title" in
the <kbd>notes</kbd>
 package.
<pre>
[<strong>lang_message_lookup</strong> $locale notes.title "Title"]

can be abbreviated by
[<strong>_</strong> $locale notes.title "Title"]

<em># message key "title" is implicitly with respect to package key
#  "notes", i.e., notes.title</em>
[_ $locale title "Title"]

</pre>

The string is looked up by the symbolic key <kbd>notes.title</kbd>

(or <kbd>title</kbd>
 for short), and the constant value
<kbd>"Title"</kbd>
 is supplied as documentation and as a
default value. Having a default value allows developers to code
their application immediately without waiting to populate the
message catalog.
<h4>Default Package Namespace</h4>

By default, keys are prefixed with the name of the current package
(if a page request is being processed). So a lookup of the key
"title" in a page in the bboard package will actually
reference the "bboard.title" entry in the message
catalog.
<p>You can override this behavior by either using a fully qualified
key such as <kbd>bboard.title</kbd> or else by changing the message
catalog namespace using the <kbd>lang_set_package</kbd>
command:</p>
<pre>
[<strong>lang_set_package</strong> "bboard"]
</pre>

So for example code that runs in a scheduled proc, where there is
not necessarily any concept of a "current package", would
either use fully qualified keys to look up messages, or else call
<kbd>lang_set_package</kbd>
 before doing a message lookup.
<h4>Message Catalog Definition Files</h4>

A message catalog is defined by placing a file in the
<kbd>catalog</kbd>
 subdirectory of a package. Each file defines a
set of messages in different locales, and the file is written in a
character set specified by its file suffix:
<pre>
/packages/bboard/catalog/
                         bboard.iso-8859-1
                         bboard.shift_jis
                         bboard.iso-8859-6
</pre>

A message catalog file consists of tcl code to define messages in a
given language or locale:
<pre>

_mr en mail_notification "This is an email notification"
_mr fr mail_notification "Le notification du email"
...

</pre>

In the example above, if the catalog file was loaded from the
bboard package, all of the keys would be prefixed autmatically with
"<code>bboard.</code>
".
<h4>Loading A Message Catalog At Package Init Time</h4>

The API function
<pre>
<strong>lang_catalog_load</strong><em>package_key</em>
</pre>

Is used to load the message catalogs for a package. The catalog
files are stored in a package subdirectory called
<kbd>catalog</kbd>
. Their file names have the form
<kbd>*.<em>encoding</em>.cat</kbd>
, where <em>encoding</em>
 is the
name of a MIME charset encoding (<em>not</em>
 a Tcl charset name as
was used in a previous version of this command).
<pre>
/packages/bboard/catalog
                        /main.iso8859-1.cat
                        /main.shift_jis.cat
                        /main.iso-8859-6.cat
                        /other.iso8859-1.cat
                        /other.shift_jis.cat
                        /other.iso-8859-6.cat
</pre>
<p>You can add more pseudo-levels of hierarchy in naming the
message keys, using any separator character you want, for
example</p>
<blockquote><pre>
_mr fr alerts.mail_notification "Le notification du email"
</pre></blockquote>

which will be stored with the full key of
<kbd>bboard.alerts.mail_notification</kbd>
.
<h4>Calling the Message Catalog API from inside of Templates</h4>

Inside of a template, you can always make a call to the message
catalog API via a Tcl escape:
<pre>
&lt;%= [_ $locale bboard.passwordPrompt "Enter Password"]%&gt; 
</pre>

However, this is awkward and ugly to use. We have defined an ADP
tag which invokes the message catalog lookup. As explained in the
previous section, since our system precompiles adp templates, we
can get a performance improvement if we can cache the message
lookups at template compile time.
<p>The &lt;TRN&gt; tag is a call to lang_message_lookup that can be
used inside of an ADP file. Here is the documentation:</p>
<blockquote>Procedure that gets called when the &lt;trn&gt; tag is
encountered on an ADP page. The purpose of the procedure is to
register the text string enclosed within a pair of &lt;trn&gt; tags
as a message in the catalog, and to display the appropriate
translated string. Takes three optional parameters:
<code>lang</code>, <code>type</code> and <code>key</code>.
<ul>
<li>
<code>key</code> specifies the key in the message catalog. If
it is omitted this procedure returns simply the text enclosed by
the tags.</li><li>
<code>lang</code> specifies the language of the text string
enclosed within the flags. If it is omitted value defaults to
English.</li><li>
<code>type</code> specifies the context in which the
translation is made. If omitted, type is user which means that the
translation is provided in the user&#39;s preferred language.</li><li>
<code>static</code> specifies that this tag should be
translated once at template compile time, rather than dynamically
every time the page is run. This will be unneccessaru and will be
deprecated once we have implemented <em>effective locale</em> based
cacheing for templates.</li>
</ul>
Example 1: Display the text string <em>Hello</em> on an ADP page
(i.e. do nothing special):
<pre>
    &lt;trn&gt;Hello&lt;/trn&gt;
    </pre>
Example 2: Assign the key key <em>hello</em> to the text string
<em>Hello</em> and display the translated string in the user&#39;s
preferred language:
<pre>
    &lt;trn key="hello"&gt;Hello&lt;/trn&gt;
    </pre>
Example 3: Specify that <em>Bonjour</em> needs to be registered as
the French translation for the key <em>hello</em> (in addition to
displaying the translation in the user&#39;s preferred language):
<pre>
    &lt;trn key="hello" lang="fr"&gt;Bonjour&lt;/trn&gt;
    </pre>
Example 4: Register the string and display it in the preferred
language of the current user. Note that the possible values for the
<code>type</code> parameter are determined by what has been
implemented in the <code>ad_locale</code> procedure. By default,
only the <code>user</code> type is implemented. An example of a
type that could be implemented is <code>subsite</code>, for
displaying strings in the language of the subsite that owns the
current web page.
<pre>
    &lt;trn key="hello" type="user"&gt;Hello&lt;/trn&gt;
    </pre><p>Example 5: Translates the string once at template compile time,
using the effective local of the page.</p><pre>
    &lt;trn key="hello" static&gt;Hello&lt;/trn&gt;
    </pre>
</blockquote>
<h3>VII. Data Model Discussion</h3>
<h4>Internationalizing the Data Models</h4>

Some data which is stored in ACS package and core database tables
may be presented to users, and thus may need to be stored in
multiple languages. Examples of this are the descriptions of
package or site parameters in the administrative interface, the
"pretty names" of objects, and group names.
<p>Tables which are in acs kernel and have user-visible names that
may need to be translated in order to create an admin back end in
another language:</p>
<pre>
user groups:
   group_name

acs_object_types:
   pretty_name
   pretty_plural

acs_attributes:
   pretty_name
   pretty_plural

acs_attribute_descriptions
   description (clob)

procedure add_description- add a lang arg ?

acs_enum_values ? pretty_name

acs_privileges: 
  pretty_name
  pretty_plural

apm_package_types
  pretty_name
  pretty_plural


apm_package "instance_name"? Maybe a given instance
gets instantiated with a name in the desired language?


apm_parameters: 
   parameter_name
   section_name
</pre>

One approach is to split a table into two tables, one holding
language-independent datam, and the other holding
language-dependent data. This approach was described in the
<a href="http://www.arsdigita.com/asj/multilingual">ASJ
Multilingual Site Article</a>
.
<p>In that case, it is convenient to create a new view which looks
like the original table, with the addition of a language column
that you can specify in the queries.</p>
<h4>Drawbacks to Splitting Tables</h4>
<strong>It is not totally transparent to developers</strong>
<br>

Every query against the table which requests or modifies
language-dependent columns must now include a WHERE clause to
select the language.
<p>
<strong>Extra join may slow things down</strong><br>
The extra join of the two tables may cause queries to slow down,
although I am not sure what the actual performance hit might be. It
shouldn&#39;t be too large, because the join is against a fully
indexed table.</p>
<h3>VIII. User Interface</h3>
<h3>IX. Configuration/Parameters</h3>
<h3>X. Code Examples</h3>
<ul>
<li>fconfigure -encoding blah</li><li>content type in outputheaders set for encoding conversion
<pre>
ad_proc adp_parse_ad_conn_file {} {
    handle a request for an adp and/or tcl file in the template system.
} {
    namespace eval template variable parse_level ""
    #ns_log debug "adp_parse_ad_conn_file =&gt; file '[file root [ad_conn file]]'"
    set parsed_template [template::adp_parse [file root [ad_conn file]] {}]
    db_release_unused_handles
    if { $parsed_template ne ""} {
        set content_type [ns_set iget [ns_conn outputheaders] "content-type"]
        if { $content_type eq "" } {
            set content_type  [ns_guesstype [ad_conn file]]
        } else {
            ns_set idelkey [ns_conn outputheaders] "content-type"
        }
        ns_return 200 $content_type $parsed_template
    }
}

</pre>
</li>
</ul>
<h3>XI. Future Improvements/Areas of Likely Change</h3>
<h3>XII. Authors</h3>
<ul>
<li>System creator</li><li>System owner: hqm\@arsdigita.com</li><li>Documentation author: hqm\@arsdigita.com</li>
</ul>
<h3>XII. Revision History</h3>
<p><em>The revision history table below is for this template -
modify it as needed for your actual design document.</em></p>
<table bgcolor="#EFEFEF" cellpadding="2" cellspacing="2" width="90%"><tbody>
<tr bgcolor="#E0E0E0">
<th width="10%">Document Revision #</th><th width="50%">Action Taken, Notes</th><th>When?</th><th>By Whom?</th>
</tr><tr>
<td>0.1</td><td>Creation</td><td>12/4/2000</td><td>Henry Minsky</td>
</tr><tr>
<td>0.2</td><td>More specific template search algorithm, extended message
catalog API to use package keys or other namespace</td><td>12/4/2000</td><td>Henry Minsky</td>
</tr><tr>
<td>0.3</td><td>Details on how the &lt;TRN&gt; tag works in templates</td><td>12/4/2000</td><td>Henry Minsky</td>
</tr><tr>
<td>0.4</td><td>Definition of effective locale for template caching,
documentation of TRN tag</td><td>12/12/2000</td><td>Henry Minsky</td>
</tr>
</tbody></table>
<hr>
<a href="mailto:hqm\@arsdigita.com">hqm\@arsdigita.com</a>
<br>
