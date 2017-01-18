<master src="master-sample">

<!-- examine master-sample.adp to see that title and closing_text are essentially
used as onevalues within the master page -->
<property name="doc(title)">@name;noquote@'s Personal Home Page</property>
<property name="closing_text"><small>It's been a pleasure to serve you this page</small></property>


<h2>@name@'s Personal Web Page</h2>
<p>

This web page is the uniquely conceived brainchild of @name@, a product of long @time_periods@ of 
assiduous labor and the creative genius of @name@.  Esoteric, unforeseen, and unforgettable, 
this web page stands as a monument to the singular and inimitable mind that is <strong>@name@</strong>.

<p>

Now, for some basic contact information:
<table>
<tr><td align="left">Name:</td><td><a href="mailto:@email@">@name@</a></td></tr>
<tr><td>Address:</td><td>@address@</td></tr>
<tr><td>Email:</td><td>@email</td></tr>
</table>

<p>
These are my best friends!  Email them!
<ul>
<multiple name="friends">
<li>@friends.first_names@, a @friends.age@ year old
<if @friends.gender@ eq f>
 gal
</if>
<else>
 guy
</else>
    
who lives at @friends.address@ and

<if @friends.likes_chocolate_p;literal@ false>
doesn't like
</if>
<else>
likes
</else>
chocolate
</li><br>
also, @friends.extra_column@<br>
and one more thing: @friends.another_column@<p>

</multiple>
</ul>

<blockquote>
@header@<br>
<slave>
</blockquote>






