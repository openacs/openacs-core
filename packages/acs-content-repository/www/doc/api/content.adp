
<property name="context">{/doc/acs-content-repository {Content Repository}} {Package: content}</property>
<property name="doc(title)">Package: content</property>
<master>
<h2>content</h2>
<p>
<a href="../index.html">Content Repository</a> : content</p>
<hr>
<ul><li>Function content.blob_to_string</li></ul>
<table cellpadding="3" cellspacing="0" border="0">
<tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><i>Not yet documented</i></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><tt>
function blob_to_string(
  blob_loc blob) return varchar2
as language
  java
name
  'com.arsdigita.content.Util.blobToString(
    oracle.sql.BLOB
   ) return java.lang.String';

</tt></pre></td></tr>
</table>
<ul><li>Procedure content.blob_to_file</li></ul>
<table cellpadding="3" cellspacing="0" border="0">
<tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><i>Not yet documented</i></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><tt>
procedure blob_to_file(
s varchar2, blob_loc blob)
as language
  java
name
  'com.arsdigita.content.Util.blobToFile(
  java.lang.String, oracle.sql.BLOB
  )';

</tt></pre></td></tr>
</table>
<ul><li>Procedure content.string_to_blob</li></ul>
<table cellpadding="3" cellspacing="0" border="0">
<tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><i>Not yet documented</i></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><tt>
procedure string_to_blob(
  s varchar2, blob_loc blob)
as language
  java
name
  'com.arsdigita.content.Util.stringToBlob(
    java.lang.String, oracle.sql.BLOB
   )';

</tt></pre></td></tr>
</table>
<ul><li>Procedure content.string_to_blob_size</li></ul>
<table cellpadding="3" cellspacing="0" border="0">
<tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><i>Not yet documented</i></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><tt>
procedure string_to_blob_size(
  s varchar2, blob_loc blob, blob_size number)
as language
  java
name
  'com.arsdigita.content.Util.stringToBlob(
    java.lang.String, oracle.sql.BLOB, int
   )';

</tt></pre></td></tr>
</table>
<p>Last Modified: $Id: content.html,v 1.1.1.1 2001/03/13 22:59:26
ben Exp $</p>
