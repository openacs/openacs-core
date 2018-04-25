
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Object Identity}</property>
<property name="doc(title)">Object Identity</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="permissions-tediously-explained" leftLabel="Prev"
			title="Chapter 11. Development
Reference"
			rightLink="programming-with-aolserver" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="object-identity" id="object-identity"></a>Object Identity</h2></div></div></div><span style="color: red">&lt;authorblurb&gt;</span><p><span style="color: red">By <a class="ulink" href="http://planitia.org" target="_top">Rafael H.
Schloming</a>
</span></p><span style="color: red">&lt;/authorblurb&gt;</span><p>One of the major design features of OpenACS 5.9.0 is the
explicit representation of <span class="emphasis"><em>object
identity</em></span>. The reason I say "explicit
representation" is because the concept of object identity has
been around forever. It is inherent to our problem domain. Consider
the example of 3.x style scoping. The 3.x data models use the
triple (user_id, group_id, scope) to <span class="emphasis"><em>identify</em></span> an <span class="emphasis"><em>object</em></span>. In the 5.9.0 data model this
object is <span class="emphasis"><em>explicitly
represented</em></span> by a single party_id.</p><p>Another good example of this is can be found in the user groups
data model. The 3.x user groups data model contains another example
of an <span class="emphasis"><em>implied identity</em></span>.
Every mapping between a user and a group could have an arbitrary
number of attached values (user_group_member_fields, etc.). In this
case it is the pair (group_id, user_id) that implicitly refers to
an object (the person&#39;s membership in a group). In the 5.9.0
data model this object identity is made explicit by adding an
integer primary key to the table that maps users to groups.</p><p>Coming from a purely relational world, this might seem slightly
weird at first. The pair (group_id, user_id) is sufficient to
uniquely identify the object in question, so why have the redundant
integer primary key? If you take a closer look, it actually
isn&#39;t quite so redundant. If you want to be able to use the
object model&#39;s permissioning features, and generic attribute
features on a table, you need an integer primary key for that
table. This is because you can&#39;t really write a data model in
oracle that uses more than one way to represent identity.</p><p>So, this apparently redundant primary key has saved us the
trouble of duplicating the entire generic storage system for the
special case of the user_group_map, and has saved us from
implementing ad-hoc security instead of just using acs-permissions.
This design choice is further validated by the fact that services
like journals that weren&#39;t previously thought to be generic can
in fact be generically applied to membership objects, thereby
allowing us to eliminated membership state auditing columns that
weren&#39;t even capable of fully tracking the history of
membership state.</p><p>The design choice of explicitly representing object identity
with an integer primary key that is derived from a globally unique
sequence is the key to eliminating redundant code and replacing it
with generic <span class="emphasis"><em>object level
services</em></span>.</p><p><span class="cvstag">($&zwnj;Id: object-identity.xml,v 1.7 2006/07/17
05:38:37 torbenb Exp $)</span></p>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="permissions-tediously-explained" leftLabel="Prev" leftTitle="OpenACS Permissions Tediously
Explained"
			rightLink="programming-with-aolserver" rightLabel="Next" rightTitle="Programming with AOLserver"
			homeLink="index" homeLabel="Home" 
			upLink="dev-guide" upLabel="Up"> 
		    