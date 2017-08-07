
<property name="context">{/doc/acs-lang {ACS Localization}} {ACS 4 Globalization Requirements}</property>
<property name="doc(title)">ACS 4 Globalization Requirements</property>
<master>
<h2>ACS 4 Globalization Requirements</h2>
<p>by Henry Minsky, Yon Feldman, Lars Pind, others</p>
<h3>I. Introduction</h3>

This document describes the requirements for functionality in the
ACS platform to support globalization of the core and optional
modules. The goal is to make it possible to support delivery of
applications which work properly in multiple locales with the
lowest development and maintenance cost.
<h4>Definitions</h4>
<blockquote>
<strong>internationalization (i18n)</strong><p>The provision within a computer program of the capability of
making itself adaptable to the requirements of different native
languages, local customs and coded character sets.</p><p><strong>locale</strong></p><p>The definition of the subset of a user&#39;s environment that
depends on language and cultural conventions.</p><p><strong>localization (L10n)</strong></p><p>The process of establishing information within a computer system
specific to the operation of particular native languages, local
customs and coded character sets.</p><p><strong>globalization</strong></p><p>A product development approach which ensures that software
products are usable in the worldwide markets through a combination
of internationalization and localization.</p>
</blockquote>
<h3>II. Vision Statement</h3>

The Mozilla project suggests keeping two catchy phrases in mind
when thinking about globalization:
<ul>
<li>One code base for the world</li><li>English is just another language</li>
</ul>
<p>Building an application often involves making a number of
assumptions on the part of the developers which depend on their own
culture. These include constant strings in the user interface and
system error messages, names of countries, cities, order of given
and family names for people, syntax of numeric and date strings and
collation order of strings.</p>
<p>The ACS should be able to operate in languages and regions
beyond US English. The goal of ACS Globalization is to provide a
clean and efficient way to factor out the locale dependent
functionality from our applications, in order to be able to easily
swap in alternate localizations.</p>
<p>This in turn will reduce redundant, costly, and error prone
rework when targeting the toolkit or applications built with the
toolkit to another locale.</p>
<p>The cost of porting the ACS to another locale without some kind
of globalization support would be large and ongoing, since without
a mechanism to incorporate the locale-specific changes cleanly back
into the code base, it would require making a new fork of the
source code for each locale.</p>
<h3>III. System/Application Overview</h3>

A globalized application will perform some or all of the following
steps to handle a page request for a specific locale:
<ol>
<li>Decide what the target locale is for an incoming page
request</li><li>Decide which character set encoding the output should be
delivered in</li><li>If a script file to handle the request needs to be loaded from
disk, determine if a character set conversion needs to be performed
when loading the script<br>
</li><li>If needed, locale-specific resources are fetched. These can
include text, graphics, or other resources that would vary with the
target locale.</li><li>If content data is fetched from the database, check for
locale-specific versions of the data (e.g. country names).</li><li>Source code should use a message catalog API to translate
constant strings in the code to the target locale</li><li>Perform locale-specific linguistic sorting on data if
needed</li><li>If the user submitted form input data, decide what character
set encoding conversion if any is needed. Parse locale-specific
quantities if needed (number formats, date formats).</li><li>If templating is being used, select correct locale-specific
template to merge with content</li><li>Format output data quantities in locale-specific manner (date,
time, numeric, currency). If templating is being used, this may be
done either before and/or after merging the data with a
template.</li>
</ol>
<p>Since the internationalization APIs may potentially be used on
every page in an application, the overhead for adding
internationalization to a module or application must not cause a
significant time delay in handling page requests.</p>
<p>In many cases there are facilities in Oracle to perform various
localization functions, and also there are facilities in Java which
we will want to move to. So the design to meet the requirements
will tend to rely on these capabilities, or close approximations to
them where possible, in order to make it easier to maintain Tcl and
Java ACS versions.</p>
<h3>IV. Use-cases and User-scenarios</h3>

Here are the cases that we need to be able to handle efficiently:
<ol>
<li>A developer needs to author a web site/application in a
language besides English, and possibly a character set besides
ISO-8859-1. This includes the operation of the ACS itself, i.e.,
navigation, admin pages for modules, error messages, as well as
additional modules or content supplied by the web site developer.
<p>What do they need to modify to make this work? Can their
localization work be easily folded in to future releases of
ACS?</p>
</li><li>A developer needs to author a web site which operates in
multiple languages simultaneously. For example, arsDigita.com with
content and navigation in English, German, and Japanese.
<p>The site would have an end-user visible UI to support these
languages, and the content management system must allow articles to
be posted in these languages. In some cases it may be necessary to
make the modules' admin UI&#39;s operate in more than one
supported language, while in other cases the backend admin
interface can operate in a single language.</p>
</li><li>A developer is writing a new module, and wants to make it easy
for someone to localize it. There should be a clear path to author
the module so that future developers can easily add support for
other locales. This would include support for creating resources
such as message catalogs, non-text assets such as graphics, and use
of templates which help to separate application logic from
presentation.</li>
</ol>
<h3>Competitive Analysis</h3>
<p>Other application servers: ATG Dyanmo, Broadvision, Vignette,
... ? Anyone know how they deal with i18n ?</p>
<h3>V. Related Links</h3>
<ul>
<li><em>System/Package "coversheet" - where all
documentation for this software is linked off of</em></li><li><em>Design document</em></li><li><em>Developer&#39;s guide</em></li><li><em>User&#39;s guide</em></li><li>
<em>Other-cool-system-related-to-this-one document</em><br><a href="http://www.li18nux.net/">LI18NUX 2000 Globalization
Specification: http://www.li18nux.net/</a><p><a href="">Mozilla i18N Guidelines:
http://www.mozilla.org/docs/refList/i18n/l12yGuidelines.html</a></p><p><a href="http://sunsite.berkeley.edu/amher/iso_639.html">ISO
639:1988 Code for the representation of names of languages
http://sunsite.berkeley.edu/amher/iso_639.html</a></p><p><a href="http://www.niso.org/3166.html">ISO 3166-1:1997 Codes
for the representation of names of countries and their subdivisions
Part 1: Country codes http://www.niso.org/3166.html</a></p><p><a href="">IANA Registry of Character Sets</a></p>
</li><li><em>Test plan</em></li><li><em>Competitive system(s)</em></li>
</ul>
<h3>VI Requirements</h3>

Because the requirements for globalization affect many areas of the
system, we will break up the requirements into phases, with a base
required set of features, and then stages of increasing
functionality.
<h3>VI.A Locales</h3>
<strong>10.0</strong>
 A standard representation of locale will be
used throughout the system. A locale refers to a language and
territory, and is uniquely identified by a combination of ISO
language and ISO country abbreviations.
<blockquote>See <a href="">Content Repository Requirement
100.20</a><p>
<strong>10.10</strong> Provide a consistent representation and
API for creating and referencing a locale</p><p>
<strong>10.20</strong> There will be a Tcl library of
locale-aware formatting and parsing functions for numbers, dates
and times. <em>Note that Java has builtin support for these
already</em>.</p><p>
<strong>10.30</strong> For each locale there will be default
date, number and currency formats.</p>
</blockquote>
<h3>VI.B Associating a Locale with a Request</h3>
<strong>20.0</strong>
 The request processor must have a mechanism
for associating a locale with each request. This locale is then
used to select the appropriate template for a request, and will
also be passed as the locale argument to the message catalog or
locale-specific formatting functions.
<blockquote>
<p>
<strong>20.10</strong> The locale for a request should be
computed by the following method, in descending order of
priority:</p><ul class="noindent">
<li>get locale associated with subsite or package id</li><li>get locale from user preference</li><li>get locale from site wide default
<p>
<strong>20.20</strong> An API will be provided for getting the
current request locale from the <code>ad_conn</code> structure.</p>
</li>
</ul>
</blockquote>
<h3>VI.C Resource Bundles / Content Repository</h3>
<strong>30.0</strong>
 A mechanism must be provided for a developer
to group a set of arbitrary content resources together, keyed by a
unique identifier and a locale.
<p>For example, what approaches could be used to implement a
localizable nav-bar mechanism for a site? A navigation bar might be
made up of a set of text strings and graphics, where the graphics
themselves are locale-specific, such as images of English or
Japanese text (as on www.arsdigita.com). It should be easy to
specify alternate configurations of text and graphics to lay out
the page for different locales.</p>
<p>Design note: Alternative mechanisms to implement this
functionality might include using templates, Java ResourceBundles,
content-item containers in the Content Repository, or some
convention assigning a common prefix to key strings in the message
catalog.</p>
<h3>VI.D Message Catalog for String Translation</h3>
<strong>40.0</strong>
 A message catalog facility will provide a
database of translations for constant strings for multilingual
applications. It must support the following:
<blockquote>
<p>
<strong>40.10</strong> Each message will referenced via unique a
key.</p><p>
<strong>40.20</strong> The key for a message will have some
hierarchical structure to it, so that sets of messages can be
grouped with respect to a module name or package path.</p><p>
<strong>40.30</strong> The API for lookup of a message will take
a locale and message key as arguments, and return the appropriate
translation of that message for the specifed locale.</p><p>
<strong>40.40</strong> The API for lookup of a message will
accept an optional default string which can be used if the message
key is not found in the catalog. This lets the developer get code
working and tested in a single language before having to initialize
or update a message catalog.</p><p>
<strong>40.50</strong> For use within templates, custom tags
which invoke the message lookup API will be provided.</p><p>
<strong>40.60</strong> Provide a method for importing and
exporting a flat file of translation strings, in order to make it
as easy as possible to create and modify message translations in
bulk without having to use a web interface.</p><p>
<strong>40.70</strong> Since translations may be in different
character sets, there must be provision for writing and reading
catalog files in different character sets. A mechanism must exist
for identifying the character set of a catalog file before reading
it.</p><p>
<strong>40.80</strong> There should be a mechanism for tracking
dependencies in the message catalog, so that if a string is
modified, the other translations of that string can be flagged as
needing update.</p><p>
<strong>40.90</strong> The message lookup must be as efficient
as possible so as not to slow down the delivery of pages.</p><p>
<br><font color="#080EFF"><em>Design question: Is there any reason to
implement the message catalog on top of the content repository as
the underlying storage and retrieval service, with a layer of
caching for performance? Would we get a nice user interface and
version control almost for free?</em></font>
</p>
</blockquote>
<h3>VI.E Character Set Encoding</h3>
<strong>Character Sets</strong>
<p>
<strong>50.0</strong> A locale will have a primary associated
character set which is used to encode text in the language. When
given a locale, we can query the system for the associated
character set to use.</p>
<p>The assumption is that we are going to use Unicode in our
database to hold all text data. Our current programming
environments (Tcl/Oracle or Java/Oracle) operate on Unicode data
internally. However, since Unicode is not yet commonly used in
browsers and authoring tools, the system must be able to read and
write other character sets. In particular, conversions to and from
Unicode will need to be explicitly performed at the following
times:</p>
<ul>
<li>Loading source files (.tcl or .adp) or content files from the
filesystem</li><li>Accepting form input data from users</li><li>Delivering text output to a browser</li><li>Composing an email message</li><li>Writing data to the filesystem</li>
</ul>
<p>
<br><font color="#080EFF"><em>Design question: Do we want to mandate
that all template files be stored in UTF8? I don&#39;t think so,
because most people don&#39;t have Unicode editors, or don&#39;t
want to be bothered with an extra step to convert files to UTF8 and
back when editing them in their favorite editor.</em></font>
</p>
<p><font color="#080EFF"><em>Same question for script and template
files, how do we know what language and character set they are
authored in? Should we overload the filename suffix (e.g.,
'.shiftjis.adp', '.ja_JP.euc.adp')?</em></font></p>
<p><font color="#080EFF"><em>The simplest design is probably just
to assign a default mapping from each locale to character a set:
e.g. ja_JP -&gt; ShiftJIS, fr_FR -&gt; ISO-8859-1. +++ (see new
ACS/Java notes) +++</em></font></p>
<blockquote>
<h4>Tcl Source File Character Set</h4>
There are two classes of Tcl files loaded by the system; library
files loaded at server startup, and page script files, which are
run on each page request.
<p>
<br><font color="#080EFF"><em>Should we require all Tcl files be stored
as UTF8? That seems too much of a burden on
developers.</em></font>
</p><p>
<strong>50.10</strong> Tcl library files can be authored in any
character set. The system must have a way to determine the
character set before loading the files, probably from the
filename.</p><p>
<strong>50.20</strong> Tcl page script files can be authored in
any character set. The system must have a way to determine the
character set before loading the files, probably from the
filename.</p><h4>Submitted Form Data Character Set</h4><strong>50.30</strong> Data which is submitted with a HTTP request
using a GET or POST method may be in any character set. The system
must be able to determine the encoding of the form data and convert
it to Unicode on demand.
<p>
<strong>50.35</strong> The developer must be able to override
the default system choice of character set when parsing and
validating user form data.</p><p>
<strong>50.30.10</strong> Extra hair: In Japan and some other
Asian languages where there are multiple character set encodings in
common use, the server may need to attempt to do an auto-detection
of the character set, because buggy browsers may submit form data
in an unexpected alternate encoding.</p><h4>Output Character Set</h4><strong>50.40</strong> The output character set for a page request
will be determined by default by the locale associated with the
request (see requirement 20.0).
<p>
<strong>50.50</strong> It must be possible for a developer to
manually override the output character set encoding for a request
using an API function.</p>
</blockquote>
<h3>VI.F ACS Kernel Issues</h3>
<blockquote>
<strong>60.10</strong> All ACS error messages must use
the message catalog and the request locale to generate error
message for the appropriate locale.
<p>
<strong>60.20</strong> Web server error messages such as 404,
500, etc must also be delivered in the appropriate locale.</p><p>
<strong>60.30</strong> Where files are written or read from
disk, their filenames must use a character set and character values
which are safe for the underlying operating system.</p>
</blockquote>
<h3>VI.G Templates</h3>
<blockquote>
<strong>70.0</strong> For a given abstract URL, the
designer may create multiple locale-specific template files may be
created (one per locale or language)
<p>
<strong>70.10</strong> For a given page request, the system must
be able to select an approprate locale-specific template file to
use. The request locale is computed as per (see requirement
20.0).</p><p><font color="#080EFF"><em>Design note: this would probably be
implemented by suffixing the locale or a locale abbreviation to the
template filename, such as <kbd>foo.ja.adp</kbd> or
<kbd>foo.en_GB.adp</kbd>.</em></font></p><p>
<strong>70.20</strong>A template file may be created for a
partial locale (language only, without a territory), and the
request processor should be able to find the closest match for the
current request locale.</p><p>
<strong>70.30</strong> A template file may be created in any
character set. The system must have a way to know which character
set a template file contains, so it can properly process it.</p><h4>Formatting Datasource Output in Templates</h4><strong>70.50</strong> The properties of a datasource column may
include a datatype so that the templating system can format the
output for the current locale. The datatype is defined by a
standard ACS datatype plus a format token or format string, for
example: a date column might be specified as 'current_date:date
LONG,' or 'current_date:date "YYYY-Mon-DD"'
<h4>Forms</h4><strong>70.60</strong> The forms API must support construction of
locale-specific HTML form widgets, such as date entry widgets, and
form validation of user input data for locale-specific data, such
as dates or numbers.
<p>
<strong>70.70</strong> For forms which allow users to upload
files, a standard method for a user to indicate the charset of a
text file being uploaded must be provided.</p><p><font color="#080EFF"><em>Design note: this presumably applies
to uploading data to the content repository as well</em></font></p>
</blockquote>
<h3>VI.H Sorting and Searching</h3>
<blockquote>
<strong>80.10</strong> Support API for correct
collation (sorting order) on lists of strings in locale-dependent
way.
<p>
<strong>80.20</strong> For the Tcl API, we will say that
locale-dependent sorting will use Oracle SQL operations (i.e., we
won&#39;t provide a Tcl API for this). We require a Tcl API
function to return the correct incantation of NLS_SORT to use for a
given locale with <code>ORDER BY</code> clauses in queries.</p><p>
<strong>80.40</strong> The system must handle full-text search
in any supported language.</p>
</blockquote>
<h3>VI.G Time Zones</h3>
<blockquote>
<strong>90.10</strong> Provide API support for
specifying a time zone
<p>
<strong>90.20</strong> Provide an API for computing time and
date operations which are aware of timezones. So for example a
calendar module can properly synchronize items inserted into a
calendar from users in different time zones using their own local
times.</p><p>
<strong>90.30</strong> Store all dates and times in universal
time zone, UTC.</p><p>
<strong>90.40</strong> For a registered users, a time zone
preference should be stored.</p><p>
<strong>90.50</strong> For a non-registered user a time zone
preference should be attached via a session or else UTC should be
used to display every date and time.</p><p>
<strong>90.60</strong> The default if we can&#39;t determine a
time zone is to display all dates and times in some universal time
zone such as GMT.</p>
</blockquote>
<h3>VI.H Database</h3>
<blockquote><p>
<strong>100.10</strong> Since UTF8 strings can use up to three
(UCS2) or six (UCS4) bytes per character, make sure that column
size declarations in the schema are large enough to accommodate
required data (such as email addresses in Japanese).</p></blockquote>
<h3>VI.I Email and Messaging</h3>

When sending an email message, just as when delivering the content
in web page over an HTTP connection, it is necessary to be able to
specify what character set encoding to use.
<blockquote>
<p>
<strong>110.10</strong> The email message sending API will allow
for a character set encoding to be specified.</p><p>
<strong>110.20</strong> The email accepting API will allow for
character set to be parsed correctly (hopefully a well formatted
message will have a MIME character set content type header)</p>
</blockquote>
<h3>Implementation Notes</h3>

Because globalization touches many different parts of the system,
we want to reduce the implementation risk by breaking the
implementation into phases.
<h3>VII. Revision History</h3>
<table border="0" cellpadding="2" width="90%" bgcolor="#EFEFEF"><tbody>
<tr>
<th width="10%" bgcolor="#E0E0E0">Document Revision #</th><th width="50%" bgcolor="#E0E0E0">Action Taken, Notes</th><th bgcolor="#E0E0E0">When?</th><th bgcolor="#E0E0E0">By Whom?</th>
</tr><tr>
<td bgcolor="#E0E0E0">0.1</td><td bgcolor="#E0E0E0">Creation</td><td bgcolor="#E0E0E0">11/08/2000</td><td bgcolor="#E0E0E0">Henry Minsky</td>
</tr><tr>
<td bgcolor="#E0E0E0">0.2</td><td bgcolor="#E0E0E0">Minor typos fixed, clarifications to
wording</td><td bgcolor="#E0E0E0">11/14/2000</td><td bgcolor="#E0E0E0">Henry Minsky</td>
</tr><tr>
<td bgcolor="#E0E0E0">0.3</td><td bgcolor="#E0E0E0">comments from Christian</td><td bgcolor="#E0E0E0">1/14/2000</td><td bgcolor="#E0E0E0">Henry Minsky</td>
</tr>
</tbody></table>
<hr>
<address><a href="">hqm\@arsdigita.com</a></address>
<p>Last modified: $Date$</p>
