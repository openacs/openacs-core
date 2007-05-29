<master>
<property name=title>#acs-subsite.Upload_Portrait#</property>
<property name="context">@context;noquote@</property>

#acs-subsite.lt_How_would_you_like_the#

<p>

#acs-subsite.lt_Upload_your_favorite#

<blockquote>
<form enctype="multipart/form-data" method=POST action="upload-2">
@export_vars;noquote@
<table>
<if @portrait_p@ eq 1>
<tr>
<td colspan=2 align="center">
<img src="/shared/portrait-bits.tcl?user_id=@current_user_id@"/>
<br>
(<a href="erase?return_url=@return_url;noquote@">Delete Portrait</a>)
</td>
</tr>
</if>
<tr>
<td valign=top align=right>#acs-subsite.Filename#: </td>
<td>
<input type=file name=upload_file size=20><br>
<font size=-1>#acs-subsite.lt_Use_the_Browse_button#</font>
</td>
</tr>
<tr>
<td valign=top align=right>#acs-subsite.Story_Behind_Photo#
<br>
<font size=-1>#acs-subsite.optional#</font>
</td>
<td><textarea rows=6 cols=50 name="portrait_comment">
</textarea>
</td>
</tr>

</table>
<p>
<center>
<input type=submit value="Upload">
</center>
</form>
</blockquote>
