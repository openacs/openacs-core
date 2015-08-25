
<property name="context">{/doc/acs-authentication {Authentication}} {IMS Sync driver design}</property>
<property name="doc(title)">IMS Sync driver design</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="ext-auth-design" leftLabel="Prev"
		    title="Design"
		    rightLink="ext-auth-ldap-install" rightLabel="Next">
		<div class="sect1" lang="en">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="ims-sync-driver-design" id="ims-sync-driver-design"></a>IMS Sync
driver design</h2></div></div></div><div class="authorblurb">by <a href="mailto:lars\@collaboraid.biz" target="_top">Lars Pind</a> OpenACS docs are written by the named
authors, and may be edited by OpenACS documentation staff.</div><div class="sect2" lang="en">
<div class="titlepage"><div><div><h3 class="title">
<a name="id2453048" id="id2453048"></a>TODO</h3></div></div></div><p>We need examples of how the communication would be done from our
clients.</p><p>The "GetDocument" communications service contract could be a
generic system-wide service contract.</p><p>We might need a source/ID column in the users table to identify
where they're imported from for doing updates, particularly if
importing from multiple sources (or when some users are local.)</p>
</div><div class="sect2" lang="en">
<div class="titlepage"><div><div><h3 class="title">
<a name="id2453074" id="id2453074"></a>Execution
Story</h3></div></div></div><div class="orderedlist"><ol type="1">
<li><p>We will parse a document in the <a href="http://www.imsglobal.org/enterprise/index.cfm" target="_top">IMS
Enterprise Specification</a> format (<a href="http://www.imsglobal.org/enterprise/entv1p1/imsent_bestv1p1.html#1404584" target="_top">example XML document</a>), and translate it into
calls to the batch user sync API.</p></li><li><p>The document will contain either the complete user listitemst
(IMS: "snapshot"), or an incremental user listitemst (IMS: "Event
Driven" -- contains only adds, edits, and deletes). You could for
example do a complete transfer once a month, and incrementals every
night. The invocation should decide which type is returned.</p></li>
</ol></div><p>The design should favor interoperability, reliability and
robustness.</p><pre class="programlisting">
&lt;enterprise&gt;

  &lt;properties&gt;
    &lt;datasource&gt;Dunelm Services Limited&lt;/datasource&gt;
    &lt;target&gt;Telecommunications LMS&lt;/target&gt;
    &lt;type&gt;DATABASE UPDATE&lt;/type&gt;

    &lt;datetime&gt;2001-08-08&lt;/datetime&gt;
  &lt;/properties&gt;
  &lt;person recstatus = "1"&gt;
    &lt;comments&gt;Add a new Person record.&lt;/comments&gt;
    &lt;sourcedid&gt;

      &lt;source&gt;Dunelm Services Limited&lt;/source&gt;
      &lt;id&gt;CK1&lt;/id&gt;
    &lt;/sourcedid&gt;
    &lt;name&gt;
      &lt;fn&gt;Clark Kent&lt;/fn&gt;

      &lt;sort&gt;Kent, C&lt;/sort&gt;
      &lt;nickname&gt;Superman&lt;/nickname&gt;
    &lt;/name&gt;
    &lt;demographics&gt;
      &lt;gender&gt;2&lt;/gender&gt;

    &lt;/demographics&gt;
    &lt;adr&gt;
      &lt;extadd&gt;The Daily Planet&lt;/extadd&gt;
      &lt;locality&gt;Metropolis&lt;/locality&gt;
      &lt;country&gt;USA&lt;/country&gt;

    &lt;/adr&gt;
  &lt;/person&gt;
  &lt;person recstatus = "2"&gt;
    &lt;comments&gt;Update a previously created record.&lt;/comments&gt;
    &lt;sourcedid&gt;

      &lt;source&gt;Dunelm Services Limited&lt;/source&gt;
      &lt;id&gt;CS1&lt;/id&gt;
    &lt;/sourcedid&gt;
    &lt;name&gt;
      &lt;fn&gt;Colin Smythe&lt;/fn&gt;

      &lt;sort&gt;Smythe, C&lt;/sort&gt;
      &lt;nickname&gt;Colin&lt;/nickname&gt;
      &lt;n&gt;
        &lt;family&gt;Smythe&lt;/family&gt;

        &lt;given&gt;Colin&lt;/given&gt;
        &lt;other&gt;Manfred&lt;/other&gt;
        &lt;other&gt;Wingarde&lt;/other&gt;
        &lt;prefix&gt;Dr.&lt;/prefix&gt;

        &lt;suffix&gt;C.Eng&lt;/suffix&gt;
        &lt;partname partnametype = "Initials"&gt;C.M.W.&lt;/partname&gt;
      &lt;/n&gt;
    &lt;/name&gt;
    &lt;demographics&gt;

      &lt;gender&gt;2&lt;/gender&gt;
      &lt;bday&gt;1958-02-18&lt;/bday&gt;
      &lt;disability&gt;None.&lt;/disability&gt;
    &lt;/demographics&gt;

    &lt;email&gt;colin\@dunelm.com&lt;/email&gt;
    &lt;url&gt;http://www.dunelm.com&lt;/url&gt;
    &lt;tel teltype = "Mobile"&gt;4477932335019&lt;/tel&gt;
    &lt;adr&gt;

      &lt;extadd&gt;Dunelm Services Limited&lt;/extadd&gt;
      &lt;street&gt;34 Acorn Drive&lt;/street&gt;
      &lt;street&gt;Stannington&lt;/street&gt;
      &lt;locality&gt; Sheffield&lt;/locality&gt;

      &lt;region&gt;S.Yorks&lt;/region&gt;
      &lt;pcode&gt;S7 6WA&lt;/pcode&gt;
      &lt;country&gt;UK&lt;/country&gt;
    &lt;/adr&gt;

    &lt;photo imgtype = "gif"&gt;
      &lt;extref&gt;http://www.dunelm.com/staff/colin2.gif&lt;/extref&gt;
    &lt;/photo&gt;
    &lt;institutionrole primaryrole = "No" institutionroletype = "Alumni"/&gt;
    &lt;datasource&gt;dunelm:colinsmythe:1&lt;/datasource&gt;

  &lt;/person&gt;
  &lt;person recstatus = "3"&gt;
    &lt;comments&gt;Delete this record.&lt;/comments&gt;
    &lt;sourcedid&gt;
      &lt;source&gt;Dunelm Services Limited&lt;/source&gt;

      &lt;id&gt;LL1&lt;/id&gt;
    &lt;/sourcedid&gt;
    &lt;name&gt;
      &lt;fn&gt;Lois Lane&lt;/fn&gt;
      &lt;sort&gt;Lane, L&lt;/sort&gt;

    &lt;/name&gt;
  &lt;/person&gt;
&lt;/enterprise&gt;
</pre><p>Above would get translated into calls to the batch sync API as
follows:</p><pre class="programlisting">
for { ... loop over persons in the document ... } {
        auth::batch::transaction \
            -job_id $job_id \
            -operation [ad_decode $recstatus 2 "update" 3 "delete" "insert"] \
            -authority_id $authority_id \
            -username { $userid if present, otherwise $sourcedid.id } \
            -first_names { $name.given if present, otherwise all except last part of $name.fn } \
            -last_name { $name.family if present, otherwise last part of $name.fn } \
            -email { $person.email ; we require this, even though the specification does not } \
            -url { $url, if present } \
            -portrait_url { $photo.imgtype/$photo.extref -- grab photo, store in DB }
    }
}
</pre><p>Mandatory fields which we can rely on are:</p><div class="orderedlist"><ol type="1">
<li><p>sourcedid: ID as defined by the source system. Used for
username.</p></li><li><p>name.fn (formatted name). Used for first_names, last_name</p></li>
</ol></div><p>Note that we require 'email' attribute, but the IMS Enterprise
spec does not. Hence, unless we change our data model to allow
users without an email address, we will have to throw an error.</p><p>Here's how we map IMS enterprise to OpenACS tables.</p><div class="orderedlist"><ol type="1">
<li>
<p>username:</p><div class="orderedlist"><ol type="a">
<li><p>&lt;userid&gt; <span class="emphasis"><em>...</em></span>
&lt;/userid&gt; if present.</p></li><li><p>&lt;sourcedid&gt;&lt;id&gt; <span class="emphasis"><em>...</em></span> &lt;/id&gt;&lt;/sourcedid&gt;
otherwise</p></li>
</ol></div>
</li><li>
<p>first_names:</p><div class="orderedlist"><ol type="a">
<li><p>&lt;name&gt;&lt;given&gt; <span class="emphasis"><em>...</em></span>&lt;/given&gt;&lt;/name&gt; if
present.</p></li><li><p>&lt;name&gt;&lt;fn&gt; <span class="emphasis"><em>...</em></span> ...&lt;/fn&gt;&lt;/name&gt;
otherwise</p></li>
</ol></div>
</li><li>
<p>last_name:</p><div class="orderedlist"><ol type="a">
<li><p>&lt;name&gt;&lt;family&gt; <span class="emphasis"><em>...</em></span>&lt;/family&gt;&lt;/name&gt; if
present.</p></li><li><p>&lt;name&gt;&lt;fn&gt;... <span class="emphasis"><em>...</em></span>&lt;/fn&gt;&lt;/name&gt;
otherwise</p></li>
</ol></div>
</li><li>
<p>email:</p><div class="orderedlist"><ol type="a">
<li><p>&lt;email&gt; <span class="emphasis"><em>...</em></span>&lt;/email&gt; if present.</p></li><li><p>Blank/unchanged if not.</p></li>
</ol></div>
</li><li>
<p>url:</p><div class="orderedlist"><ol type="a">
<li><p>&lt;url&gt; <span class="emphasis"><em>...</em></span>&lt;/url&gt; if present.</p></li><li><p>Blank/unchanged if not.</p></li>
</ol></div>
</li><li>
<p>portrait:</p><div class="orderedlist"><ol type="a"><li><p>&lt;photo imgtype="gif"&gt;&lt;extref&gt;<span class="emphasis"><em>...</em></span>&lt;/extref&gt;&lt;/photo&gt; if
present: HTTP GET the photo, insert it into the system. (Do we do
this, then, with all users when doing a snapshot update?)</p></li></ol></div>
</li>
</ol></div>
</div><div class="sect2" lang="en">
<div class="titlepage"><div><div><h3 class="title">
<a name="id2452593" id="id2452593"></a>
Resources</h3></div></div></div><div class="itemizedlist"><ul type="disc">
<li><p>
<a href="http://www.cetis.ac.uk/content/20020524162233" target="_top">Consolidation before the leap; IMS Enterprise 1.1</a>: This
article says that IMS Enterprise 1.1 (current version) does not
address the communication model, which is critically missing for
real seamless interoperability. IMS Enterprise 2.0 will address
this, but Blackboard, who's influential in the IMS committee, is
adopting OKI's programming interrfaces for this.</p></li><li><p><a href="http://www.cetis.ac.uk/content/20030717185453" target="_top">IMS and OKI, the wire and the socket</a></p></li>
</ul></div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="ext-auth-design" leftLabel="Prev" leftTitle="Design"
		    rightLink="ext-auth-ldap-install" rightLabel="Next" rightTitle=""
		    homeLink="index" homeLabel="Home" 
		    upLink="ext-auth-design" upLabel="Up"> 
		