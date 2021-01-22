
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {OpenACS Internationalization Requirements}</property>
<property name="doc(title)">OpenACS Internationalization Requirements</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="db-api-detailed" leftLabel="Prev"
		    title="
Chapter 15. Kernel Documentation"
		    rightLink="security-requirements" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="i18n-requirements" id="i18n-requirements"></a>OpenACS Internationalization
Requirements</h2></div></div></div><div class="authorblurb">
<p>by Henry Minsky, <a class="ulink" href="mailto:yon\@openforce.net" target="_top">Yon Feldman</a>, <a class="ulink" href="mailto:lars\@collaboraid.biz" target="_top">Lars
Pind</a>, <a class="ulink" href="mailto:peter\@collaboraid.biz" target="_top">Peter Marklund</a>, <a class="ulink" href="mailto:christian\@collaboraid.biz" target="_top">Christian
Hvid</a>, and others.</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="i18n-requirements-introduction" id="i18n-requirements-introduction"></a>Introduction</h3></div></div></div><p>This document describes the requirements for functionality in
the OpenACS platform to support globalization of the core and
optional modules. The goal is to make it possible to support
delivery of applications which work properly in multiple locales
with the lowest development and maintenance cost.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="i18n-requirements-definitions" id="i18n-requirements-definitions"></a>Definitions</h3></div></div></div><div class="variablelist"><dl class="variablelist">
<dt><span class="term">internationalization (i18n)</span></dt><dd><p>The provision within a computer program of the capability of
making itself adaptable to the requirements of different native
languages, local customs and coded character sets.</p></dd><dt><span class="term">locale</span></dt><dd><p>The definition of the subset of a user&#39;s environment that
depends on language and cultural conventions.</p></dd><dt><span class="term">localization (L10n)</span></dt><dd><p>The process of establishing information within a computer system
specific to the operation of particular native languages, local
customs and coded character sets.</p></dd><dt><span class="term">globalization</span></dt><dd><p>A product development approach which ensures that software
products are usable in the worldwide markets through a combination
of internationalization and localization.</p></dd>
</dl></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="II._Vision_Statement" id="II._Vision_Statement"></a>Vision Statement</h3></div></div></div><p>The Mozilla project suggests keeping two catchy phrases in mind
when thinking about globalization:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>One code base for the world</p></li><li class="listitem"><p>English is just another language</p></li>
</ul></div><p>Building an application often involves making a number of
assumptions on the part of the developers which depend on their own
culture. These include constant strings in the user interface and
system error messages, names of countries, cities, order of given
and family names for people, syntax of numeric and date strings and
collation order of strings.</p><p>The OpenACS should be able to operate in languages and regions
beyond US English. The goal of OpenACS Globalization is to provide
a clean and efficient way to factor out the locale dependent
functionality from our applications, in order to be able to easily
swap in alternate localizations.</p><p>This in turn will reduce redundant, costly, and error prone
rework when targeting the toolkit or applications built with the
toolkit to another locale.</p><p>The cost of porting the OpenACS to another locale without some
kind of globalization support would be large and ongoing, since
without a mechanism to incorporate the locale-specific changes
cleanly back into the code base, it would require making a new fork
of the source code for each locale.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="system-application-overview" id="system-application-overview"></a>System/Application Overview</h3></div></div></div><p>A globalized application will perform some or all of the
following steps to handle a page request for a specific locale:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>Decide what the target locale is for an incoming page
request</p></li><li class="listitem"><p>Decide which character set encoding the output should be
delivered in</p></li><li class="listitem"><p>If a script file to handle the request needs to be loaded from
disk, determine if a character set conversion needs to be performed
when loading the script</p></li><li class="listitem"><p>If needed, locale-specific resources are fetched. These can
include text, graphics, or other resources that would vary with the
target locale.</p></li><li class="listitem"><p>If content data is fetched from the database, check for
locale-specific versions of the data (e.g. country names).</p></li><li class="listitem"><p>Source code should use a message catalog API to translate
constant strings in the code to the target locale</p></li><li class="listitem"><p>Perform locale-specific linguistic sorting on data if needed</p></li><li class="listitem"><p>If the user submitted form input data, decide what character set
encoding conversion if any is needed. Parse locale-specific
quantities if needed (number formats, date formats).</p></li><li class="listitem"><p>If templating is being used, select correct locale-specific
template to merge with content</p></li><li class="listitem"><p>Format output data quantities in locale-specific manner (date,
time, numeric, currency). If templating is being used, this may be
done either before and/or after merging the data with a
template.</p></li>
</ol></div><p>Since the internationalization APIs may potentially be used on
every page in an application, the overhead for adding
internationalization to a module or application must not cause a
significant time delay in handling page requests.</p><p>In many cases there are facilities in Oracle to perform various
localization functions, and also there are facilities in Java which
we will want to move to. So the design to meet the requirements
will tend to rely on these capabilities, or close approximations to
them where possible, in order to make it easier to maintain Tcl and
Java OpenACS versions.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="IV._Use-cases_and_User-scenarios" id="IV._Use-cases_and_User-scenarios"></a>Use-cases and
User-scenarios</h3></div></div></div><p>Here are the cases that we need to be able to handle
efficiently:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem">
<p>A developer needs to author a web site/application in a language
besides English, and possibly a character set besides ISO-8859-1.
This includes the operation of the OpenACS itself, i.e.,
navigation, admin pages for modules, error messages, as well as
additional modules or content supplied by the web site
developer.</p><p>What do they need to modify to make this work? Can their
localization work be easily folded in to future releases of
OpenACS?</p>
</li><li class="listitem">
<p>A developer needs to author a web site which operates in
multiple languages simultaneously. For example, www.un.org with
content and navigation in multiple languages.</p><p>The site would have an end-user visible UI to support these
languages, and the content management system must allow articles to
be posted in these languages. In some cases it may be necessary to
make the modules' admin UI&#39;s operate in more than one
supported language, while in other cases the backend admin
interface can operate in a single language.</p>
</li><li class="listitem"><p>A developer is writing a new module, and wants to make it easy
for someone to localize it. There should be a clear path to author
the module so that future developers can easily add support for
other locales. This would include support for creating resources
such as message catalogs, non-text assets such as graphics, and use
of templates which help to separate application logic from
presentation.</p></li>
</ol></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="Competitive_Analysis" id="Competitive_Analysis"></a>Competitive Analysis</h3></div></div></div><p>Other application servers: ATG Dyanmo, Broadvision, Vignette,
... ? Anyone know how they deal with i18n ?</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="V._Related_Links" id="V._Related_Links"></a>Related Links</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p><span class="emphasis"><em>System/Package "coversheet"
- where all documentation for this software is linked off
of</em></span></p></li><li class="listitem"><p><span class="emphasis"><em><a class="link" href="i18n-design" title="Design Notes">Design
document</a></em></span></p></li><li class="listitem"><p><span class="emphasis"><em><a class="link" href="i18n" title="Chapter 14. Internationalization">Developer&#39;s
guide</a></em></span></p></li><li class="listitem"><p><span class="emphasis"><em>User&#39;s guide</em></span></p></li><li class="listitem">
<p><span class="emphasis"><em>Other-cool-system-related-to-this-one
document</em></span></p><p><a class="ulink" href="http://www.li18nux.net/" target="_top">LI18NUX 2000 Globalization Specification:
http://www.li18nux.net/</a></p><p><a class="ulink" href="http://www.mozilla.org/docs/refList/i18n/l12yGuidelines.html" target="_top">Mozilla i18N Guidelines:
http://www.mozilla.org/docs/refList/i18n/l12yGuidelines.html</a></p><p><a class="ulink" href="https://www.iso.org/standard/4766.html" target="_top">ISO 639:1988 Code for the representation of names of
languages</a></p><p><a class="ulink" href="https://www.iso.org/standard/24591.html" target="_top">ISO 3166-1:1997 Codes for the representation of names
of countries and their subdivisions Part 1: Country codes</a></p><p><a class="ulink" href="http://www.isi.edu/in-notes/iana/assignments/character-sets" target="_top">IANA Registry of Character Sets</a></p>
</li><li class="listitem"><p><span class="emphasis"><em>Test plan</em></span></p></li><li class="listitem"><p><span class="emphasis"><em>Competitive system(s)</em></span></p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="VI_Requirements" id="VI_Requirements"></a>Requirements</h3></div></div></div><p>Because the requirements for globalization affect many areas of
the system, we will break up the requirements into phases, with a
base required set of features, and then stages of increasing
functionality.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="VI.A_Locales" id="VI.A_Locales"></a>Locales</h3></div></div></div><p><span class="emphasis"><em>10.0</em></span></p><p>A standard representation of locale will be used throughout the
system. A locale refers to a language and territory, and is
uniquely identified by a combination of ISO language and ISO
country abbreviations.</p><div class="blockquote"><blockquote class="blockquote">
<p>See <a class="ulink" href="/doc/acs-content-repository/requirements" target="_top">Content Repository Requirement 100.20</a>
</p><p>
<span class="emphasis"><em>10.10</em></span> Provide a
consistent representation and API for creating and referencing a
locale</p><p>
<span class="emphasis"><em>10.20</em></span> There will be a Tcl
library of locale-aware formatting and parsing functions for
numbers, dates and times. <span class="emphasis"><em>Note that Java
has builtin support for these already</em></span>.</p><p>
<span class="emphasis"><em>10.30</em></span> For each locale
there will be default date, number and currency formats.
<em><span class="remark">Currency i18n is NOT IMPLEMENTED for
5.0.0.</span></em>
</p><p>
<span class="emphasis"><em>10.40</em></span>Administrators can
upgrade their servers to use new locales via the APM.
<em><span class="remark">NOT IMPLEMENTED in 5.0.0; current
workaround is to get an xml file and load it
manually.</span></em>
</p>
</blockquote></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="VI.B_Associating_a_Locale_with_a_Request" id="VI.B_Associating_a_Locale_with_a_Request"></a>Associating a Locale
with a Request</h3></div></div></div><p><span class="emphasis"><em>20.0</em></span></p><p>The request processor must have a mechanism for associating a
locale with each request. This locale is then used to select the
appropriate template for a request, and will also be passed as the
locale argument to the message catalog or locale-specific
formatting functions.</p><div class="blockquote"><blockquote class="blockquote">
<p>
<span class="emphasis"><em>20.10</em></span> The locale for a
request should be computed by the following method, in descending
order of priority:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>get locale associated with subsite or package id</p></li><li class="listitem"><p>get locale from user preference</p></li><li class="listitem">
<p>get locale from site wide default</p><p>
<span class="emphasis"><em>20.20</em></span> An API will be
provided for getting the current request locale from the
<code class="literal">ad_conn</code> structure.</p>
</li>
</ul></div>
</blockquote></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="resource-bundles" id="resource-bundles"></a>Resource Bundles / Content Repository</h3></div></div></div><p><span class="emphasis"><em>30.0</em></span></p><p>A mechanism must be provided for a developer to group a set of
arbitrary content resources together, keyed by a unique identifier
and a locale.</p><p>For example, what approaches could be used to implement a
localizable nav-bar mechanism for a site? A navigation bar might be
made up of a set of text strings and graphics, where the graphics
themselves are locale-specific, such as images of English or
Japanese text (as on www.un.org). It should be easy to specify
alternate configurations of text and graphics to lay out the page
for different locales.</p><p>Design note: Alternative mechanisms to implement this
functionality might include using templates, Java ResourceBundles,
content-item containers in the Content Repository, or some
convention assigning a common prefix to key strings in the message
catalog.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="VI.D_Message_Catalog_for_String_Translation" id="VI.D_Message_Catalog_for_String_Translation"></a>Message Catalog
for String Translation</h3></div></div></div><p><span class="emphasis"><em>40.0</em></span></p><p>A message catalog facility will provide a database of
translations for constant strings for multilingual applications. It
must support the following:</p><div class="blockquote"><blockquote class="blockquote">
<p>
<span class="emphasis"><em>40.10</em></span> Each message will
referenced via unique a key.</p><p>
<span class="emphasis"><em>40.20</em></span> The key for a
message will have some hierarchical structure to it, so that sets
of messages can be grouped with respect to a module name or package
path.</p><p>
<span class="emphasis"><em>40.30</em></span> The API for lookup
of a message will take a locale and message key as arguments, and
return the appropriate translation of that message for the specifed
locale.</p><p>
<span class="emphasis"><em>40.40</em></span> The API for lookup
of a message will accept an optional default string which can be
used if the message key is not found in the catalog. This lets the
developer get code working and tested in a single language before
having to initialize or update a message catalog.</p><p>
<span class="emphasis"><em>40.50</em></span> For use within
templates, custom tags which invoke the message lookup API will be
provided.</p><p>
<span class="emphasis"><em>40.60</em></span> Provide a method
for importing and exporting a flat file of translation strings, in
order to make it as easy as possible to create and modify message
translations in bulk without having to use a web interface.</p><p>
<span class="emphasis"><em>40.70</em></span> Since translations
may be in different character sets, there must be provision for
writing and reading catalog files in different character sets. A
mechanism must exist for identifying the character set of a catalog
file before reading it.</p><p>
<span class="emphasis"><em>40.80</em></span> There should be a
mechanism for tracking dependencies in the message catalog, so that
if a string is modified, the other translations of that string can
be flagged as needing update.</p><p>
<span class="emphasis"><em>40.90</em></span> The message lookup
must be as efficient as possible so as not to slow down the
delivery of pages.</p>
</blockquote></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="VI.E_Character_Set_Encoding" id="VI.E_Character_Set_Encoding"></a>Character Set Encoding</h3></div></div></div><p><span class="emphasis"><em>Character Sets</em></span></p><p>
<span class="emphasis"><em>50.0</em></span> A locale will have a
primary associated character set which is used to encode text in
the language. When given a locale, we can query the system for the
associated character set to use.</p><p>The assumption is that we are going to use Unicode in our
database to hold all text data. Our current programming
environments (Tcl/Oracle or Java/Oracle) operate on Unicode data
internally. However, since Unicode is not yet commonly used in
browsers and authoring tools, the system must be able to read and
write other character sets. In particular, conversions to and from
Unicode will need to be explicitly performed at the following
times:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Loading source files (.tcl or .adp) or content files from the
filesystem</p></li><li class="listitem"><p>Accepting form input data from users</p></li><li class="listitem"><p>Delivering text output to a browser</p></li><li class="listitem"><p>Composing an email message</p></li><li class="listitem"><p>Writing data to the filesystem</p></li>
</ul></div><p>Acs-templating does the following.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>When the acs-templating package opens an an ADP or Tcl file, it
assumes the file is iso-8859-1. If the output charset
(OutputCharset) in the AOLserver config file is set, then
acs-templating assumes it&#39;s that charset. Writing Files</p></li><li class="listitem"><p>When the acs-templating package writes an an ADP or Tcl file, it
assumes the file is iso-8859-1. If the output charset
(OutputCharset) in the AOLserver config file is set, then
acs-templating assumes it&#39;s that charset.</p></li>
</ul></div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="Tcl_Source_File_Character_Set" id="Tcl_Source_File_Character_Set"></a>Tcl Source File Character
Set</h4></div></div></div><div class="blockquote"><blockquote class="blockquote">
<p>There are two classes of Tcl files loaded by the system; library
files loaded at server startup, and page script files, which are
run on each page request.</p><p><span class="emphasis"><em>Should we require all Tcl files be
stored as UTF8? That seems too much of a burden on
developers.</em></span></p><p>
<span class="emphasis"><em>50.10</em></span> Tcl library files
can be authored in any character set. The system must have a way to
determine the character set before loading the files, probably from
the filename.</p><p>
<span class="emphasis"><em>50.20</em></span> Tcl page script
files can be authored in any character set. The system must have a
way to determine the character set before loading the files,
probably from the filename.</p>
</blockquote></div>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="Submitted_Form_Data_Character_Set" id="Submitted_Form_Data_Character_Set"></a>Submitted Form Data
Character Set</h4></div></div></div><p>
<span class="emphasis"><em>50.30</em></span> Data which is
submitted with a HTTP request using a GET or POST method may be in
any character set. The system must be able to determine the
encoding of the form data and convert it to Unicode on demand.</p><p>
<span class="emphasis"><em>50.35</em></span> The developer must
be able to override the default system choice of character set when
parsing and validating user form data. <em><span class="remark">INCOMPLETE - form widgets in
acs-templating/tcl/date-procs.tcl are not internationalized. Also,
acs-templating&#39;s UI needs to be internationalized by replacing
all user-visible strings with message keys.</span></em>
</p><p>
<span class="emphasis"><em>50.30.10</em></span>In Japan and some
other Asian languages where there are multiple character set
encodings in common use, the server may need to attempt to do an
auto-detection of the character set, because buggy browsers may
submit form data in an unexpected alternate encoding.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="Output_Character_Set" id="Output_Character_Set"></a>Output Character Set</h4></div></div></div><div class="blockquote"><blockquote class="blockquote">
<p>
<span class="emphasis"><em>50.40</em></span> The output
character set for a page request will be determined by default by
the locale associated with the request (see requirement 20.0).</p><p>
<span class="emphasis"><em>50.50</em></span> It must be possible
for a developer to manually override the output character set
encoding for a request using an API function.</p>
</blockquote></div>
</div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="VI.F_ACS_Kernel_Issues" id="VI.F_ACS_Kernel_Issues"></a>ACS Kernel Issues</h3></div></div></div><div class="blockquote"><blockquote class="blockquote">
<p>
<span class="emphasis"><em>60.10</em></span> All OpenACS error
messages must use the message catalog and the request locale to
generate error message for the appropriate locale.<em><span class="remark">NOT IMPLEMENTED for 5.0.0.</span></em>
</p><p>
<span class="emphasis"><em>60.20</em></span> Web server error
messages such as 404, 500, etc must also be delivered in the
appropriate locale.</p><p>
<span class="emphasis"><em>60.30</em></span> Where files are
written or read from disk, their filenames must use a character set
and character values which are safe for the underlying operating
system.</p>
</blockquote></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="VI.G_Templates" id="VI.G_Templates"></a>Templates</h3></div></div></div><div class="blockquote"><blockquote class="blockquote">
<p>
<span class="emphasis"><em>70.0</em></span> For a given abstract
URL, the designer may create multiple locale-specific template
files may be created (one per locale or language)</p><p>
<span class="emphasis"><em>70.10</em></span> For a given page
request, the system must be able to select an approprate
locale-specific template file to use. The request locale is
computed as per (see requirement 20.0).</p><p>
<span class="emphasis"><em>70.20</em></span>A template file may
be created for a partial locale (language only, without a
territory), and the request processor should be able to find the
closest match for the current request locale.</p><p>
<span class="emphasis"><em>70.30</em></span> A template file may
be created in any character set. The system must have a way to know
which character set a template file contains, so it can properly
process it.</p>
</blockquote></div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="Formatting_Datasource_Output_in_Templates" id="Formatting_Datasource_Output_in_Templates"></a>Formatting
Datasource Output in Templates</h4></div></div></div><p>
<span class="emphasis"><em>70.50</em></span> The properties of a
datasource column may include a datatype so that the templating
system can format the output for the current locale. The datatype
is defined by a standard OpenACS datatype plus a format token or
format string, for example: a date column might be specified as
'current_date:date LONG,' or 'current_date:date
"YYYY-Mon-DD"'</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="Forms" id="Forms"></a>Forms</h4></div></div></div><div class="blockquote"><blockquote class="blockquote">
<p>
<span class="emphasis"><em>70.60</em></span> The forms API must
support construction of locale-specific HTML form widgets, such as
date entry widgets, and form validation of user input data for
locale-specific data, such as dates or numbers. <span class="emphasis"><em>NOT IMPLEMENTED in 5.0.0.</em></span>
</p><p>
<span class="emphasis"><em>70.70</em></span> For forms which
allow users to upload files, a standard method for a user to
indicate the charset of a text file being uploaded must be
provided.</p><p><span class="emphasis"><em>Design note: this presumably applies
to uploading data to the content repository as well</em></span></p>
</blockquote></div>
</div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="VI.H_Sorting_and_Searching" id="VI.H_Sorting_and_Searching"></a>Sorting and Searching</h3></div></div></div><div class="blockquote"><blockquote class="blockquote">
<p>
<span class="emphasis"><em>80.10</em></span> Support API for
correct collation (sorting order) on lists of strings in
locale-dependent way.</p><p>
<span class="emphasis"><em>80.20</em></span> For the Tcl API, we
will say that locale-dependent sorting will use Oracle SQL
operations (i.e., we won&#39;t provide a Tcl API for this). We
require a Tcl API function to return the correct incantation of
NLS_SORT to use for a given locale with <code class="literal">ORDER
BY</code> clauses in queries.</p><p>
<span class="emphasis"><em>80.40</em></span> The system must
handle full-text search in any supported language.</p>
</blockquote></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="VI.G_Time_Zones" id="VI.G_Time_Zones"></a>Time Zones</h3></div></div></div><div class="blockquote"><blockquote class="blockquote">
<p>
<span class="emphasis"><em>90.10</em></span> Provide API support
for specifying a time zone</p><p>
<span class="emphasis"><em>90.20</em></span> Provide an API for
computing time and date operations which are aware of timezones. So
for example a calendar module can properly synchronize items
inserted into a calendar from users in different time zones using
their own local times.</p><p>
<span class="emphasis"><em>90.30</em></span> Store all dates and
times in universal time zone, UTC.</p><p>
<span class="emphasis"><em>90.40</em></span> For a registered
users, a time zone preference should be stored.</p><p>
<span class="emphasis"><em>90.50</em></span> For a
non-registered user a time zone preference should be attached via a
session or else UTC should be used to display every date and
time.</p><p>
<span class="emphasis"><em>90.60</em></span> The default if we
can&#39;t determine a time zone is to display all dates and times
in some universal time zone such as GMT.</p>
</blockquote></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="VI.H_Database" id="VI.H_Database"></a>Database</h3></div></div></div><div class="blockquote"><blockquote class="blockquote"><p>
<span class="emphasis"><em>100.10</em></span> Since UTF8 strings
can use up to three (UCS2) or six (UCS4) bytes per character, make
sure that column size declarations in the schema are large enough
to accommodate required data (such as email addresses in Japanese).
<em><span class="remark">Since 5.0.0, this is covered in the
database install instructions for both PostgreSQL and
Oracle.</span></em>
</p></blockquote></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="VI.I_Email_and_Messaging" id="VI.I_Email_and_Messaging"></a>Email and Messaging</h3></div></div></div><p>When sending an email message, just as when delivering the
content in web page over an HTTP connection, it is necessary to be
able to specify what character set encoding to use, defaulting to
UTF-8.</p><div class="blockquote"><blockquote class="blockquote">
<p>
<span class="emphasis"><em>110.10</em></span> The email message
sending API will allow for a character set encoding to be
specified.</p><p>
<span class="emphasis"><em>110.20</em></span> The email
accepting API allows for character set to be parsed correctly (the
message has a MIME character set content type header)</p>
</blockquote></div><p>Mail is not internationalized. The following issues must be
addressed.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Many functions still call ns_sendmail. This means that there are
different end points for sending mail. This should be changed to
use the acs-mail-lite API instead.</p></li><li class="listitem"><p>Consumers of email services must do the following: Determine the
appropriate language or languages to use for the message subject
and message body and localize them (as in notifications).</p></li><li class="listitem"><p>Extreme Use case: Web site has a default language of Danish. A
forum is set up for Swedes, so the forum has a package_id and a
language setting of Swedish. A poster posts to the forum in Russian
(is this possible?). A user is subscribed to the forum and has a
language preference of Chinese. What should be in the message body
and message subject?</p></li><li class="listitem"><p>Incoming mail should be localized.</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="i18n-requirements-implementation-notes" id="i18n-requirements-implementation-notes"></a>Implementation
Notes</h3></div></div></div><p>Because globalization touches many different parts of the
system, we want to reduce the implementation risk by breaking the
implementation into phases.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="i18n-requirements-revision-history" id="i18n-requirements-revision-history"></a>Revision History</h3></div></div></div><div class="informaltable"><table class="informaltable" cellspacing="0" border="1">
<colgroup>
<col><col><col><col>
</colgroup><tbody>
<tr>
<td><span class="strong"><strong>Document Revision
#</strong></span></td><td><span class="strong"><strong>Action Taken,
Notes</strong></span></td><td><span class="strong"><strong>When?</strong></span></td><td><span class="strong"><strong>By Whom?</strong></span></td>
</tr><tr>
<td>1</td><td>Updated with results of MIT-sponsored i18n work at
Collaboraid.</td><td>14 Aug 2003</td><td>Joel Aufrecht</td>
</tr><tr>
<td>0.4</td><td>converting from HTML to DocBook and importing the document to
the OpenACS kernel documents. This was done as a part of the
internationalization of OpenACS and .LRN for the Heidelberg
University in Germany</td><td>12 September 2002</td><td>Peter Marklund</td>
</tr><tr>
<td>0.3</td><td>comments from Christian</td><td>1/14/2000</td><td>Henry Minsky</td>
</tr><tr>
<td>0.2</td><td>Minor typos fixed, clarifications to wording</td><td>11/14/2000</td><td>Henry Minsky</td>
</tr><tr>
<td>0.1</td><td>Creation</td><td>11/08/2000</td><td>Henry Minsky</td>
</tr>
</tbody>
</table></div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="db-api-detailed" leftLabel="Prev" leftTitle="Database Access API"
		    rightLink="security-requirements" rightLabel="Next" rightTitle="Security Requirements"
		    homeLink="index" homeLabel="Home" 
		    upLink="kernel-doc" upLabel="Up"> 
		