<master>
<property name=title>Upload Portrait</property>
<property name="context">@context@</property>

How would you like the world to see @first_names@ @last_name@?

<p>

Upload your favorite file, a scanned JPEG or GIF, from your desktop
computer system (note that you can't refer to an image elsewhere on
the Internet; this image must be on your computer's hard drive).

<blockquote>
<form enctype=multipart/form-data method=POST action="upload-2">
@export_vars@
<table>
<tr>
<td valign=top align=right>Filename: </td>
<td>
<input type=file name=upload_file size=20><br>
<font size=-1>Use the "Browse..." button to locate your file, then click "Open".</font>
</td>
</tr>
<tr>
<td valign=top align=right>Story Behind Photo
<br>
<font size=-1>(optional)</font>
</td>
<td><textarea rows=6 cols=50 wrap=soft name=portrait_comment>
</textarea>
</td>
</tr>

</table>
<p>
<center>
<input type=submit value="Upload">
</center>
</blockquote>
</form>

