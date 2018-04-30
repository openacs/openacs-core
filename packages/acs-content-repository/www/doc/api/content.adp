
<property name="context">{/doc/acs-content-repository {ACS Content Repository}} {Package: content}</property>
<property name="doc(title)">Package: content</property>
<master>
<h2>content</h2>
<p>
<a href="../index">Content Repository</a> : content</p>
<hr>
<ul>
<li>Function content.blob_to_string
<table cellpadding="3" cellspacing="0" border="0">
<tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><em>Not yet documented</em></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function blob_to_string(
  blob_loc blob) return varchar2
as language
  java
name
  'com.arsdigita.content.Util.blobToString(
    oracle.sql.BLOB
   ) return java.lang.String';

</kbd></pre></td></tr>
</table>
</li><li>Procedure content.blob_to_file
<table cellpadding="3" cellspacing="0" border="0">
<tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><em>Not yet documented</em></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure blob_to_file(
s varchar2, blob_loc blob)
as language
  java
name
  'com.arsdigita.content.Util.blobToFile(
  java.lang.String, oracle.sql.BLOB
  )';

</kbd></pre></td></tr>
</table>
</li><li>Procedure content.string_to_blob
<table cellpadding="3" cellspacing="0" border="0">
<tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><em>Not yet documented</em></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure string_to_blob(
  s varchar2, blob_loc blob)
as language
  java
name
  'com.arsdigita.content.Util.stringToBlob(
    java.lang.String, oracle.sql.BLOB
   )';

</kbd></pre></td></tr>
</table>
</li><li>Procedure content.string_to_blob_size
<table cellpadding="3" cellspacing="0" border="0">
<tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><em>Not yet documented</em></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure string_to_blob_size(
  s varchar2, blob_loc blob, blob_size number)
as language
  java
name
  'com.arsdigita.content.Util.stringToBlob(
    java.lang.String, oracle.sql.BLOB, int
   )';

</kbd></pre></td></tr>
</table>
</li>
</ul>
<p>Last Modified: $&zwnj;Id: content.html,v 1.2 2017/08/07 23:47:47
gustafn Exp $</p>
