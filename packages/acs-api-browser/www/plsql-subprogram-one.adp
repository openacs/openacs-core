<master>
<property name="doc(title)">@title;literal@</property>
<property name="context">@context;literal@</property>

<if @package_slider_list@ ne "">
<div style='float: right;'>
[ <%= [join $package_slider_list " | "] %> ]
</div>
</if>

<blockquote>
<pre>
@source_text@
</pre>
</blockquote>


