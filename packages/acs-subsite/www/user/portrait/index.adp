<master>
<property name="&doc">doc</property>
<property name="context">@context;literal@</property>

<switch @return_code@>

<case value="no_error">
<if @admin_p;literal@ true>
<p>#acs-subsite.lt_This_is_the_image_that#:</p>
</if>

<div style="text-align:center">
<img @widthheight@ src="@portrait_image_url;noi18n@" alt="@doc.title@">
</div>

<ul>
<li>#acs-subsite.lt_Uploaded_pretty_date#</li>
<li>#acs-subsite.Caption#: 
<p>@description@</p>
</li>
</ul>

<if @admin_p;literal@ true>
#acs-subsite.Options#:

<ul>
<li><a href="comment-edit?@export_edit_vars@">#acs-subsite.Edit_caption#</a></li>
<li><a href="upload?return_url=@return_url@">#acs-subsite.upload_a_replacement_por#</a></li>

<li><a href="erase?@export_edit_vars@">#acs-subsite.Erase_Portrait#</a></li>

</ul>
</if>
</case>

<case value="no_user">
<p>#acs-subsite.lt_We_cant_find_you#</p>
</case>

<case value="no_portrait_info">
<p>
#acs-subsite.lt_The_picture_of_you_in#
<a href="upload?return_url=@return_url@">#acs-subsite.upload#</a> #acs-subsite.another_picture#
</p>
</case>

<case value="no_portrait">
<p>
<if @admin_p;literal@ false>
#acs-subsite.lt_This_user_doesnt_have#
<a href="upload?@export_edit_vars@">#acs-subsite.go_upload_the_users_por#</a>.
</if>
<else>
#acs-subsite.You_dont_have_a_portrait#
<a href="upload?return_url=@return_url@">#acs-subsite.go_upload_your_portrait#</a>.
</else>
</p>
</case>
 
</switch>
