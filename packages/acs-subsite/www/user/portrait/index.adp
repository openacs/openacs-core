<master>
<property name="title">#acs-subsite.lt_Portrait_of_first_last#</property>
<property name="context">@context;noquote@</property>

<switch @return_code@>

<case value="no_error">
<if @admin_p@ eq 1>
<p>#acs-subsite.lt_This_is_the_image_that#:</p>
</if>

<center>
<img @widthheight@ src="@subsite_url@shared/portrait-bits.tcl?@export_vars@"
alt="Portrait of @first_names@ @last_name@">
</center>

<ul>
<li>#acs-subsite.lt_Uploaded_pretty_date#</li>
<li>#acs-subsite.Comment#: 
<blockquote>
@description@
</blockquote>
</li>
</ul>

<if @admin_p@ eq 1>
#acs-subsite.Options#:

<ul>
<li><a href="comment-edit?@export_edit_vars@">#acs-subsite.edit_comment#</a></li>
<li><a href="upload?return_url=@return_url@">#acs-subsite.upload_a_replacement_por#</a></li>

<li><a href="erase?@export_edit_vars@">#acs-subsite.erase_portrait#</a></li>

</ul>
</if>
</case>

<case value="no_user">
#acs-subsite.lt_We_cant_find_you#
</case>

<case value="no_portrait_info">
#acs-subsite.lt_The_picture_of_you_in#
<a href="upload?return_url=@return_url@">#acs-subsite.upload#</a> #acs-subsite.another_picture#
</case>

<case value="no_portrait">
<if @admin_p@ eq "0">
#acs-subsite.lt_This_user_doesnt_have#
<a href="upload?@export_edit_vars@">#acs-subsite.go_upload_the_users_por#</a>.
</if>
<else>
#acs-subsite.You_dont_have_a_portrait#
<a href="upload?return_url=@return_url@">#acs-subsite.go_upload_your_portrait#</a>.
</else>
</case>
 
</switch>






