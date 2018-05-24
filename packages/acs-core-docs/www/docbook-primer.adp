
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {OpenACS Documentation Guide}</property>
<property name="doc(title)">OpenACS Documentation Guide</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="doc-standards" leftLabel="Prev"
			title="Chapter 13. Documentation
Standards"
			rightLink="psgml-mode" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="docbook-primer" id="docbook-primer"></a>OpenACS Documentation Guide</h2></div></div></div><p>By Claus Rasmussen, with additions by Roberto Mello, Vinod
Kurup, and the OpenACS Community</p><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="dbprimer-overview" id="dbprimer-overview"></a>Overview of OpenACS Documentation</h3></div></div></div><p>
<span class="productname">OpenACS</span>™ is a powerful system
with incredible possibilities and applications, but this power
comes with some complexity and a steep learning curve that is only
attenuated by good documentation. Our goal is to write superb
documentation, so that users, developers and administrators of
OpenACS installations can enjoy the system.</p><p>The history of OpenACS documentation: ..began by building on a
good documentation base from ArsDigita&#39;s ACS in the late
1990's. Some sections of the documentation, however, lacked
details and examples; others simply did not exist. The OpenACS
community began meeting the challenge by identifying needs and
writing documentation on an as needed basis.</p><p>By having documentation dependent on volunteers and code
developers, documentation updates lagged behind the evolving system
software. As significant development changes were made to the
system, existing documentation became dated, and its value
significantly reduced. The valiant efforts that were made to keep
the documentation current proved too difficult as changes to the
system sometimes had far-reaching affects to pages throughout the
documentation. System integration and optimization quickly rendered
documentation obsolete for developers. The code became the
substitute and source for documentation.</p><p>With thousands of lines of code and few developers tracking
changes, features and advances to the OpenACS system went unnoticed
or were not well understood except by the code authors. Work was
duplicated as a consequence of developers not realizing the
significant work completed by others. New developers had to learn
the system through experience with working with it and discussion
in the forums. Informal sharing of experiential and tacit knowledge
has become the OpenACS community&#39;s main method of sharing
knowledge.</p><p>This document attempts to shape ongoing documentation efforts by
using principles of continual improvement to re-engineer
documentation production.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="docs-managing" id="docs-managing"></a>Managing OpenACS Documentation</h3></div></div></div><p>Documentation production shares many of the challenges of
software development, such as managing contributions, revisions and
the (editorial) release cycle. This is yet another experiment in
improving documentation --this time by using principles of
continual improvement to focus the on-going efforts. These
processes are outlined as project management phases:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>
<span class="strong"><strong>Requirements phase</strong></span>
is about setting goals and specifications, and includes exploration
of scenarios, use cases etc. As an example, see the <a class="ulink" href="http://openacs.org/doc/openacs-4/requirements-template.html" target="_top">OpenACS Documentation Requirements Template</a> which
focuses on systems requirements for developers.</p></li><li class="listitem"><p>
<span class="strong"><strong>Strategy phase</strong></span> is
about creating an approach to doing work. It sets behavioral
guidelines and boundaries that help keep perspective on how efforts
are directed. OpenACS developers discuss strategy when coordinating
efforts such as code revisioning and new features.</p></li><li class="listitem"><p>
<span class="strong"><strong>Planning phase</strong></span> is
about explicitly stating the way to implement the strategy as a set
of methods. OpenACS system design requires planning. For example,
see <a class="ulink" href="http://openacs.org/doc/openacs-4/filename.html" target="_top">OpenACS documentation template</a> planning relating to
package design.</p></li><li class="listitem"><p>
<span class="strong"><strong>Implementation
phase</strong></span> is about performing the work according to the
plan, where decisions on how to handle unforeseen circumstances are
guided by the strategy and requirements.</p></li><li class="listitem"><p>
<span class="strong"><strong>Verification phase</strong></span>
measures how well the plan was implemented. Success is measured by
A) verifying if the project has met the established goals, and B)
reviewing for ongoing problem areas etc. OpenACS follows
verification through different means on different projects, but in
all cases, the OpenACS community verifies the project as a success
through feedback including bug reports, user and administrator
comments, and code changes.</p></li>
</ol></div><p>OpenACS forum discussions on documentation requirements and
strategies are summarized in the following sections. Production
phases are mainly organized and fulfilled by a designated
documentation maintainer. Hopefully the following sections will
help spur greater direct participation by the OpenACS
community.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="docs-requirements" id="docs-requirements"></a>OpenACS General Documentation
Requirements</h3></div></div></div><p>By the OpenACS Community. This section is a collection of
documentation requirements that have been expressed in the OpenACS
forums to 4th July 2003.</p><p>OpenACS documentation should meet the following requirements. No
significance has been given to the order presented, topic breadth
or depth here.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>clarity in presentation. <a class="ulink" href="http://www.lifewithqmail.org/lwq.html" target="_top">Life with
qmail</a> is a recommended example of "rated high" online
documentation.</p></li><li class="listitem"><p>Avoid requirements that significantly increase the labor
required to maintain documentation.</p></li><li class="listitem">
<p>Use best practices learned from the print world, web, and other
media, about use of gamma, space, writing style etc.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>Consistency in publishing -Establishing and adhering to
publishing standards</p></li><li class="listitem"><p>Use standardized language -Use international English (without
slang or colloquial terms) for ESL (English as a second language)
readers (and making translation easier for those interested in
translating the documentation for internationalization
efforts).</p></li><li class="listitem"><p>All jargon used in documentation needs to be defined. Use
standardized terms when available, avoiding implicit understanding
of specific OpenACS terms.</p></li><li class="listitem"><p>Document titles (for example on html pages) should include whole
document title (as in book title): (chapter title) : (section), so
that bookmarks etc. indicate location in a manner similar to pages
in books (in print publishing world).</p></li><li class="listitem"><p>Organize document according to the needs of the reader (which
may be different than the wishes of the writers).</p></li><li class="listitem"><p>Do not make informal exclamations about difficulty/ease for
users to complete tasks or understand... for example,
"Simply...". Readers come from many different backgrounds
--remember that the greater audience is likely as varied as the
readers on the internet--- If important, state pre-conditions or
knowledge requirements etc. if different than the rest of the
context of the document. For example, "requires basic
competency with a text-based editor such as vi or emacs via
telnet"</p></li>
</ul></div>
</li><li class="listitem">
<p>Show where to find current information instead of writing about
current info that becomes obsolete. If the information is not found
elsewhere, then create one place for it, where others can refer to
it. This structure of information will significantly reduce
obsolescence in writing and labor burden to maintain up-to-date
documentation. In other words, state facts in appropriately
focused, designated areas only, then refer to them by reference
(with links).</p><p>Note: Sometimes facts should be stated multiple ways, to
accommodate different reading style preferences. The should still
be in 1 area, using a common layout of perhaps summary,
introduction and discussion requiring increasing expertise,
complexity or specificity.</p>
</li><li class="listitem"><p>Consistency in link descriptions -When link urls refer to whole
documents, make the link (anchor wrapped title) that points to a
document with the same title and/or heading of the document.</p></li><li class="listitem"><p>Consider OpenACS documentation as a set of books (an
encyclopedic set organized like an atlas) that contains volumes
(books). Each book contains chapters and sections much like how
DocBook examples are shown, where each chapter is a web page. This
designation could help create an OpenACs book in print, and help
new readers visualize how the documentation is organized.</p></li><li class="listitem"><p>The use licenses between OpenACS and Arsdigita&#39;s ACS are not
compatible, thereby creating strict limits on how much OpenACS
developers should have access to Arsdigita code and resources. The
OpenACS documentation has a new legal requirement: to eliminate any
dependency on learning about the system from Arsdigita ACS examples
to minimize any inference of license noncompliance, while
recognizing the important work accomplished by Philip Greenspun,
Arsdigita, and the early ACS adopters.</p></li><li class="listitem">
<p>Use a consistent general outline for each book.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>Introduction (includes purpose/goal), Glossary of terms,
Credits, License, Copyright, Revision History</p></li><li class="listitem"><p>Table of Contents (TOC)s for each book: the end-users, content
and site administrators, marketing, developer tutorial, and
developers.</p></li><li class="listitem"><p>Priorities of order and content vary based on each of the
different readers mentioned. The developers guide should be
organized to be most useful to the priorities of developers, while
being consistent with the general documentation requirements
including publishing strategy, style etc.</p></li><li class="listitem">
<p>Use generic DocBook syntax to maximize reader familiarity with
the documents.</p><pre class="programlisting">
                &lt;book&gt;&lt;title&gt;&lt;part label="Part 1"&gt;&lt;etc...&gt;
              </pre>
</li>
</ul></div>
</li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="docs-end-user-reqs" id="docs-end-user-reqs"></a>OpenACS Documentation Requirements for
End-users</h3></div></div></div><p>By the OpenACS Community. This section is a collection of
documentation requirements that have been expressed in the OpenACS
forums to 4th July 2003.</p><p>OpenACS end-user documentation should meet the following
requirements. No significance has been given to the order
presented, topic breadth or depth here.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>End-users should not have to read docs to use the system.</p></li><li class="listitem"><p>Include how to get help. How and where to find answers, contact
others, what to do if one gets an AOLserver or other error when
using the system. Include types of available support (open-source,
private commercial etc.) including references.</p></li><li class="listitem"><p>Explain/foster understanding of the overall structure of the
system. This would be an overview of the system components, how it
works, and how to find out more or dig deeper... To promote the
system by presenting the history of the system, and writing about
some tacit knowledge re: OpenACS.org and the opensource
culture.</p></li><li class="listitem"><p>Introduce and inspire readers about the uses, benefits, and the
possibilities this system brings (think customer solution, customer
cost, convenience, value). A comprehensive community communications
system; How this system is valuable to users; Reasons others use
OpenACS (with quotes in their own words) "...the most
important thing that the ACS does is manage users, i.e. provide a
way to group, view and manipulate members of the web community. --
Talli Somekh, September 19, 2001" using it to communicate,
cooperate, collaborate... OpenACS offers directed content
functionality with the OpenACS templating system. ... OpenACS is
more than a data collection and presentation tool. OpenACS has
management facilities that are absent in other portals. ...The
beauty of OpenACS is the simplicity (and scalability) of the
platform on which it is built and the library of tried and tested
community building tools that are waiting to be added. It seems
that most portals just add another layer of complexity to the cake.
See <a class="ulink" href="http://openacs.org/bboard/q-and-a-fetch-msg.tcl?msg_id=00058H&amp;topic_id=11&amp;topic=OpenACS" target="_top">Slides on OACS features</a>...a set of slides on OACS
features that can be used for beginners who want to know OACS is
about and what they can do with it. Screen captures that highlight
features. Example shows BBoard, calendar, news, file storage, wimpy
point, ticket tracking. An OpenACS tour; an abbreviated,
interactive set of demo pages.</p></li><li class="listitem">
<p>From a marketing perspective,</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>differentiate "product" by highlighting features,
performance quality, conformance to standards, durability (handling
of technological obsolescence), reliability, repairability, style
of use, design (strategy in design, specifications, integrated,
well-matched systems etc).</p></li><li class="listitem"><p>differentiate "service" by highlighting software
availability (licensing and completeness from mature to early
adopters or development versions), community incident support,
project collaborative opportunities, and contractor support
availability</p></li><li class="listitem"><p>differentiate price (economic considerations of opensource and
features)</p></li><li class="listitem"><p>Discussion and details should rely on meeting criteria of
design, completeness of implementation, and related system
strengths and weaknesses. Marketing should not rely on comparing to
other technologies. Competitive analysis involves mapping out
strengths, weaknesses, opportunities and threats when compared to
other systems for a specific purpose, and thus is inappropriate
(and becomes stale quickly) for general documentation.</p></li><li class="listitem"><p>When identifying subsystems, such as tcl, include links to their
marketing material if available.</p></li><li class="listitem"><p>create an example/template comparison table that shows versions
of OpenACS and other systems (commonly competing against OpenACS)
versus a summary feature list and how well each meets the feature
criteria. Each system should be marked with a date to indicate time
information was gathered, since information is likely volatile.</p></li>
</ul></div>
</li><li class="listitem"><p>To build awareness about OpenACS, consider product
differentiation: form, features, performance quality, conformance
quality (to standards and requirements), durability, reliability,
repairability, style, design: the deliberate planning of these
product attributes.</p></li><li class="listitem"><p>Include jargon definitions, glossary, FAQs, site map/index,
including where to find Instructions for using the packages. FAQ
should refer like answers to the same place for consistency,
brevity and maintainability.</p></li><li class="listitem"><p>Explain/tutorial on how the UI works (links do more than go to
places, they are active), Page flow, descriptions of form elements;
browser/interface strengths and limitations (cookies, other)</p></li><li class="listitem"><p>Discuss criteria used to decide which features are important,
and the quality of the implementation from a users perspective.
Each project implementation places a different emphasis on the
various criteria, which is why providing a framework to help decide
is probably more useful than an actual comparison.</p></li>
</ul></div><p>Package documentation requirements have additional
requirements.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>A list of all packages, their names, their purposes, what they
can and cannot do (strengths, limitations), what differentiates
them from similar packages, minimal description, current version,
implementation status, author/maintainers, link(s) to more info.
Current version available at the <a class="ulink" href="http://openacs.org/repository/5-2/" target="_top">repository</a>.</p></li><li class="listitem"><p>Include dependencies/requirements, known conflicts, and comments
from the real world edited into a longer description to quickly
learn if a package is appropriate for specific projects.</p></li><li class="listitem"><p>Create a long bulleted list of features. Feature list should go
deeper than high-level feature lists and look at the quality of the
implementations (from the user&#39;s perspective, not the
programmer&#39;s). Example issues an end-user may have questions
about: Ticket Tracker and Ticket Tracker Lite, why would I want one
of them vs the other? And, before I specify to download and install
it, what credit card gateways are supported by the current
e-commerce module? There are some packages where the name is clear
enough, but what are the limitations of the standard package?</p></li><li class="listitem"><p>End-user docs should not be duplicative. The package description
information and almost everything about a package for
administrators and developers is already described in the package
itself through two basic development document templates: a
<a class="ulink" href="http://openacs.org/doc/current/requirements-template.html" target="_top">Requirements Template</a> and <a class="ulink" href="http://openacs.org/doc/current/filename.html" target="_top">Detailed Design Document</a>.</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="docs-admin-reqs" id="docs-admin-reqs"></a>OpenACS Documentation Requirements for Site
and Administrators</h3></div></div></div><p>By the OpenACS Community. This section is a collection of
documentation requirements that have been expressed in the OpenACS
forums to 4th July 2003.</p><p>OpenACS administrators' documentation should meet the
following requirements. No significance has been given to the order
presented, topic breadth or depth here.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>For each requirement below, include links to developer tutorials
and other documentation for more detail.</p></li><li class="listitem"><p>Describe a structural overview of a working system and how the
components work together. "The Layered Cake view" a
general network view of system; a table showing system levels
versus roles to help with understanding how the subsystems are
interconnected.</p></li><li class="listitem"><p>Provide a comprehensive description of typical administrative
processes for operating an OpenACS system responsibly, including
reading logs and command line views that describe status of various
active processes.</p></li><li class="listitem"><p>Create a list of administrative tools that are useful to
administrating OpenACS, including developer support, schema-browser
and API browser. Link to AOLserver&#39;s config file
documentation.</p></li><li class="listitem"><p>Resources on high level subjects such as web services, security
guidelines</p></li><li class="listitem"><p>Describe typical skill sets (and perhaps mapped to standardized
job titles) for administrating an OpenACS system (human-resources
style). For a subsite admin/moderator attributes might include
trustworthy, sociable, familiarity with the applications and
subsystems, work/group communication skills et cetera</p></li><li class="listitem"><p>Describe how to set up typical site moderation and
administration including parameters, permissions, "Hello
World" page</p></li><li class="listitem"><p>Show directory structure of a typical package, explanation of
the various file types in a package (tcl,adp,xql) and how those
relate to the previously described subsystems, when they get
refreshed etc.</p></li><li class="listitem"><p>Ways to build a "Hello World" page</p></li><li class="listitem"><p>Show examples of how the OpenACS templating system is used,
including portal sections of pages. For example, create a
customised auto-refreshing startpage using lars-blogger, a photo
gallery, and latest posts from a forum. This should rely heavily on
documentation existing elsewhere to keep current. This would
essentially be a heavily annotated list of links.</p></li><li class="listitem"><p>Show ways of modifying the look and feel across pages of an
OpenACS website. Refer to the skins package tutorial.</p></li><li class="listitem"><p>Describe a methodology for diagnosing problems, finding error
statements and interpreting them --for OpenACS and the underlying
processes.</p></li><li class="listitem"><p>FAQs: Administration tasks commonly discussed on boards: admin
page flow, how to change the looks of a subsite with a new
master.adp, options on "user pages" , a quick
introduction to the functions and processes. info about the user
variables, file locations</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="docs-install-reqs" id="docs-install-reqs"></a>OpenACS Installation Documentation
Requirements</h3></div></div></div><p>By the OpenACS Community. This section is a collection of
documentation requirements that have been expressed in the OpenACS
forums to 4th July 2003.</p><p>OpenACS installation documentation should meet the following
requirements. No significance has been given to the order
presented, topic breadth or depth here.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>state installation prerequisites. For example: "You should
read through the installation process to familiarize yourself with
the installation process, before beginning an
installation."</p></li><li class="listitem"><p>list critical decisions (perhaps as questions) that need to be
made before starting: which OS, which DB, which AOLserver version,
system name, dependencies et cetera. Maybe summarize options as
tables or decision-trees. For example, "As you proceed
throughout the installation, you will be acting on decisions that
have an impact on how the remaining part of the system is
installed. Here is a list of questions you should answer before
beginning."</p></li><li class="listitem"><p>list pre-installation assumptions</p></li><li class="listitem"><p>Show chronological overview of the process of installing a
system to full working status: Install operating system with
supporting software, configure with preparations for OpenACS,
RDBMS(s) install and configure, Webserver install and configure,
OpenACS install and configure, post-install work</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="docs-developer-tutorial-reqs" id="docs-developer-tutorial-reqs"></a>OpenACS Developer Tutorial
Documentation Requirements</h3></div></div></div><p>By the OpenACS Community. This section is a collection of
documentation requirements that have been expressed in the OpenACS
forums to 4th July 2003.</p><p>OpenACS developer tutorial documentation should meet the
following requirements. No significance has been given to the order
presented, topic breadth or depth here.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>list learning prerequisites to customize, fix, and improve OACS
modules, and create new ones. You are expected to have read and
understand the information [minimum requirements similar to adept
at Using OpenACS Administrating Guide] before reading this
guide.</p></li><li class="listitem"><p>Refer to development documentation instead of duplicating
here</p></li><li class="listitem"><p>List suggestions for installing and setting up a development
environment; these can be annotated links to the installation
documentation</p></li><li class="listitem"><p>Provide working examples that highlight the various subsystems,
Tcl environment, OpenACS protocols, AOLserver template and ns_*
commands, OpenACS templating, sql queries, db triggers, scheduling
protocols, how to use the page contract, how to get the accessing
user_id etc</p></li><li class="listitem"><p>Show how to construct basic SQL queries using the db API,</p></li><li class="listitem"><p>The life of an http request to a dynamic, templated page</p></li><li class="listitem"><p>General rules to follow for stability, scalability</p></li><li class="listitem"><p>Show the step by step customizing of an existing package that
meets current recommended coding styles of OpenACS package
development, by referring to developer resources.</p></li><li class="listitem"><p>Use the ArsDigita problem sets and "what Lars produced for
ACS Java" as inspiration for a PostgreSQL equivalent tutorial
about developing a new OpenACS package including discussion of the
significance of the package documentation templates</p></li><li class="listitem"><p>Include a summary of important links used by developers</p></li><li class="listitem"><p>Note any deprecated tools and methods by linking to prior
versions instead of describing them in current docs</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="docs-developer-reqs" id="docs-developer-reqs"></a>OpenACS Developer Documentation
Requirements</h3></div></div></div><p>By the OpenACS Community. This section is a collection of
documentation requirements that have been expressed in the OpenACS
forums to 4th July 2003.</p><p>OpenACS developer documentation should meet the following
requirements. No significance has been given to the order
presented, topic breadth or depth here.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>list documentation assumptions, such as familiarity with
modifying OpenACS packages. All kernel docs are here etc.</p></li><li class="listitem"><p>This documentation should be written for ongoing use by
developers, not as a tutorial.</p></li><li class="listitem"><p>List of practical development and diagnostics tools and
methodologies.</p></li><li class="listitem"><p>List of OpenACS development resources, api-doc, schema-browser,
developer-support package etc.</p></li><li class="listitem"><p>Identify each OpenACS subsystem, explain why it is used (instead
of other choices). In the case of subsystems that are developed
outside of OpenACS such as tcl, include external references to
development and reference areas.</p></li><li class="listitem"><p>Show current engineering standards and indicate where changes to
the standards are in the works.</p></li><li class="listitem"><p>Sections should be dedicated to DotLRN standards as well, if
they are not available elsewhere.</p></li><li class="listitem"><p>Add overview diagrams showing the core parts of the datamodel
including an updated summary of Greenspun&#39;s Chapter 4: Data
Models and the Object System</p></li><li class="listitem"><p>package design guidelines and development process templates
including planning, core functions, testing, usability, and
creating case studies</p></li><li class="listitem">
<p>Standard package conventions, where to see "model"
code, and guidelines (or where to find them) for:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>programming tcl/sql</p></li><li class="listitem"><p>using the acs-api</p></li><li class="listitem"><p>ad_form</p></li><li class="listitem"><p>coding permissions</p></li><li class="listitem"><p>OpenACS objects</p></li><li class="listitem"><p>scheduled protocols</p></li><li class="listitem"><p>call backs</p></li><li class="listitem"><p>directory structure</p></li><li class="listitem"><p>user interface</p></li><li class="listitem"><p>widgets</p></li><li class="listitem"><p>package_name and type_extension_table</p></li><li class="listitem"><p>adding optional services, including search, general comments,
attachments, notifications, workflow, CR and the new CR Tcl API</p></li>
</ul></div>
</li><li class="listitem"><p>Document kernel coding requirements, strategy and guidelines to
help code changers make decisions that meet kernel designers'
criteria</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="doc-strategy" id="doc-strategy"></a>OpenACS Documentation Strategy</h3></div></div></div><p>OpenACS documentation development is subject to the constraints
of the software project development and release methods and cycles
(<a class="xref" href="cvs-guidelines" title="Using CVS with OpenACS">the section called “Using CVS with
OpenACS”</a>). Essentially, all phases of work may be active to
accommodate the asynchronous nature of multiple subprojects
evolving by the efforts of a global base of participants with
culturally diverse time references and scheduling
idiosyncrasies.</p><p>The documentation strategy is to use project methods to involve
others by collaborating or obtaining guidance or feedback (peer
review) to distribute the workload and increase the overall value
of output for the OpenACS project.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="dbprimer-why" id="dbprimer-why"></a>OpenACS Documentation Strategy: Why
DocBook?</h3></div></div></div><p>OpenACS documentation is taking a dual approach to publishing.
Documentation that is subject to rapid change and participation by
the OpenACS community is managed through the <a class="ulink" href="http://openacs.org/xowiki/pages/en/Documentation_Project" target="_top">OpenACS xowiki Documentation Project</a> Formal documents
that tend to remain static and require more expressive publishing
tools will be marked up to conform to the <a class="ulink" href="http://docbook.org/xml/index.html" target="_top">DocBook XML
DTD</a>. The remaining discussion is about publishing using
Docbook.</p><p>
<a class="indexterm" name="idp140682193502840" id="idp140682193502840"></a> is a publishing standard based on XML
with similar goals to the OpenACS Documentation project. Some
specific reasons why we are using DocBook:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>It is open-source.</p></li><li class="listitem"><p>The DocBook community <a class="ulink" href="http://docbook.org/help" target="_top">mailing lists</a>
</p></li><li class="listitem"><p>A number of free and commercial <a class="ulink" href="https://github.com/docbook/wiki/wiki/DocBookTools" target="_top">tools</a> are available for editing and publishing DocBook
documents.</p></li><li class="listitem"><p>It enables us to publish in a variety of formats.</p></li><li class="listitem"><p>XML separates content from presentation: It relieves each
contributor of the burden of presentation, freeing each writer to
focus on content and sharing knowledge.</p></li><li class="listitem"><p>It is well tested technology. It has been in development since
the <a class="ulink" href="http://docbook.org/tdg/en/html/ch01.html#d0e2132" target="_top">early 1990's</a>).</p></li>
</ul></div><p>Reasons why we are using Docbook XML instead of Docbook
SGML:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>
<span class="emphasis"><em>Consistency</em></span> and history.
We started with a collection of DocBook XML files that ArsDigita
wrote. Trying to re-write them to conform to the SGML DTD would be
unnecessary work.</p></li><li class="listitem"><p>
<span class="emphasis"><em>XML does not require extra
effort</em></span>. Writing in XML is almost identical to SGML,
with a couple extra rules. More details in the <a class="ulink" href="http://www.tldp.org/LDP/LDP-Author-Guide/html/index.html" target="_top">LDP Author Guide</a>.</p></li><li class="listitem"><p>
<span class="emphasis"><em>The tool chain has
matured</em></span>. xsltproc and other XML based tools have
improved to the point where they are about as good as the SGML
tools. Both can output html and pdf formats.</p></li>
</ul></div><p>Albeit, the road to using DocBook has had some trials. In 2002,
Docbook still was not fully capable of representing online books as
practiced by book publishers and expected from readers with regards
to usability on the web. That meant DocBook did not entirely meet
OpenACS publishing requirements at that time.</p><p>In 2004, Docbook released version 4.4, which complies with all
the OpenACS publishing requirements. Producing a web friendly book
hierarchy arguably remains DocBooks' weakest point. For
example, a dynamically built document should be able to extract
details of a specific reference from a bibliographic (table) and
present a footnote at the point where referenced. DocBook 4.4
allows for this with <code class="computeroutput">bibliocoverage</code>, <code class="computeroutput">bibliorelation</code>, and <code class="computeroutput">bibliosource</code>. <a class="ulink" href="http://www.docbook.org/tdg/en/html/docbook.html" target="_top">DocBook: The Definitive Guide</a> is a good start for
learning how to represent paper-based books online.</p><p>The following DocBook primer walks you through the basics, and
should cover the needs for 95 percent of the documentation we
produce. You are welcome to explore DocBook&#39;s <a class="ulink" href="http://docbook.org/tdg/en/html/part2.html" target="_top">list
of elements</a> and use more exotic features in your documents. The
list is made up of SGML-elements but basically the same elements
are valid in the XML DTD <span class="strong"><strong>as long as
you remember to</strong></span>: <a class="indexterm" name="idp140682193521704" id="idp140682193521704"></a>
</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Always close your tags with corresponding end-tags and to
<span class="strong"><strong>not use other tag
minimization</strong></span>
</p></li><li class="listitem"><p>Write all elements and attributes in lowercase</p></li><li class="listitem"><p>Quote all attributes</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="dbprimer-validation" id="dbprimer-validation"></a>Tools</h3></div></div></div><p>You are going to need the following to work with the OpenACS
Docbook XML documentation:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>
<a class="ulink" href="http://docbook.org/xml/index.html" target="_top">Docbook XML DTD</a> - The document type definition
for XML. You can find an RPM or DEB package or you can download a
zip file from the site linked from here.</p></li><li class="listitem"><p>
<a class="ulink" href="http://sourceforge.net/projects/docbook/" target="_top">XSL Stylesheets</a> (docbook-xsl) - The stylesheets
to convert to HTML. We have been using a stylesheet based upon
NWalsh&#39;s chunk.xsl.</p></li><li class="listitem"><p>
<code class="computeroutput">xsltproc</code> - The processor
that will take an XML document and, given a xsl stylesheet, convert
it to HTML. It needs libxml2 and libxslt (available in RPM and DEB
formats or from <a class="ulink" href="http://xmlsoft.org/" target="_top">xmlsoft.org</a>.</p></li><li class="listitem"><p>Some editing tool. A popular one is Emacs with the psgml and
nXML modes. The <a class="ulink" href="http://www.tldp.org/LDP/LDP-Author-Guide/html/index.html" target="_top">LDP Author Guide</a> and <a class="ulink" href="https://github.com/docbook/wiki/wiki/DocBookTools" target="_top">DocBook Wiki</a> list some alternates.</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="dbprimer-new-doc" id="dbprimer-new-doc"></a>Writing New Docs</h3></div></div></div><p>After you have the tools mentioned above, you need to define a
title for your document. Then start thinking about the possible
sections and subsections you will have in your document. Make sure
you coordinate with the OpenACS Gatekeepers to make sure you are
not writing something that someone else is already writing. Also,
if you desire to use the OpenACS CVS repository, please e-mail the
gatekeeper in charge of documentation.</p><p>You can look at some templates for documents (in Docbook XML) in
the <a class="ulink" href="https://github.com/openacs/openacs-core/tree/oacs-5-9/packages/acs-core-docs/www/xml/engineering-standards" target="_top">sources for acs-core-docs</a>, especially the
<span class="emphasis"><em>Detailed Design Documentation
Template</em></span> and the <span class="emphasis"><em>System/Application Requirements
Template</em></span>.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="dbprimer-structure" id="dbprimer-structure"></a>Document Structure</h3></div></div></div><p>The documentation for each package will make up a little
"book" that is structured like this - examples are
<span class="emphasis"><em>emphasized</em></span>: <a class="indexterm" name="idp140682193542808" id="idp140682193542808"></a>
</p><pre class="programlisting">
    book                        : <span class="strong"><strong>Docs for one package</strong></span> - <span class="emphasis"><em>templating</em></span>
     |
     +--chapter                 : <span class="strong"><strong>One section</strong></span> - <span class="emphasis"><em>for developers</em></span>
         |
---------+------------------------------------------------------
         |
         +--sect1               : <span class="strong"><strong>Single document</strong></span> - <span class="emphasis"><em>requirements</em></span>
             |
             +--sect2           : <span class="strong"><strong>Sections</strong></span> - <span class="emphasis"><em>functional requirements</em></span>
                 |
                 +--sect3       : <span class="strong"><strong>Subsections</strong></span> - <span class="emphasis"><em>Programmer&#39;s API</em></span>
                     |
                    ...         : <span class="strong"><strong>...</strong></span>
</pre><p>The actual content is split up into documents that start at a
<code class="computeroutput">sect1</code>-level. These are then
tied together in a top-level document that contains all the
information above the line. This will be explained in more detail
in a later document, and we will provide a set of templates for
documenting an entire package.</p><p>For now you can take a look at the <a class="ulink" href="https://github.com/openacs/openacs-core/tree/oacs-5-9/packages/acs-core-docs/www/xml/engineering-standards" target="_top">sources of these DocBook documents</a> to get an idea
of how they are tied together.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="dbprimer-sections" id="dbprimer-sections"></a>Headlines, Sections</h3></div></div></div><p>
<a class="indexterm" name="idp140682193554664" id="idp140682193554664"></a> Given that your job starts at the
<code class="computeroutput">sect1</code>-level, all your documents
should open with a <a class="ulink" href="http://docbook.org/tdg/en/html/sect1.html" target="_top"><code class="computeroutput">&lt;sect1&gt;</code></a>-tag
and end with the corresponding <code class="computeroutput">&lt;/sect1&gt;</code>.</p><p>
<a class="indexterm" name="idp140682193559080" id="idp140682193559080"></a> You need to feed every <code class="computeroutput">&lt;sect1&gt;</code> two attributes. The first
attribute, <code class="computeroutput">id</code>, is standard and
can be used with all elements. It comes in very handy when
interlinking between documents (more about this when talking about
links in <a class="xref" href="docbook-primer" title="Links">the section called “Links”</a>). The value of
<code class="computeroutput">id</code> has to be unique throughout
the book you&#39;re making since the <code class="computeroutput">id</code>'s in your <code class="computeroutput">sect1</code>'s will turn into filenames when
the book is parsed into HTML.</p><p>
<a class="indexterm" name="idp140682193563912" id="idp140682193563912"></a> The other attribute is <code class="computeroutput">xreflabel</code>. The value of this is the text
that will appear as the link when referring to this <code class="computeroutput">sect1</code>.</p><p>Right after the opening tag you put the title of the document -
this is usually the same as <code class="computeroutput">xreflabel</code>-attribute. E.g. the top level of
the document you&#39;re reading right now looks like this:</p><pre class="programlisting">
&lt;sect1 id="docbook-primer" xreflabel="DocBook Primer"&gt;
  &lt;title&gt;DocBook Primer&lt;/title&gt;

...

&lt;/sect1&gt;
</pre><p>
<a class="indexterm" name="idp140682186069336" id="idp140682186069336"></a> Inside this container your document will
be split up into <a class="ulink" href="http://docbook.org/tdg/en/html/sect2.html" target="_top"><code class="computeroutput">&lt;sect2&gt;</code></a>'s,
each with the same requirements - <code class="computeroutput">id</code> and <code class="computeroutput">xreflabel</code> attributes, and a <code class="computeroutput">&lt;title&gt;</code>-tag inside. Actually, the
<code class="computeroutput">xreflabel</code> is never required in
sections, but it makes linking to that section a lot easier.</p><p>When it comes to naming your <code class="computeroutput">sect2</code>'s and below, prefix them with
some abbreviation of the <code class="computeroutput">id</code> in
the <code class="computeroutput">sect1</code> such as <code class="computeroutput">requirements-overview</code>.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="dbprimer-code" id="dbprimer-code"></a>Code</h3></div></div></div><p>
<a class="indexterm" name="idp140682186055096" id="idp140682186055096"></a> For displaying a snippet of code, a
filename or anything else you just want to appear as a part of a
sentence, we use <a class="ulink" href="http://docbook.org/tdg/en/html/computeroutput.html" target="_top"><code class="computeroutput">&lt;computeroutput&gt;</code></a> and <a class="ulink" href="http://docbook.org/tdg/en/html/code.html" target="_top"><code class="code">&lt;code&gt;</code></a> tags. These
replace the HTML-tag <code class="code">&lt;code&gt;</code> tag,
depending on whether the tag is describing computer output or
computer code.</p><p>For bigger chunks of code such as SQL-blocks, the tag <a class="ulink" href="http://docbook.org/tdg/en/html/programlisting.html" target="_top"><code class="computeroutput">&lt;programlisting&gt;</code></a> is used. Just
wrap your code block in it; mono-spacing, indents and all that
stuff is taken care of automatically.</p><p>For expressing user interaction via a terminal window, we wrap
the <a class="ulink" href="http://docbook.org/tdg/en/html/screen.html" target="_top"><code class="computeroutput">&lt;screen&gt;</code></a> tag
around text that has been wrapped by combinations of <a class="ulink" href="http://docbook.org/tdg/en/html/computeroutput.html" target="_top"><code class="computeroutput">&lt;computeroutput&gt;</code></a> and <a class="ulink" href="http://docbook.org/tdg/en/html/userinput.html" target="_top"><strong class="userinput"><code>&lt;userinput&gt;</code></strong></a>
</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="dbprimer-links" id="dbprimer-links"></a>Links</h3></div></div></div><p>
<a class="indexterm" name="idp140682186045448" id="idp140682186045448"></a> Linking falls into two different
categories: inside the book you&#39;re making and outside:</p><div class="variablelist"><dl class="variablelist">
<dt><span class="term"><span class="strong"><strong>1. Inside
linking, cross-referencing other parts of your
book</strong></span></span></dt><dd>
<p>By having unique <code class="computeroutput">id</code>'s
you can cross-reference any part of your book with a simple tag,
regardless of where that part is.</p><p>
<a class="indexterm" name="idp140682186031576" id="idp140682186031576"></a>Check out how I link to a subsection of
the Developer&#39;s Guide:</p><p>Put this in your XML:</p><pre class="programlisting">
- Find information about creating a package in
&lt;xref linkend="packages-making-a-package"&gt;&lt;/xref&gt;.
</pre><p>And the output is:</p><pre class="programlisting">
- Find information about creating a package in 
<a class="xref" href="packages" title="Making a Package">Making a Package</a>.
</pre><p>Note that even though this is an empty tag, you have to
either:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>Provide the end-tag, <code class="computeroutput">&lt;/xref&gt;</code>, or</p></li><li class="listitem"><p>Put a slash before the ending-bracket: <code class="computeroutput">&lt;xref
linkend="blahblah"/&gt;</code>
</p></li>
</ol></div><p>If the section you link to hasn&#39;t a specified <code class="computeroutput">xreflabel</code>-attribute, the link is going to
look like this:</p><p>Put this in your XML:</p><pre class="programlisting">
-Find information about what a package looks like in 
&lt;xref linkend="packages-looks"&gt;&lt;/xref&gt;.
</pre><p>And the output is:</p><pre class="programlisting">
- Find information about what a package looks like in 
<a class="xref" href="packages" title="What a Package Looks Like">the section called “What a Package Looks Like”</a>.
</pre><p>Note that since I haven&#39;t provided an <code class="computeroutput">xreflabel</code> for the subsection, <code class="computeroutput">packages-looks</code>, the parser will try its
best to explain where the link takes you.</p>
</dd><dt><span class="term"><span class="strong"><strong>2. Linking
outside the documentation</strong></span></span></dt><dd>
<p>
<a class="indexterm" name="idp140682186011816" id="idp140682186011816"></a> If you&#39;re hyper-linking out of the
documentation, it works almost the same way as HTML - the tag is
just a little different (<a class="ulink" href="http://docbook.org/tdg/en/html/ulink.html" target="_top"><code class="computeroutput">&lt;ulink&gt;</code></a>):</p><pre class="programlisting">
&lt;ulink url="http://www.oracle.com/"&gt;Oracle Corporation&lt;/ulink&gt;</pre><p>....will create a hyper-link to Oracle in the HTML-version of
the documentation.</p><p>
<span class="strong"><strong>NOTE:</strong></span> Do NOT use
ampersands in your hyperlinks. These are reserved for referencing
<a class="ulink" href="http://www.docbook.org/tdg/en/html/ch01.html#s-entities" target="_top">entities</a>. To create an ampersand, use the entity
<code class="code">&amp;amp;</code>
</p>
</dd>
</dl></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="dbprimer-graphics" id="dbprimer-graphics"></a>Graphics</h3></div></div></div><p><span class="emphasis"><em>
<span class="strong"><strong>Note:</strong></span> The graphics guidelines are
not written in stone. Use another valid approach if it works better
for you.</em></span></p><p>
<a class="indexterm" name="idp140682185999096" id="idp140682185999096"></a> To insert a graphic we use the elements
<a class="ulink" href="http://docbook.org/tdg/en/html/mediaobject.html" target="_top"><code class="computeroutput">&lt;mediaobject&gt;</code></a>,
<a class="ulink" href="http://docbook.org/tdg/en/html/imageobject.html" target="_top"><code class="computeroutput">&lt;imageobject&gt;</code></a>,
<a class="ulink" href="http://docbook.org/tdg/en/html/imagedata.html" target="_top"><code class="computeroutput">&lt;imagedata&gt;</code></a>,
and <a class="ulink" href="http://docbook.org/tdg/en/html/textobject.html" target="_top"><code class="computeroutput">&lt;textobject&gt;</code></a>.
Two versions of all graphics are required. One for the Web (usually
a JPEG or GIF), and a brief text description. The description
becomes the ALT text. You can also supply a version for print
(EPS).</p><pre class="programlisting">
&lt;mediaobject&gt;
  &lt;imageobject&gt;
    &lt;imagedata fileref="images/rp-flow.gif" format="GIF" align="center"/&gt;
  &lt;/imageobject&gt;
  &lt;imageobject&gt;
    &lt;imagedata fileref="images/rp-flow.eps" format="EPS" align="center"/&gt;
  &lt;/imageobject&gt;
  &lt;textobject&gt;
    &lt;phrase&gt;This is an image of the flow in the Request Processor&lt;/phrase&gt;
  &lt;/textobject&gt;
&lt;/mediaobject&gt;
</pre><p>Put your graphics in a separate directory ("images")
and link to them only with relative paths.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="dbprimer-lists" id="dbprimer-lists"></a>Lists</h3></div></div></div><p>
<a class="indexterm" name="idp140682185988600" id="idp140682185988600"></a> Here&#39;s how you make the DocBook
equivalent of the three usual HTML-lists:</p><div class="variablelist"><dl class="variablelist">
<dt><span class="term"><span class="strong"><strong>1. How to make
an &lt;ul&gt;</strong></span></span></dt><dd>
<p>Making an unordered list is pretty much like doing the same
thing in HTML - if you close your <code class="computeroutput">&lt;li&gt;</code>, that is. The only differences
are that each list item has to be wrapped in something more, such
as <code class="computeroutput">&lt;para&gt;</code>, and that the
tags are called <a class="ulink" href="http://docbook.org/tdg/en/html/itemizedlist.html" target="_top"><code class="computeroutput">&lt;itemizedlist&gt;</code></a>
and <a class="ulink" href="http://docbook.org/tdg/en/html/listitem.html" target="_top"><code class="computeroutput">&lt;listitem&gt;</code></a>:</p><pre class="programlisting">
&lt;itemizedlist&gt;

  &lt;listitem&gt;&lt;para&gt;Stuff goes here&lt;/para&gt;&lt;/listitem&gt;
  &lt;listitem&gt;&lt;para&gt;More stuff goes here&lt;/para&gt;&lt;/listitem&gt;

&lt;/itemizedlist&gt;
</pre>
</dd><dt><span class="term"><span class="strong"><strong>2. How to make
an &lt;ol&gt;</strong></span></span></dt><dd>
<p>The ordered list is like the preceding, except that you use
<a class="ulink" href="http://docbook.org/tdg/en/html/orderedlist.html" target="_top"><code class="computeroutput">&lt;orderedlist&gt;</code></a>
instead:</p><pre class="programlisting">
&lt;orderedlist&gt;

  &lt;listitem&gt;&lt;para&gt;Stuff goes here&lt;/para&gt;&lt;/listitem&gt;
  &lt;listitem&gt;&lt;para&gt;More stuff goes here&lt;/para&gt;&lt;/listitem&gt;

&lt;/orderedlist&gt;
</pre>
</dd><dt><span class="term"><span class="strong"><strong>3. How to make
a &lt;dl&gt;</strong></span></span></dt><dd>
<p>This kind of list is called a <code class="computeroutput">variablelist</code> and these are the tags
you&#39;ll need to make it happen: <a class="ulink" href="http://docbook.org/tdg/en/html/variablelist.html" target="_top"><code class="computeroutput">&lt;variablelist&gt;</code></a>, <a class="ulink" href="http://docbook.org/tdg/en/html/varlistentry.html" target="_top"><code class="computeroutput">&lt;varlistentry&gt;</code></a>, <a class="ulink" href="http://docbook.org/tdg/en/html/term.html" target="_top"><code class="computeroutput">&lt;term&gt;</code></a> and
<a class="ulink" href="http://docbook.org/tdg/en/html/listitem.html" target="_top"><code class="computeroutput">&lt;listitem&gt;</code></a>:</p><pre class="programlisting">
&lt;variablelist&gt;

  &lt;varlistentry&gt;
    &lt;term&gt;Heading (&lt;dt&gt;) goes here&lt;/term&gt;
    &lt;listitem&gt;&lt;para&gt;And stuff (&lt;dd&gt;)goes here&lt;/para&gt;&lt;/listitem&gt;
  &lt;/varlistentry&gt;

  &lt;varlistentry&gt;
    &lt;term&gt;Another heading goes here&lt;/term&gt;
    &lt;listitem&gt;&lt;para&gt;And more stuff goes here&lt;/para&gt;&lt;/listitem&gt;
  &lt;/varlistentry&gt;

&lt;/variablelist&gt;
</pre>
</dd>
</dl></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="dbprimer-tables" id="dbprimer-tables"></a>Tables</h3></div></div></div><p>
<a class="indexterm" name="idp140682185965944" id="idp140682185965944"></a> DocBook supports several types of tables,
but in most cases, the <a class="ulink" href="http://docbook.org/tdg/en/html/informaltable.html" target="_top"><code class="computeroutput">&lt;informaltable&gt;</code></a> is enough:</p><pre class="programlisting">
&lt;informaltable frame="all"&gt;
  &lt;tgroup cols="3"&gt;
    &lt;tbody&gt;

      &lt;row&gt;
        &lt;entry&gt;a1&lt;/entry&gt;
        &lt;entry&gt;b1&lt;/entry&gt;
        &lt;entry&gt;c1&lt;/entry&gt;
      &lt;/row&gt;

      &lt;row&gt;
        &lt;entry&gt;a2&lt;/entry&gt;
        &lt;entry&gt;b2&lt;/entry&gt;
        &lt;entry&gt;c2&lt;/entry&gt;
      &lt;/row&gt;

      &lt;row&gt;
        &lt;entry&gt;a3&lt;/entry&gt;
        &lt;entry&gt;b3&lt;/entry&gt;
        &lt;entry&gt;c3&lt;/entry&gt;
      &lt;/row&gt;

    &lt;/tbody&gt;
  &lt;/tgroup&gt;
&lt;/informaltable&gt;
</pre><p>With our current XSL-style-sheet, the output of the markup above
will be a simple HTML-table:</p><div class="informaltable"><table class="informaltable" cellspacing="0" border="1">
<colgroup>
<col><col><col>
</colgroup><tbody>
<tr>
<td>a1</td><td>b1</td><td>c1</td>
</tr><tr>
<td>a2</td><td>b2</td><td>c2</td>
</tr><tr>
<td>a3</td><td>b3</td><td>c3</td>
</tr>
</tbody>
</table></div><p>If you want cells to span more than one row or column, it gets a
bit more complicated - check out <a class="ulink" href="http://docbook.org/tdg/en/html/table.html" target="_top"><code class="computeroutput">&lt;table&gt;</code></a> for an
example.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="dbprimer-emphasis" id="dbprimer-emphasis"></a>Emphasis</h3></div></div></div><p>
<a class="indexterm" name="idp140682185949880" id="idp140682185949880"></a> Our documentation uses two flavors of
emphasis - italics and bold type. DocBook uses one - <a class="ulink" href="http://docbook.org/tdg/en/html/emphasis.html" target="_top"><code class="computeroutput">&lt;emphasis&gt;</code></a>.</p><p>The <code class="computeroutput">&lt;emphasis&gt;</code> tag
defaults to italics when parsed. If you&#39;re looking for
emphasizing with bold type, use <code class="computeroutput">&lt;emphasis
role="strong"&gt;</code>.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="dbprimer-indexing" id="dbprimer-indexing"></a>Indexing Your DocBook Documents</h3></div></div></div><p>Words that are marked as index-words are referenced in an index
in the final, parsed document.</p><p>Use <a class="ulink" href="http://docbook.org/tdg/en/html/indexterm.html" target="_top"><code class="computeroutput">&lt;indexterm&gt;</code></a>,
<a class="ulink" href="http://docbook.org/tdg/en/html/primary.html" target="_top"><code class="computeroutput">&lt;primary&gt;</code></a> and <a class="ulink" href="http://docbook.org/tdg/en/html/secondary.html" target="_top"><code class="computeroutput">&lt;secondary&gt;</code></a>
for this. See these links for an explanation.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="dbprimer-converting" id="dbprimer-converting"></a>Converting to HTML</h3></div></div></div><div class="note" style="margin-left: 0.5in; margin-right: 0.5in;">
<h3 class="title">Note</h3><p>This section is quoted almost verbatim from the LDP Author
Guide.</p>
</div><p>Once you have the <a class="xref" href="docbook-primer" title="Tools">Docbook
Tools</a> installed, you can convert your xml documents to HTML or
other formats.</p><p>With the DocBook XSL stylesheets, generation of multiple files
is controlled by the stylesheet. If you want to generate a single
file, you call one stylesheet. If you want to generate multiple
files, you call a different stylesheet.</p><p>To generate a single HTML file from your DocBook XML file, use
the command:</p><pre class="screen">
<code class="computeroutput">bash$ </code><strong class="userinput"><code>xsltproc -o outputfilename.xml /usr/share/sgml/docbook/stylesheet/xsl/nwalsh/html/html.xsl filename.xml</code></strong>
</pre><div class="note" style="margin-left: 0.5in; margin-right: 0.5in;">
<h3 class="title">Note</h3><p>This example uses Daniel Veillard&#39;s <span class="strong"><strong>xsltproc</strong></span> command available as part
of libxslt from <a class="ulink" href="http://www.xmlsoft.org/XSLT/" target="_top">http://www.xmlsoft.org/XSLT/</a>. If you are using other XML
processors such as Xalan or Saxon, you will need to change the
command line appropriately.</p>
</div><p>To generate a set of linked HTML pages, with a separate page for
each &lt;chapter&gt;, &lt;sect1&gt; or &lt;appendix&gt; tag, use
the following command:</p><pre class="screen">
<code class="computeroutput">bash$ </code><strong class="userinput"><code>xsltproc /usr/share/sgml/docbook/stylesheet/xsl/nwalsh/html/chunk.xsl filename.xml</code></strong>
</pre><p>You could also look at the <a class="ulink" href="https://raw.githubusercontent.com/openacs/openacs-core/master/packages/acs-core-docs/www/xml/Makefile" target="_top">acs-core-docs Makefile</a> for examples of how these
documents are generated.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="db-primer-further-reading" id="db-primer-further-reading"></a>Further Reading</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p><a class="ulink" href="http://www.xml.com/lpt/a/2002/07/31/xinclude.html" target="_top">Using Xinclude</a></p></li><li class="listitem"><p>The <a class="ulink" href="http://www.tldp.org/LDP/LDP-Author-Guide/html/index.html" target="_top">LDP Author Guide</a> has a lot of good information, a table
of docbook elements and their "look" in HTML and lots of
good links for tools.</p></li><li class="listitem"><p>James Clark wrote <a class="link" href="nxml-mode" title="Using nXML mode in Emacs">nXML Mode</a>, an alternative to PSGML
Mode. nXML Mode can validate a file as it is edited.</p></li><li class="listitem"><p>David Lutterkort wrote an <a class="link" href="psgml-mode" title="Using PSGML mode in Emacs">intro to the PSGML Mode in
Emacs</a>
</p></li><li class="listitem"><p>James Clark&#39;s free Java parser <a class="ulink" href="http://www.jclark.com/xml/xp/index.html" target="_top">XP</a>.
Note that this does not validate XML, only parses it.</p></li><li class="listitem"><p>
<a class="ulink" href="http://sources.redhat.com/docbook-tools/" target="_top">DocBook Tool for Linux</a>: Converts docbook
documents to a number of formats. <span class="emphasis"><em>NOTE:
I only got these to work with Docbook SGML, NOT with Docbook XML.
If you are able to make it work with our XML, please let us
know.</em></span>
</p></li><li class="listitem"><p>AptConvert from <a class="ulink" href="http://www.pixware.fr/" target="_top">PIXware</a> is a Java editor that will produce
DocBook documents and let you transform them into HTML and PDF for
a local preview before you submit.</p></li><li class="listitem"><p>In the process of transforming your HTML into XML, <a class="ulink" href="http://tidy.sourceforge.net/" target="_top">HTML
tidy</a> can be a handy tool to make your HTML
"regexp&#39;able". Brandoch Calef has made a <a class="ulink" href="http://web.archive.org/web/20010830084757/http://developer.arsdigita.com/working-papers/bcalef/html-to-docbook.html" target="_top">Perl script with directions</a> (now via archive.org)
that gets you most of the way.</p></li>
</ul></div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="doc-standards" leftLabel="Prev" leftTitle="Chapter 13. Documentation
Standards"
			rightLink="psgml-mode" rightLabel="Next" rightTitle="Using PSGML mode in Emacs"
			homeLink="index" homeLabel="Home" 
			upLink="doc-standards" upLabel="Up"> 
		    