<master>
<property name="title">Portrait of @first_names;noquote@ @last_name;noquote@</property>
<property name="context">@context;noquote@</property>

<p>This is the image that we show to other users at @system_name@:</p>

<center>
<img @widthheight@ src="/shared/portrait-bits.tcl?@export_vars@">
</center>

Data:

<ul>
<li>Uploaded:  @pretty_date@</li>
<li>Comment: 
<blockquote>
@description@
</blockquote>
</li>
</ul>

Options:

<ul>
<li><a href="comment-edit?@export_edit_vars@">edit comment</a></li>
<li><a href="upload?@export_edit_vars@">upload a replacement portrait</a></li>

<li><a href="erase?@export_edit_vars@">erase portrait</a></li>

</ul>


