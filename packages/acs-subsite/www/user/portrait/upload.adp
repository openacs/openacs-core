<master>
<property name=title>#acs-subsite.Upload_Portrait#</property>
<property name="context">@context;noquote@</property>


<p>#acs-subsite.lt_How_would_you_like_the#</p>

<p>#acs-subsite.lt_Upload_your_favorite#</p>

<div>
<form enctype="multipart/form-data" method=POST action="upload-2">
<div>@export_vars;noquote@</div>
<table>
<if @portrait_p@ eq 1>
<tr>
<td colspan=2 align="center">
<img src="/shared/portrait-bits.tcl?user_id=@current_user_id@" alt="Your portrait">
<br>
(<a href="erase?return_url=@return_url;noquote@">Delete Portrait</a>)
</td>
</tr>
</if>
<tr>
<td valign=top align=right>#acs-subsite.Filename#: </td>
<td>
<input type=file name=upload_file size=20><br>
#acs-subsite.lt_Use_the_Browse_button#
</td>
</tr>
<tr>
<td valign=top align=right>#acs-subsite.Story_Behind_Photo#
<br>
#acs-subsite.optional#
</td>
<td><textarea rows=6 cols=50 name="portrait_comment">
</textarea>
</td>
</tr>

</table>
<p style="text-align:center">
<input type=submit value="Upload">
</p>
</form>
</div>
