<master src="/www/templates/new-master">
<property name="title">@pa.title@</property>
<property name="context_bar">@pa.context_bar;noquote@</property>
<br>
<table cellpadding=0 cellspacing=0 border=0 width="100%">
<tr>
<td align="left" valign="top" bgcolor="#efefef" width="50%">

<!-- FORUMS NESTED TABLE START -->
<TABLE WIDTH="100%" BORDER="0" CELLSPACING="0" CELLPADDING="0">
<tr>
<td align="left" valign="top" bgcolor="#66ccff"><img 
src="images/spacer.gif" alt="" height="1" width="8"></td>

<td align="left" valign="top" bgcolor="#66ccff"><span 
class="nav"><a href="/forums" class="top">OpenACS Community Forums</a></span></td>

<td align="left" valign="top" bgcolor="#66ccff"><img 
src="images/spacer.gif" alt="" height="1" width="8"></td>

</tr>
<tr>

<td align="left" valign="top" bgcolor="#999999" colspan="3"><img 
src="images/line.gif" alt="" height="2" width="210"></td>

</tr>
<tr>

<td align="left" valign="top" bgcolor="#efefef" colspan="3"><img
src="images/spacer.gif" alt="" height="6" width="1"></td>

</tr>
<tr>

<td align="left" valign="top" bgcolor="#EFEFEF"><img 
src="/templates/images/spacer.gif" alt="" height="1" width="8"></td>

<td align="left" valign="top" bgcolor="#EFEFEF">

<span class="reg">
<ul>
<multiple name=forums>
  <li><a href="/forums/forum-view?forum_id=@forums.forum_id@">@forums.short_name@</a>
</multiple>
</ul>
<br><br></td>

<td align="left" valign="top" bgcolor="#EFEFEF"><img 
src="/templates/images/spacer.gif" alt="" height="1" width="8"></td>

</tr>
</table>

<!-- NESTED TABLE END -->

</td>

<!-- MARGIN -->
<td align="left" valign="top" width="35"><img src="/templates/images/spacer.gif" alt="" 
height="1" width="20" alt=""></td>

<td align="center" valign="top" bgcolor="#efefef"  width="50%">
<!-- OPENACS SITES LIST - NESTED TABLE START -->
<TABLE WIDTH="100%" BORDER="0" CELLSPACING="0" CELLPADDING="0">
<tr>

<td align="left" valign="top" bgcolor="#66ccff"><img 
src="/templates/images/spacer.gif" alt="" height="1" width="8"></td>

<td align="left" valign="top" bgcolor="#66ccff"><span 
class="nav"><a href="sites" class="top">OpenACS Sites</a>
</span></td>

<td align="left" valign="top" bgcolor="#66ccff"><img 
src="/templates/images/spacer.gif" alt="" height="1" width="8"></td>

</tr>
<tr>

<td align="left" valign="top" bgcolor="#999999" colspan="3"><img 
src="/templates/images/line.gif" alt="" height="2" width="210"></td>

</tr>
<tr>

<td align="left" valign="top" bgcolor="#efefef" colspan="3"><img
src="images/spacer.gif" alt="" height="6" width="1"></td>

</tr>
<tr>

<td align="left" valign="top" bgcolor="#EFEFEF"><img 
src="/templates/images/spacer.gif" alt="" height="1" width="8"></td>

<td align="left" valign="top" bgcolor="#EFEFEF">

<span>
<ul>
<multiple name=sites>
<if @sites.rownum@ le @n_sites@>
  <li><a href="@sites.url@">@sites.title@</a> -- @sites.description@</li>
</if>
</multiple>
</ul>

<if @sites:rowcount@ gt @n_sites@>
  &nbsp;&nbsp;<a href="oacs_sites">more sites</a>...</span>
  <br><br>
</if>

</span>
</td>

<td align="left" valign="top" bgcolor="#EFEFEF"><img 
src="/templates/images/spacer.gif" alt="" height="1" width="8"></td>


</tr>

</table>

<!-- NESTED TABLE END-->


</td>
</tr>
</TABLE>

<br>

<!-- START new TABLE FOR OPENACS SITES LISTING -->

<table cellspacing="0" cellpadding="0" border="0" width="100%">
<tr>
<td valign="top" align="left" bgcolor="#efefef">

<!-- JOB BOARDS NESTED TABLE START -->

<TABLE WIDTH="100%" BORDER="0" CELLSPACING="0" CELLPADDING="0">
<tr>
<td align="left" valign="top" bgcolor="#66ccff"><img 
src="/templates/images/spacer.gif" alt="" height="1" width="8"></td>

<td align="left" valign="top" bgcolor="#66ccff"><span 
class="nav"><a href="jobs" class="top">Community Job Postings</a></span></td>

<td align="left" valign="top" bgcolor="#66ccff"><img 
src="/templates/images/spacer.gif" alt="" height="1" width="8"></td>

</tr>
<tr>

<td align="left" valign="top" bgcolor="#999999" colspan="3"><img 
src="/templates/images/line.gif" alt="" height="2" width="210"></td>

</tr>
<tr>

<td align="left" valign="top" bgcolor="#efefef" colspan="3"><img
src="images/spacer.gif" alt="" height="6" width="1"></td>

</tr>
<tr>

<td align="left" valign="top" bgcolor="#EFEFEF"><img 
src="/templates/images/spacer.gif" alt="" height="1" width="8"></td>

<td align="left" valign="top" bgcolor="#EFEFEF">

<span>
<ul>
<multiple name=jobs>
<if @jobs.rownum@ le @n_jobs@>
  <li><a href="jobs/@jobs.url@">@jobs.title@</a> - @jobs.description@</li>
</if>
</multiple>
</ul>

<if @jobs:rowcount@ gt @n_jobs@>
   &nbsp;&nbsp;<a href="jobs">more jobs</a>...
  <br><br>
</if>
</span>
</td>

<td align="left" valign="top" bgcolor="#EFEFEF"><img 
src="/templates/images/spacer.gif" alt="" height="1" width="8"></td>

</tr>
</table>


<!-- NESTED TABLE END -->

<br>
</td>

<!-- MARGIN -->
<td align="left" valign="top" width="35"><img src="/templates/images/spacer.gif" alt=""
height="1" width="20" alt=""></td>

<!-- START CELL FOR OACS COMPANIES -->

<td align="left" valign="top" bgcolor="#efefef">

<!-- COMPANIES NESTED TABLE START -->

<TABLE WIDTH="100%" BORDER="0" CELLSPACING="0" CELLPADDING="0">
<tr>

<td align="left" valign="top" bgcolor="#66ccff"><img 
src="/templates/images/spacer.gif" alt="" height="1" width="8"></td>

<td align="left" valign="top" bgcolor="#66ccff"><span 
class="nav"><a href="companies" class="top">OpenACS Companies</a>
</span></td>

<td align="left" valign="top" bgcolor="#66ccff"><img 
src="/templates/images/spacer.gif" alt="" height="1" width="8"></td>

</tr>
<tr>

<td align="left" valign="top" bgcolor="#999999" colspan="3"><img 
src="/templates/images/line.gif" alt="" height="2" width="210"></td>

</tr>
<tr>

<td align="left" valign="top" bgcolor="#efefef" colspan="3"><img
src="images/spacer.gif" alt="" height="6" width="1"></td>

</tr>
<tr>

<td align="left" valign="top" bgcolor="#efefef"><img 
src="/templates/images/spacer.gif" alt="" height="1" width="8"></td>

<td align="left" valign="top" bgcolor="#efefef">


<span>
An alphabetical listing of companies that can help you with OpenACS.

<!--
<ul>
<multiple name=companies>
  <li><a href="@companies.url@">@companies.title@</a>
  <if @companies.description@ not nil> - @companies.description@</if></li>
</multiple>
</ul>
-->

<ul>
<multiple name=companies>
<if @companies.rownum@ le @n_companies@>
  <li><a href="@companies.url@">@companies.title@</a>
  <if @companies.description@ not nil> - @companies.description@</if></li>
</if>
</multiple>
</ul>

<if @companies:rowcount@ gt @n_companies@>
  &nbsp;&nbsp;<a href="companies">more companies</a>...  
<br><br>
</if>

</span>
</td>

<td align="left" valign="top" bgcolor="#efefef"><img 
src="/templates/images/spacer.gif" alt="" height="1" width="8"></td>


</tr>
</table>
<!-- NESTED TABLE END -->

<br>
</td>

</tr>
</table>










