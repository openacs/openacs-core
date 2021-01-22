
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Subsites Design Document}</property>
<property name="doc(title)">Subsites Design Document</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="subsites-requirements" leftLabel="Prev"
		    title="
Chapter 15. Kernel Documentation"
		    rightLink="apm-requirements" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="subsites-design" id="subsites-design"></a>Subsites Design Document</h2></div></div></div><div class="authorblurb">
<p>By <a class="ulink" href="http://planitia.org" target="_top">Rafael H. Schloming</a>
</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><p><span class="emphasis"><em>*Note* This document has not gone
through the any of the required QA process yet. It is being tagged
as stable due to high demand.</em></span></p><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="subsites-design-essentials" id="subsites-design-essentials"></a>Essentials</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;"><li class="listitem"><p><a class="xref" href="subsites-requirements" title="Subsites Requirements">OpenACS 4 Subsites Requirements</a></p></li></ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="subsites-design-intro" id="subsites-design-intro"></a>Introduction</h3></div></div></div><p>An OpenACS 4 subsite is a managed suite of applications that
work together for a particular user community. This definition
covers a very broad range of requirements: from a Geocities style
homepage where a user can install whatever available application he
wants (e.g. a single user could have their own news and forums), to
a highly structured project subsite with multiple interdependent
applications. Thus, flexibility in application deployment is the
overarching philosophy of subsites.</p><p>Meeting such broad requirements of flexibility demands
architecture-level support, i.e. very low level support from the
core OpenACS 4 data model. For example, the subsites concept
demands that any package can have multiple instances installed at
different URLs - entailing support from the APM and the Request
Processor. Since the design and implementation directly associated
with subsites is actually minimal, a discussion of subsites design
is, in fact, a discussion of how core OpenACS 4 components
implicitly support subsites as a whole.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="subsites-design-hist-considerations" id="subsites-design-hist-considerations"></a>Historical
Considerations</h3></div></div></div><p>The subsites problem actually has several quite diverse origins.
It was originally recognized as a toolkit feature in the form of
"scoping". The basic concept behind scoping was to allow
one scoped OpenACS installation to behave as multiple unscoped
OpenACS installations so that one OpenACS install could serve
multiple communities. Each piece of application data was tagged
with a "scope" consisting of the (user_id, group_id,
scope) triple. In practice the highly denormalized data models that
this method uses produced large amounts of very redundant code and
in general made it an extremely cumbersome process to
"scopify" a module.</p><p>Before the advent of scoping there were several cases of client
projects implementing their own version of scoping in special
cases. One example being the wineaccess multi-retailer ecommerce.
(Remember the other examples and get details. Archnet?,
iluvcamp?)</p><p>The requirements of all these different projects vary greatly,
but the one consistent theme among all of them is the concept that
various areas of the web site have their own private version of a
module. Because this theme is so dominant, this is the primary
problem that the OpenACS4 implementation of subsites addresses.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="subsites-design-competitors" id="subsites-design-competitors"></a>Competitive Analysis</h3></div></div></div><p>...</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="subsites-design-design-tradeoffs" id="subsites-design-design-tradeoffs"></a>Design Tradeoffs</h3></div></div></div><p>The current implementation of package instances and subsites
allows extremely flexible URL configurations. This has the benefit
of allowing multiple instances of the same package to be installed
in one subsite, but can potentially complicate the process of
integrating packages with each other since it is likely people will
want packages that live at non standard URLs to operate together.
This requirement would cause some packages to have more
configuration options than normal since hard-coding the URLs would
not be feasible anymore.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="subsites-design-api" id="subsites-design-api"></a>API</h3></div></div></div><p>This section will cover all the APIs relevant to subsites, and
so will consist of portions of the APIs of several systems.</p><p><span class="strong"><strong>Packages</strong></span></p><p>The following package is provided for instantiation of packages.
The apm_package.new function can be used to create a package of any
type known to the system. The apm_package_types table can be
queried for a list of installed packages. (See APM docs for more
detail XXX: insert link here)</p><pre class="programlisting"><code class="computeroutput">create or replace package apm_package
as

  function new (
    package_id      in apm_packages.package_id%TYPE 
               default null,
    instance_name   in apm_packages.instance_name%TYPE
               default null,
    package_key     in apm_packages.package_key%TYPE,
    object_type     in acs_objects.object_type%TYPE
               default 'apm_package', 
    creation_date   in acs_objects.creation_date%TYPE 
               default sysdate,
    creation_user   in acs_objects.creation_user%TYPE 
               default null,
    creation_ip     in acs_objects.creation_ip%TYPE 
               default null,
    context_id      in acs_objects.context_id%TYPE 
               default null
  ) return apm_packages.package_id%TYPE;

  procedure delete (
    package_id      in apm_packages.package_id%TYPE
  );

  function singleton_p (
    package_key     in apm_packages.package_key%TYPE
  ) return integer;

  function num_instances (
    package_key     in apm_package_types.package_key%TYPE
  ) return integer;

  function name (
    package_id      in apm_packages.package_id%TYPE
  ) return varchar;

  -- Enable a package to be utilized by a subsite.
  procedure enable (
    package_id      in apm_packages.package_id%TYPE
  );
  
  procedure disable (
    package_id      in apm_packages.package_id%TYPE
  );

  function highest_version (
    package_key     in apm_package_types.package_key%TYPE
  ) return apm_package_versions.version_id%TYPE;
  
end apm_package;
/
show errors
</code></pre><p><span class="strong"><strong>Site Nodes</strong></span></p><p>This data model keeps track of what packages are being served
from what URLs. You can think of this as a kind of
rp_register_directory_map on drugs. This table represents a fully
hierarchical site map. The directory_p column indicates whether or
not the node is a leaf node. The pattern_p column indicates whether
an exact match between the request URL and the URL of the node is
required. If pattern_p is true then a match between a request URL
and a site node occurs if any valid prefix of the request URL
matches the site node URL. The object_id column contains the object
mounted on the URL represented by the node. In most cases this will
be a package instance.</p><pre class="programlisting"><code class="computeroutput">create table site_nodes (
    node_id     constraint site_nodes_node_id_fk
            references acs_objects (object_id)
            constraint site_nodes_node_id_pk
            primary key,
    parent_id   constraint site_nodes_parent_id_fk
            references site_nodes (node_id),
        name        varchar(100)
            constraint site_nodes_name_ck
            check (name not like '%/%'),
    constraint site_nodes_un
    unique (parent_id, name),
    -- Is it legal to create a child node?
    directory_p char(1) not null
            constraint site_nodes_directory_p_ck
            check (directory_p in ('t', 'f')),
        -- Should urls that are logical children of this node be
    -- mapped to this node?
        pattern_p   char(1) default 'f' not null
            constraint site_nodes_pattern_p_ck
            check (pattern_p in ('t', 'f')),
    object_id   constraint site_nodes_object_id_fk
            references acs_objects (object_id)
);
</code></pre><p>The following package is provided for creating nodes.</p><pre class="programlisting"><code class="computeroutput">create or replace package site_node
as

  -- Create a new site node. If you set directory_p to be 'f' then you
  -- cannot create nodes that have this node as their parent.

  function new (
    node_id     in site_nodes.node_id%TYPE default null,
    parent_id       in site_nodes.node_id%TYPE default null,
    name        in site_nodes.name%TYPE,
    object_id       in site_nodes.object_id%TYPE default null,
    directory_p     in site_nodes.directory_p%TYPE,
    pattern_p       in site_nodes.pattern_p%TYPE default 'f'
  ) return site_nodes.node_id%TYPE;

  -- Delete a site node.

  procedure delete (
    node_id     in site_nodes.node_id%TYPE
  );

  -- Return the node_id of a url. If the url begins with '/' then the
  -- parent_id must be null. This will raise the no_data_found
  -- exception if there is no matching node in the site_nodes table.
  -- This will match directories even if no trailing slash is included
  -- in the url.

  function node_id (
    url         in varchar,
    parent_id   in site_nodes.node_id%TYPE default null
  ) return site_nodes.node_id%TYPE;

  -- Return the url of a node_id.

  function url (
    node_id     in site_nodes.node_id%TYPE
  ) return varchar;

end;
/
show errors
</code></pre><p><span class="strong"><strong>Request
Processor</strong></span></p><p>Once the above APIs are used to create packages and mount them
on a specific site node, the following request processor APIs can
be used to allow the package to serve content appropriate to the
package instance.</p><pre class="programlisting"><code class="computeroutput">[ad_conn node_id]
[ad_conn package_id]
[ad_conn package_url]
[ad_conn subsite_id]
[ad_conn subsite_url]
</code></pre>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="subsites-design-data-model" id="subsites-design-data-model"></a>Data Model Discussion</h3></div></div></div><p>The subsites implementation doesn&#39;t really have it&#39;s own
data model, although it depends heavily on the site-nodes data
model, and the APM data model.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="subsites-design-ui" id="subsites-design-ui"></a>User Interface</h3></div></div></div><p>The primary elements of the subsite user interface consist of
the subsite admin pages. These pages are divided up into two areas:
Group administration, and the site map. The group administration
pages allow a subsite administrator to create and modify groups.
The site map pages allow a subsite administrator to install,
remove, configure, and control access to packages. The site map
interface is the primary point of entry for most of the things a
subsite administrator would want to do.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="subsites-design-config" id="subsites-design-config"></a>Configuration/Parameters</h3></div></div></div><p>...</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="subsites-design-future" id="subsites-design-future"></a>Future Improvements/Areas of Likely
Change</h3></div></div></div><p>The current subsites implementation addresses the most basic
functionality required for subsites. It is likely that as
developers begin to use the subsites system for more sophisticated
projects, it will become necessary to develop tools to help build
tightly integrated packages. The general area this falls under is
"inter-package communication". An actual implementation
of this could be anything from clever use of configuration
parameters to lots of package level introspection. Another area
that is currently underdeveloped is the ability to "tar
up" and distribute a particular configuration of site
nodes/packages. As we build more fundamental applications that can
be applied in more general areas, this feature will become more and
more in demand since more problems will be solvable by
configuration instead of coding.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="subsites-design-authors" id="subsites-design-authors"></a>Authors</h3></div></div></div><p><a class="ulink" href="mailto:rhs\@mit.edu" target="_top">rhs\@mit.edu</a></p>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="subsites-requirements" leftLabel="Prev" leftTitle="Subsites Requirements"
		    rightLink="apm-requirements" rightLabel="Next" rightTitle="Package Manager Requirements"
		    homeLink="index" homeLabel="Home" 
		    upLink="kernel-doc" upLabel="Up"> 
		