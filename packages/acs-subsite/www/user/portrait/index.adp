<master>
<property name="title">Portrait of @first_names;noquote@ @last_name;noquote@</property>
<property name="context">@context;noquote@</property>

<if @admin_p@ eq 1>
<p>This is the image that we show to other users at @system_name@:</p>
</if>

<center>
<img @widthheight@ src="@subsite_url@shared/portrait-bits.tcl?@export_vars@">
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
<li><a href="upload?@export_edit_vars@">upload a replacement portrait</a></li>

<li><a href="erase?@export_edit_vars@">erase portrait</a></li>

</ul>
</if>
