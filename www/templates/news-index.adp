<master>
<property name="title">@pa.title@</property>
<property name="context_bar">@pa.context_bar;noquote@</property>
<br>
<table cellpadding=0 cellspacing=0 border=0 width="100%">
<tr>
<!-- LEFT SIDE CELL WITH NEWS -->
<td align="left" valign="top" width="100%">

<!-- LEFT NESTED TABLE START -->

<TABLE WIDTH="100%" BORDER="0" CELLSPACING="0" CELLPADDING="0">

<tr>
<td align="left" valign="top" bgcolor="#66ccff"><img
src="/templates/images/spacer.gif" alt="" height="1" width="8"></td>

<td align="left" valign="top" bgcolor="#66ccff"><span class="nav">
OpenACS Community News
<if @archive_p@ eq "t"> Archive</if>
</span></td>

<td align="left" valign="top" bgcolor="#66ccff"><img
src="/templates/images/spacer.gif" alt="" height="1" width="8"></td>
</tr>

<tr>
<td align="left" valign="top" bgcolor="#999999" colspan="3"><img
src="/templates/images/line.gif" alt="" height="2" WIDTH="210"></td>

</tr>

<tr>

<td align="left" valign="top" bgcolor="#ffffff"><img
src="/templates/images/spacer.gif" width="8" height="1"></td>

<td align="left" valign="top" bgcolor="#ffffff">
<img src="/templates/images/spacer.gif" width="8" height="5"><br clear="left">
<span class="reg">
<if @content_items:rowcount@ eq 0>
<em>There are no current news items</em>
</if>

<ul>
<multiple name="content_items">
<li><span class="footer">@content_items.release_date@:</span> 
<a href="@content_items.url@">@content_items.title@</a><br><br></li>
</multiple>

</ul>

<if @archive_p@ ne "t"> 
If you're looking for an old news article, check the 
<a href="?archive_p=t">expired news</a>.
</if> <else>
You're viewing expired news items.  <a href="?archive_p=f">
Click here for the fresh ones</a>.
</else>
</span>
<br> 
</td>

<td align="left" valign="top" bgcolor="#ffffff"><img
src="/templates/images/spacer.gif" alt="" height="1" width="8"></td>

</tr>
</table>
<!-- NESTED TABLE END -->

<br>
</TD>

<!-- MARGIN -->
<td align="left" valign="top" width="35"><img src="/templates/images/spacer.gif" alt=""
height="1" width="20" alt=""></td>
<!--END MARGIN-->


<!--START EVENT SECTION - RIGHT SIDE CELL-->
<td align="left" valign="top" width="250">

<!-- NESTED EVENTS TABLE START -->

<TABLE WIDTH="100%" BORDER="0" CELLSPACING="0" CELLPADDING="0">
<tr>
<td align="left" valign="top" bgcolor="#66ccff"><img
src="/templates/images/spacer.gif" alt="" height="1" width="8"></td>

<td align="left" valign="top" bgcolor="#66ccff"><span
class="nav">Special Events</span></td>

<td align="left" valign="top" bgcolor="#cccccc"><img 
src="/templates/images/greyright.gif" alt="" height="8" width="8"></td>

</tr>
<tr>

<td align="left" valign="top" bgcolor="#999999" colspan="2"><img
src="/templates/images/line.gif" alt="" height="2" width="250"></td>

<td align="left" valign="top" bgcolor="cccccc"><img
src="/templates/images/spacer.gif" alt="" height="2" WIDTH="8"></td>

</tr>
<tr>

<td align="left" valign="top" bgcolor="#DEDEDE"><img
src="/templates/images/spacer.gif" alt="" height="1" width="8"></td>


<td align="left" valign="top" bgcolor="#DEDEDE">
<img src="/templates/images/spacer.gif" alt="" height="8" width="234"><br clear="left">

<span>
<!-- _____________ EVENTS CONTENT GOES HERE ____________ -->
<if @pa.content@ not nil>
@pa.content@
</if>
</span>
<!-- _____________ END EVENTS CONTENT  ____________ -->
</td>

<td align="left" valign="top" bgcolor="#cccccc"><img
src="/templates/images/spacer.gif" alt="" height="1" width="8"></td>

</tr>
<TR>
<td align="left" valign="top" bgcolor="#cccccc" COLSPAN="3"><img
src="/templates/images/grey.gif" alt="" height="8" width="8"></td>
</tr>

</table>
<!-- NESTED TABLE END -->
<br>
</td>
<!-- end RIGHT cell -->
</tr>
</table>

<!-- END MAIN CONTENT TABLE -->
