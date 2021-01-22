
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Object Model Requirements}</property>
<property name="doc(title)">Object Model Requirements</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="kernel-overview" leftLabel="Prev"
		    title="
Chapter 15. Kernel Documentation"
		    rightLink="object-system-design" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="object-system-requirements" id="object-system-requirements"></a>Object Model Requirements</h2></div></div></div><div class="authorblurb">
<p>By Pete Su</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="object-system-requirements-" id="object-system-requirements-"></a>I. Introduction</h3></div></div></div><p>A major goal in OpenACS 4 is to unify and normalize many of the
core services of the system into a coherent common data model and
API. In the past, these services were provided to applications in
an ad-hoc and irregular fashion. Examples of such services
include:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>General Comments</p></li><li class="listitem"><p>User/groups</p></li><li class="listitem"><p>Attribute storage in user/groups</p></li><li class="listitem"><p>General Permissions</p></li><li class="listitem"><p>Site wide search</p></li><li class="listitem"><p>General Auditing</p></li>
</ul></div><p>All of these services involve relating extra information and
services to application data objects, examples of which
include:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Bboard messages</p></li><li class="listitem"><p>A user home page</p></li><li class="listitem"><p>A ticket in the Ticket Tracker</p></li><li class="listitem"><p>A photograph in the PhotoDB</p></li>
</ul></div><p>In the past, developers had to use ad-hoc and inconsistent
schemes to interface to the various "general" services
mentioned above. Since each service used its own scheme for storing
its metadata and mapping this data to application objects, we could
not implement any kind of centralized management system or
consistent administrative pages for all the services. Consequently,
a large amount of duplicate code appeared throughout the system for
dealing with these services.</p><p>Unifying and "normalizing" these interfaces, to
minimize the amount of code repetition in applications, is a
primary goal of OpenACS 4. Thus the Object Model (OM, also referred
to later as the object system) is concerned primarily with the
storage and management of <span class="emphasis"><em>metadata</em></span>, on any object within a given
instance of OpenACS 4. The term "metadata" refers to any
extra data the OM stores on behalf of the application - outside of
the application&#39;s data model - in order to enable certain
generic services. The term "object" refers to any entity
being represented within the OpenACS, and typically corresponds to
a single row within the relational database.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="object-system-requirements-vision" id="object-system-requirements-vision"></a>Vision Statement</h3></div></div></div><p>The OpenACS 4 Object Model must address five high-level
requirements that repeatedly exhibit themselves in the context of
existing services in OpenACS 3.x, as described below.</p><p><span class="strong"><strong>Object Identifiers for General
Services</strong></span></p><p>Generic services require a single unambiguous way of identifying
application objects that they manage or manipulate. In OpenACS 3.x,
there are several different idioms that construct object
identifiers from other data. Many modules use a <code class="computeroutput">(user_id, group_id, scope)</code> triple
combination for the purpose of recording ownership information on
objects for access control. User/groups also uses <code class="computeroutput">(user_id, group_id)</code> pairs in its
<code class="computeroutput">user_group_map</code> table as a way
to identify data associated with a single membership relation.</p><p>Also in OpenACS 3.x, many utility modules exist that do nothing
more than attach some extra attributes to existing application
data. For example, general comments maintains a mapping table that
maps application "page" data (static or dynamic) to one
or more user comments on the page, by constructing a unique
identifier for each page. This identifier is usually a combination
of the table in which the data is stored, and the value of the
primary key value for the particular page. This idiom is referred
to as the "(on_which_table + on_what_id)" method for
identifying application data. General comments stores its map from
pages to comments using a "(on_which_table + on_what_id)"
key, plus the id of the comment itself.</p><p>All of these composite key constructions are implicit object
identifiers: they build a unique ID out of other pieces of the data
model. The problem is that their definition and use is ad-hoc and
inconsistent. This makes the construction of generic
application-independent services difficult. Therefore, the OpenACS
4 Object Model should provide a centralized and uniform mechanism
for tagging application objects with unique identifiers.</p><p><span class="strong"><strong>Support for Unified Access
Control</strong></span></p><p>Access control should be as transparent as possible to the
application developer. Until the implementation of the general
permissions system, every OpenACS application had to manage access
control to its data separately. Later on, a notion of
"scoping" was introduced into the core data model.</p><p>"Scope" is a term best explained by example. Consider
some hypothetical rows in the <code class="computeroutput">address_book</code> table:</p><div class="informaltable"><table class="informaltable" cellspacing="0" border="1">
<colgroup>
<col><col><col><col>
</colgroup><tbody>
<tr>
<td><span class="strong"><strong>...</strong></span></td><td><span class="strong"><strong><code class="computeroutput">scope</code></strong></span></td><td><span class="strong"><strong><code class="computeroutput">user_id</code></strong></span></td><td><span class="strong"><strong><code class="computeroutput">group_id</code></strong></span></td><td><span class="strong"><strong>...</strong></span></td>
</tr><tr>
<td>...</td><td><code class="computeroutput">user</code></td><td><code class="computeroutput">123</code></td><td></td><td>...</td>
</tr><tr>
<td>...</td><td><code class="computeroutput">group</code></td><td></td><td><code class="computeroutput">456</code></td><td>...</td>
</tr><tr>
<td>...</td><td><code class="computeroutput">public</code></td><td></td><td></td><td>...</td>
</tr>
</tbody>
</table></div><p>The first row represents an entry in User 123's personal
address book, the second row represents an entry in User Group
456's shared address book, and the third row represents an
entry in the site&#39;s public address book.</p><p>In this way, the scoping columns identify the security context
in which a given object belongs, where each context is <span class="emphasis"><em>either</em></span> a person <span class="emphasis"><em>or</em></span> a group of people <span class="emphasis"><em>or</em></span> the general public (itself a group of
people).</p><p>The problem with this scheme is that we are limited to using
only users and groups as scopes for access control, limiting
applications to a single level of hierarchy. Worse, the scoping
system demanded that every page needing access to a given
application had to do an explicit scope check to make sure access
was allowed - if a developer was careless on just one site page, a
security problem could result.</p><p>Thus the OpenACS 4 Object Model must support a more general
access control system that allows access control domains to be
hierarchical, and specifiable with a single piece of data, instead
of the old composite keys described above.</p><p><span class="strong"><strong>Extensible Data
Models</strong></span></p><p>Another problem with previous OpenACS data models is that many
of the central tables in the system became bloated as they were
extended to support an increasing number of modules. The
<code class="computeroutput">users</code> table is the best case in
point: it became full of columns that exist for various special
applications (e.g. user portraits), but that aren&#39;t really
related to each other in any way except that they store information
on users, i.e. the table became grossly denormalized. Normalizing
(breaking-down) this table into several pieces, each of which is
specific to a particular application, would improve maintainability
greatly. Furthermore, the ability to allow applications or users to
define new extensions to existing tables, and have some central
metadata facility for keeping track of what data belong to which
tables, would be very useful.</p><p>Thus the motivation for providing <span class="emphasis"><em>object types</em></span> and <span class="emphasis"><em>subtyping</em></span> in the OpenACS 4 Object Model.
The OM should allow developers to define a hierarchy of metadata
<span class="emphasis"><em>object types</em></span> with subtyping
and inheritance. Developers can then use the framework to allow
users to define custom extensions to the existing data models, and
the OM does the bookkeeping necessary to make this easier,
providing a generic API for object creation that automatically
keeps track of the location and relationships between data.</p><p>
<span class="strong"><strong>Design Note:</strong></span> While
this doesn&#39;t really belong in a requirements document, the fact
that we are constrained to using relational databases means that
certain constraints on the overall design of the object data model
exist, which you can read about in <a class="xref" href="object-system-design" title="Summary and Design Considerations">Summary and Design
Considerations</a>.</p><p><span class="strong"><strong>Modifiable Data
Models</strong></span></p><p>Another recurring applications problem is how to store a
modifiable data model, or how to store information that may change
extensively between releases or in different client installations.
Furthermore, we want to avoid changes to an application&#39;s
database queries in the face of any custom extensions, since such
changes are difficult or dangerous to make at runtime, and can make
updating the system difficult. Some example applications in OpenACS
3.x with modifiable data models include:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>User/groups: developers and users can attach custom data to
group types, groups, and members of groups.</p></li><li class="listitem"><p>In the Ecommerce data model, the <code class="computeroutput">ec_custom_product_fields</code> table defines
attributes for catalog products, and the <code class="computeroutput">ec_custom_product_field_values</code> table stores
values for those attributes.</p></li><li class="listitem"><p>In the PhotoDB data model, the <code class="computeroutput">ph_custom_photo_fields</code> table defines
attributes for the photographs owned by a specific user, and tables
named according to the convention "<code class="computeroutput">ph_user_&lt;user_id&gt;_custom_info</code>"
are used to store values for those attributes.</p></li>
</ul></div><p>Thus the Object Model must provide a general mechanism for
applications and developers to modify or extend data models,
without requiring changes to the SQL schema of the system. This
ensures that all applications use the same base schema, resulting
in a uniform and more maintainable system.</p><p><span class="strong"><strong>Generic
Relations</strong></span></p><p>Many OpenACS applications define simple relationships between
application objects, and tag those relationships with extra data.
In OpenACS 3.x, this was done using <span class="emphasis"><em>mapping tables</em></span>. The user/groups module
has the most highly developed data model for this purpose, using a
single table called <code class="computeroutput">user_group_map</code> that mapped users to groups.
In addition, it uses the the <code class="computeroutput">user_group_member_fields</code> and <code class="computeroutput">user_group_member_fields_map</code> tables to
allow developers to attach custom attributes to group members. In
fact, these custom attributes were not really attached to the
users, but to the fact that a user was a member of a particular
group - a subtle but important distinction. As a historical note,
in OpenACS 3.x, user/groups was the only part of the system that
provided this kind of data model in a reusable way. Therefore,
applications that needed this capability often hooked into
user/groups for no other reason than to use this part of its data
model.</p><p>The OpenACS 4 data model must support generic relations by
allowing developers to define a special kind of object type called
a <span class="emphasis"><em>relation type</em></span>. Relation
types are themselves object types that do nothing but represent
relations. They can be used by applications that previously used
user/groups for the same purpose, but without the extraneous,
artificial dependencies.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="object-system-requirements-system-overview" id="object-system-requirements-system-overview"></a>System
Overview</h3></div></div></div><p>The Object Model package is a combination of data model and a
procedural API for manipulating application objects within an
OpenACS instance. The OM allows developers to describe a
hierarchical system of <span class="emphasis"><em>object
types</em></span> that store metadata on application objects. The
object type system supports subtyping with inheritance, so new
object types can be defined in terms of existing object types.</p><p>The OM data model forms the main part of the OpenACS 4 Kernel
data model. The other parts of the Kernel data model include:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Parties and Groups</p></li><li class="listitem"><p>Permissions</p></li>
</ul></div><p>Each of these is documented elsewhere at length.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="object-system-requirements-use-cases" id="object-system-requirements-use-cases"></a>Use-cases and
User-scenarios</h3></div></div></div><p>(Pending as of 8/27/00)</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="object-system-requirements-links" id="object-system-requirements-links"></a>Related Links</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p><a class="xref" href="object-system-design" title="Object Model Design">OpenACS 4 Object Model Design</a></p></li><li class="listitem"><p><a class="xref" href="objects" title="OpenACS Data Models and the Object System">OpenACS Data Models and
the Object System</a></p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="object-system-requirements-data-model" id="object-system-requirements-data-model"></a>Requirements: Data
Model</h3></div></div></div><p>The data model for the object system provides support for the
following kinds of schema patterns that are used by many existing
OpenACS modules:</p><div class="variablelist"><dl class="variablelist">
<dt><span class="term"><span class="strong"><strong>10.0 Object
Identification and Storage</strong></span></span></dt><dd>
<p>Object identification is a central mechanism in the new metadata
system. The fact that every object has a known unique identifier
means that the core can deal with all objects in a generic way.
Thus the only action required of an application to obtain any
general service is to "hook into" the object system.</p><p>In OpenACS 3.x, modules use ad-hoc means to construct unique
identifiers for objects that they manage. Generally, these unique
IDs are built from other IDs that happen to be in the data model.
Because there is no consistency in these implementations, every
application must hook into every service separately.</p><p>Examples of utilities that do this in OpenACS 3.x system
are:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>User/groups: Information is attached to group membership
relations.</p></li><li class="listitem"><p>General Comments: Comments are attached to objects representing
some kind of document.</p></li><li class="listitem"><p>General Permissions: Stores access control information on
application data.</p></li><li class="listitem"><p>User Profiling: Maps users to pieces of content that they have
looked at; content identifiers must be managed in a uniform
way.</p></li><li class="listitem"><p>Site Wide Search: Stores all content in a single flat table,
with object identifiers pointing to the object containing the
content in the first place. This way, we can search the contents of
many different types of objects in a uniform way.</p></li>
</ul></div><p>The OM will support and unify this programming idiom by
providing objects with unique identifiers (unique within a given
OpenACS instance) and with information about where the application
data associated with the object is stored. The identifier can be
used to refer to collections of heterogeneous application data.
More importantly, object identifiers will enable developers to
readily build and use generic services that work globally across a
system.</p><p>The object identifiers should be subject to the following
requirements:</p><p><span class="strong"><strong>10.10
Uniqueness</strong></span></p><p>The object ID should be unique among all the IDs in the entire
OpenACS system in which the object lives.</p><p><span class="strong"><strong>10.20 Useful as a
Reference</strong></span></p><p>Applications should be able to use the unique object ID as a
reference, with which they can fetch any or all of the object&#39;s
attributes.</p><p><span class="strong"><strong>10.30 Storable</strong></span></p><p>Object IDs should be storable in tables. e.g. you should be able
to use them to implement mapping tables between objects, to
represent relationships.</p><p><span class="strong"><strong>10.40 Moveable</strong></span></p><p>Objects should be mobile between databases. That is, information
will often need to be moved between multiple servers (development,
staging, and production), so a mechanism for moving this data is
necessary. In addition, a mechanism for tagging these objects in a
way similar to CVS would be useful in determining which objects
need to be synchronized.</p>
</dd><dt><span class="term"><span class="strong"><strong>20.0 Object
Types</strong></span></span></dt><dd>
<p>An <span class="emphasis"><em>object type</em></span> refers to
a specification of one or more attributes to be managed along with
a piece of application data.</p><p>The object system should provide a data model for describing and
representing object types. This data model is somewhat analogous to
the Oracle data dictionary, which stores information about all user
defined tables in the system.</p><p>The canonical example of this kind of data model occurs in the
current OpenACS 3.x user/groups module, which allows the developer
to create new <span class="emphasis"><em>group types</em></span>
that can contain not only generic system level attributes but also
extended, developer-defined attributes. In addition, these
attributes can either be attached to the group type itself, and
shared by all instances, or they can be different for each
instance. At its core, the OpenACS 4 object system is meant to be a
generalization of this mechanism. The data model should allow
developers to at least do everything they used to with user/groups,
but without its administrative hassles.</p><p>Therefore, the data model must be able to represent object types
that have the following characteristics:</p><p><span class="strong"><strong>20.10 Type Name</strong></span></p><p>A human readable name for the object type.</p><p><span class="strong"><strong>20.20 Type
Attributes</strong></span></p><p>Attributes whose values are shared by all instances of the
object type.</p><p><span class="strong"><strong>20.30 Object
Attributes</strong></span></p><p>Attributes that are specific to each particular object belonging
to a given type.</p><p>The data model must also enforce certain constraints on object
types:</p><p><span class="strong"><strong>20.40 Type
Uniqueness</strong></span></p><p>Object type names must be unique.</p><p><span class="strong"><strong>20.50 Attribute Name
Uniqueness</strong></span></p><p>Attribute names must be unique in the scope of a single object
type and any of its parent types.</p>
</dd><dt><span class="term"><span class="strong"><strong>30.0 Type
Extension</strong></span></span></dt><dd>
<p>The Object Model must support the definition of object types
that are subtypes of existing types. A subtype inherits all the
attributes of its parent type, and defines some attributes of its
own. A critical aspect of the OM is parent types may be altered,
and any such change must propagate to child subtypes.</p><p>The OM data model must enforce constraints on subtypes that are
similar to the ones on general object types.</p><p><span class="strong"><strong>30.10 Subtype
Uniqueness</strong></span></p><p>Subtype names must be unique (this parallels requirement
10.40).</p><p><span class="strong"><strong>30.20 Subtype Attribute Name
Uniqueness</strong></span></p><p>Attribute names must be unique in the scope of a single object
subtype.</p><p><span class="strong"><strong>30.30 Parent Type
Prerequisite</strong></span></p><p>Subtypes must be defined in terms of parent types that, in fact,
already exist.</p><p><span class="strong"><strong>30.40</strong></span></p><p>The extended attribute names in a subtype must not be the same
as those in its parent type.</p>
</dd><dt><span class="term"><span class="strong"><strong>35.0
Methods</strong></span></span></dt><dd>
<p><span class="strong"><strong>35.10 Method and Type
Association</strong></span></p><p>The OM data model should define a mechanism for associating
procedural code, called <span class="emphasis"><em>methods</em></span>, with objects of a given type.
Methods are associated with the each object <span class="emphasis"><em>type</em></span> - not each object <span class="emphasis"><em>instance</em></span>.</p><p><span class="strong"><strong>35.20 Method
Sharing</strong></span></p><p>All instances of a given object type should share the same set
of defined methods for that type.</p>
</dd><dt><span class="term"><span class="strong"><strong>40.0 Object
Attribute Value Storage</strong></span></span></dt><dd>
<p>In addition to information on types, the OM data model provides
for the centralized storage of object attribute values. This
facility unifies the many ad-hoc attribute/value tables that exist
in various OpenACS 3.x data models, such as:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>User groups: Each instance of a group type can have custom
data.</p></li><li class="listitem"><p>Photo DB: Users can define their own custom metadata to attach
to photograph objects.</p></li><li class="listitem"><p>Ecommerce: Vendors can attach custom fields to the data model
describing their products.</p></li>
</ul></div><p><span class="strong"><strong>40.10 Generic
Retrieval</strong></span></p><p>Attributes should be stored so that they are retrievable in a
way that is independent of the type of the object that they belong
to. That is, the only data needed to retrieve an attribute should
be the system-wide ID of an object (see requirement 10.20 above)
and the attribute name.</p><p><span class="strong"><strong>40.20 Inherited
Attributes</strong></span></p><p>The system should allow for the automatic retrieval of inherited
attribute values, for an object belonging to a subtype.</p><p><span class="strong"><strong>40.30. Constraints on
Attributes</strong></span></p><p>The system should allow the developer to put down constraints on
the values that an attribute may hold, for the purposes of
maintaining application specific integrity rules.</p>
</dd><dt><span class="term"><span class="strong"><strong>50.0 Object
Contexts</strong></span></span></dt><dd>
<p>In OpenACS 3.x, there was a notion of "scope" for
application objects. An object could be belong to one of three
scopes: public, group or user. This provided a crude way to
associate objects with particular scopes in the system, but it was
awkward to use and limited in flexibility.</p><p>The OpenACS 4 Object Model provides a generalized notion of
scope that allows developers to represent a hierarchy of object
<span class="emphasis"><em>contexts</em></span>. These contexts are
used as the basis for the permissions system. In general, if an
object has no explicit permissions attached to it, then it inherits
permissions from its context.</p><p>The context data model also forms the basis of the <a class="link" href="subsites-requirements" title="Subsites Requirements">subsites system</a>, and is a basic part of
the <a class="link" href="permissions-requirements" title="Permissions Requirements">permissions system</a>, described in
separate documents.</p><p>The context data model should provide the following
facilities:</p><p><span class="strong"><strong>50.10 Unique ID</strong></span></p><p>Every context should have a unique ID in the system.</p><p><span class="strong"><strong>50.20 Tree
Structure</strong></span></p><p>The data model should support a tree structured organization of
contexts. That is, contexts can be logically "contained"
within other contexts (i.e. contexts have parents) and contexts can
contain other contexts (i.e. contexts can have children).</p><p><span class="strong"><strong>50.30 Data Model
Constraints</strong></span></p><p>All objects must have a context ID. This ID must refer to an
existing context or be NULL. The meaning of a NULL context is
determined by the implementation.</p><p><span class="strong"><strong>Note:</strong></span></p><p>The current system interprets the NULL context as meaning the
default "site-wide" context in some sense. I wanted to
note this fact for others, but there is no need to make this a
requirement of the system. I think it would be reasonable to have a
NULL context be an error (psu 8/24/2000).</p>
</dd><dt><span class="term"><span class="strong"><strong>55.0 Object
Relations</strong></span></span></dt><dd><p>The data model should include a notion of pair-wise relations
between objects. Relations should be able to record simple facts of
the form "object X is related to object Y by relationship
R," and also be able to attach attributes to these facts.</p></dd>
</dl></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="object-system-requirements-api" id="object-system-requirements-api"></a>Requirements: API</h3></div></div></div><p>The API should let programmers accomplish the following
actions:</p><div class="variablelist"><dl class="variablelist">
<dt><span class="term"><span class="strong"><strong>60.0 Object
Type Creation</strong></span></span></dt><dd>
<p><span class="strong"><strong>60.10 Create a New Object
Type</strong></span></p><p>The object system API should provide a procedure call that
creates a new object type by running the appropriate transactions
on the object system data model. This API call is subject to the
constraints laid out in the data model. We call this operation
"instantiating" an object.</p><p><span class="strong"><strong>60.20 Create a New Object
Subtype</strong></span></p><p>The object system API should provide a procedure call for
creating subtypes of a given type. Operationally, this API is the
same as requirement 60.10. Instances of subtypes automatically
contain all attributes of the parent type in addition to all
attributes of the subtype. This API is subject to the constraints
laid out in the data model.</p><p><span class="strong"><strong>60.30 Create a New Relation
Type</strong></span></p><p>There should be an API call to create a new type of object
relation. Relation types can be modeled as object types. The API
below for manipulating attributes can then be used to add
attributes to relation types.</p>
</dd><dt><span class="term"><span class="strong"><strong>70.0 Update an
Object Type</strong></span></span></dt><dd><p>The object system API must allow the programmer to modify, add,
and delete attributes from any object type. Updates should be
propagated to any child subtypes. This API is subject to the
constraints laid out in the data model.</p></dd><dt><span class="term"><span class="strong"><strong>80.0 Delete an
Object Type</strong></span></span></dt><dd>
<p>The system provides an API call for deleting an object type.</p><p><span class="strong"><strong>80.10</strong></span></p><p>Deleting an object type destroys all instances of the type. It
should be an error to delete types that have dependent subtypes.
This API is subject to the constraints laid out in the data
model.</p><p><span class="strong"><strong>80.10.10</strong></span></p><p>However, the programmer should also be able to specify that all
the subtypes and instances of those subtypes be destroyed before
destroying the object type. This is similar to a "delete
cascade" constraint in SQL.</p>
</dd><dt><span class="term"><span class="strong"><strong>90.0 Object
Instance Creation and Destruction</strong></span></span></dt><dd>
<p>The system must provide API calls to manage the creation and
destruction of object instances.</p><p><span class="strong"><strong>90.10 Create an Instance of an
Object Type</strong></span></p><p>The system should provide an API call for creating a new
instance of a given object type. The new instance should be
populated with values for each of the attributes specified in the
definition of the type. In addition, it should be possible to
create the new instance with an optional context ID that refers to
the default context that the object will live in.</p><p><span class="strong"><strong>90.20 Delete an Object
Instance</strong></span></p><p>The OM should provide an API call for object deletion. Objects
can be deleted only when no other objects in the system refer to
them. Since it might not be practical to provide a mechanism like
"delete cascade" here in a reliable way, providing such a
facility in the system is optional.</p>
</dd><dt><span class="term"><span class="strong"><strong>94.0 Object
Relation Creation and Destruction</strong></span></span></dt><dd><p>The system must provide API calls to manage the creation and
destruction of object relations.</p></dd><dt><span class="term"><span class="strong"><strong>94.10 Create an
Object Relation</strong></span></span></dt><dd><p>The OM must provide an API call to declare that two objects are
related to each other by a given relation type. This API call
should also allow programmers to attach attributes to this object
relation.</p></dd><dt><span class="term"><span class="strong"><strong>94.20 Destroy
an Object Relation</strong></span></span></dt><dd><p>There should be an API call for destroying object relations and
their attributes.</p></dd><dt><span class="term"><span class="strong"><strong>95.10 Create
and Destroy Contexts</strong></span></span></dt><dd><p>The system should provide an API to create and destroy object
contexts.</p></dd><dt><span class="term"><span class="strong"><strong>100.10 Set
Attribute Values for an Object</strong></span></span></dt><dd><p>The system should provide an API for updating the attribute
values of a particular instance of an object type.</p></dd><dt><span class="term"><span class="strong"><strong>110.10 Get
Attribute Values for an Object</strong></span></span></dt><dd><p>The system should provide an API for retrieving attribute values
from a particular instance of an object type.</p></dd><dt><span class="term"><span class="strong"><strong>120.10
Efficiency</strong></span></span></dt><dd><p>The Object Model must support the efficient storage and
retrieval of object attributes. Since the OM is intended to form
the core of many general services in the OpenACS, and these
services will likely make extensive use of the OM tables, queries
on these tables must be fast. The major problem here seems to be
supporting subtyping and inheritance in a way that does not
severely impact query performance.</p></dd><dt><span class="term"><span class="strong"><strong>130.10 Ease of
Use</strong></span></span></dt><dd>
<p>Most OpenACS packages will be expected to use the Object Model
in one way or another. Since it is important that the largest
audience of developers possible adopts and uses the OM, it must be
easy to incorporate into applications, and it must not impose undue
requirements on an application&#39;s data model. In other words, it
should be easy to "hook into" the object model, and that
ability should not have a major impact on the application data
model.</p><p>
<span class="strong"><strong>Note:</strong></span> Is the API
the only way to obtain values? How does this integrate with
application level SQL queries?</p>
</dd>
</dl></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="object-system-requirements-history" id="object-system-requirements-history"></a>Revision History</h3></div></div></div><div class="informaltable"><table class="informaltable" cellspacing="0" border="1">
<colgroup>
<col><col><col><col>
</colgroup><tbody>
<tr>
<td><span class="strong"><strong>Document Revision
#</strong></span></td><td><span class="strong"><strong>Action Taken,
Notes</strong></span></td><td><span class="strong"><strong>When?</strong></span></td><td><span class="strong"><strong>By Whom?</strong></span></td>
</tr><tr>
<td>0.1</td><td>Creation</td><td>08/10/2000</td><td>Bryan Quinn</td>
</tr><tr>
<td>0.2</td><td>Major re-write</td><td>08/11/2000</td><td>Pete Su</td>
</tr><tr>
<td>0.3</td><td>Draft completed after initial reviews</td><td>08/22/2000</td><td>Pete Su</td>
</tr><tr>
<td>0.4</td><td>Edited, updated to conform to requirements template, pending
freeze</td><td>08/23/2000</td><td>Kai Wu</td>
</tr><tr>
<td></td><td>Final edits before freeze</td><td>08/24/2000</td><td>Pete Su</td>
</tr><tr>
<td>0.5</td><td>Edited for consistency</td><td>08/27/2000</td><td>Kai Wu</td>
</tr><tr>
<td>0.6</td><td>Put Object ID stuff first, because it makes more sense</td><td>08/28/2000</td><td>Pete Su</td>
</tr><tr>
<td>0.7</td><td>Added requirement that knowledge-level objects must be moveable
between databases.</td><td>08/29/2000</td><td>Richard Li</td>
</tr><tr>
<td>0.8</td><td>Rewrote intro to match language and concepts in the design
document. Also cleaned up usage a bit in the requirements section.
Added short vague requirements on relation types.</td><td>09/06/2000</td><td>Pete Su</td>
</tr><tr>
<td>0.9</td><td>Edited for ACS 4 Beta release.</td><td>09/30/2000</td><td>Kai Wu</td>
</tr>
</tbody>
</table></div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="kernel-overview" leftLabel="Prev" leftTitle="Overview"
		    rightLink="object-system-design" rightLabel="Next" rightTitle="Object Model Design"
		    homeLink="index" homeLabel="Home" 
		    upLink="kernel-doc" upLabel="Up"> 
		