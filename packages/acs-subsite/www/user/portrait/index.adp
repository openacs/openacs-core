<master>
<property name="title">Portrait of @first_names@ @last_name@</property>
<property name="context">@context;noquote@</property>

<switch @return_code@>

<case value="no_error">
<p>This is the image that we show to other users at @system_name@:</p>
</if>

<center>
<img @widthheight@ src="@subsite_url@shared/portrait-bits.tcl?@export_vars@"
alt="Portrait of @first_names@ @last_name@">
</center>

<ul>
<li>Uploaded:  @pretty_date@</li>
<li>Comment: 
<blockquote>
@description@
</blockquote>
</li>
</ul>

<if @admin_p@ eq 1>
Options:

<ul>
<li><a href="comment-edit?@export_edit_vars@">edit comment</a></li>
<li><a href="upload?return_url=@return_url@">upload a replacement portrait</a></li>

<li><a href="erase?@export_edit_vars@">erase portrait</a></li>

</ul>
</if>
</case>

<case value="no_user">
We can't find you (user @user_id@) in the users table.  Probably your
account was deleted for some reason.
</case>

<case value="no_portrait_info">
The picture of you in the system is invalid. Please
<a href="upload?return_url=@return_url@">upload</a> another picture.
</case>

<case value="no_portrait">
<if @admin_p@ eq "0">
This user doesn't have a portrait yet. You can
<a href="upload?@export_edit_vars@">go upload the user's portrait</a>.
</if>
<else>
You don't have a portrait yet. You can
<a href="upload?return_url=@return_url@">go upload your portrait</a>.
</else>
</case>
 
</switch>





