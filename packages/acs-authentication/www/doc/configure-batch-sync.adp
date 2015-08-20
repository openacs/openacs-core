
<property name="context">{/doc/acs-authentication {Authentication}} {Configure Batch Synchronization}</property>
<property name="doc(title)">Configure Batch Synchronization</property>
<master>

<body>
<div class="navheader"><table width="100%" summary="Navigation header" border="0"><tr>
<td width="20%" align="left"><a accesskey="p" href="ext-auth-ldap-install">Prev</a></td><th width="60%" align="center">Installation</th><td width="20%" align="right"><a accesskey="n" href="ext-auth-design">Next</a></td>
</tr></table></div><div class="sect1" lang="en">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="configure-batch-sync" id="configure-batch-sync"></a>Configure
Batch Synchronization</h2></div></div></div><div class="orderedlist"><ol type="1">
<li><p>Browse to the authentication administration page, <tt class="computeroutput">http://<span class="replaceable"><span class="replaceable">yourserver</span></span><a href="/acs-admin/auth/" target="_top">/acs-admin/auth/</a>
</tt> and choose an authority for
batch sync.</p></li><li><p>Set Batch sync enabled to Yes. Set GetDocument Implementation to
HTTP GET. Set ProcessDocument Implementation to IMS Enterprise 1.1.
These settings will cause OpenACS to attempt to retrieve via HTTP a
list of users in XML format from a location we will specify in a
few steps.</p></li><li><p>Click OK.</p></li><li><p>On the next page, click <tt class="computeroutput">Configure</tt> on the GetDocument Implementation
line.</p></li><li><p>Enter either or both the IncrementalURL and SnapshotURL. These
are the URLs which the external Authority will supply with XML
files in IMS Enterprise 1.1 format.</p></li><li>
<p>Configure your Authority (RADIUS server, etc) to supply XML
files to the URLs IncrementalURL and SnapshotURL. A typical set of
incremental file record looks like:</p><pre class="programlisting">
&lt;?xml version="1.0" encoding="ISO-8859-1"?&gt;
&lt;enterprise&gt;
  &lt;properties&gt;
    &lt;datasource&gt;FOO&lt;/datasource&gt;
    &lt;target&gt;dotLRN&lt;/target&gt;
    &lt;type&gt;DB Increment&lt;/type&gt;
    &lt;datetime&gt;28-oct-2003#16:06:02&lt;/datetime&gt;
  &lt;/properties&gt;
  &lt;person recstatus = "1"&gt;
    &lt;sourcedid&gt;
      &lt;source&gt;FOO&lt;/source&gt;
      &lt;id&gt;karlf&lt;/id&gt;
    &lt;/sourcedid&gt;
    &lt;name&gt;
      &lt;n&gt;
        &lt;given&gt;Karl&lt;/given&gt;
        &lt;family&gt;Fritz&lt;/family&gt;
        &lt;prefix&gt;&lt;/prefix&gt;
      &lt;/n&gt;
    &lt;/name&gt;
    &lt;email&gt;karlf\@example.net&lt;/email&gt;
  &lt;/person&gt;
  &lt;person recstatus = "2"&gt;    &lt;!--modified person--&gt;
    ...
  &lt;/person&gt;
  &lt;person recstatus = "3"&gt;    &lt;!--deleted person--&gt;
  &lt;sourcedid&gt;
    &lt;id&gt;LL1&lt;/id&gt;      &lt;!--only requires username--&gt;
  &lt;/sourcedid&gt;
  &lt;/person&gt;
&lt;/enterprise&gt;
</pre><p>A snapshot file is similar but doesn't have recstatus, since
it's not a delta but a list of valid records. See the larger
example in the design document for more details.</p><p>(More information: <a href="ims-sync-driver-design" title="IMS Sync driver design">the section called “IMS Sync driver
design”</a>, <a href="http://www.imsproject.org/enterprise/" target="_top">The IMS 1.1 spec</a>)</p>
</li>
</ol></div><div class="cvstag">($Id: configure-batch-sync.html,v 1.2
2004/02/19 14:59:42 joela Exp $)</div>
</div><div class="navfooter">
<hr><table width="100%" summary="Navigation footer">
<tr>
<td width="40%" align="left"><a accesskey="p" href="ext-auth-ldap-install">Prev</a></td><td width="20%" align="center"><a accesskey="h" href="index">Home</a></td><td width="40%" align="right"><a accesskey="n" href="ext-auth-design">Next</a></td>
</tr><tr>
<td width="40%" align="left">Installing LDAP support</td><td width="20%" align="center"><a accesskey="u" href="ext-auth-install">Up</a></td><td width="40%" align="right">Design</td>
</tr>
</table><hr><address><a href="mailto:docs\@openacs.org">docs\@openacs.org</a></address>
</div><a name="comments" id="comments"></a><center><a href="http://openacs.org/doc/configure-batch-sync.html#comments">View
comments on this page at openacs.org</a></center>
</body>
