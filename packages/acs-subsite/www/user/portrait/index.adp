<master>
<property name=title>Portrait of @first_names@ @last_name@</property>

<h2>Portrait of @first_names@ @last_name@</h2>

@context_bar@

<hr>

This is the image that we show to other users at @system_name@:

<br>
<br>

<center>
<img @widthheight@ src="/shared/portrait-bits.tcl?@export_vars@">
</center>

Data:

<ul>
<li>Uploaded:  @pretty_date@
<li>Comment:  

<blockquote>
@description@
</blockquote>

</ul>

Options:

<ul>
<li><a href=comment-edit?@export_edit_vars@>edit comment</a>
<li><a href="upload?@export_edit_vars@">upload a replacement</a>

<p>

<li><a href="erase?@export_edit_vars@">erase</a>

</ul>


