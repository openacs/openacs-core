<master>
<property name=title>@title;noquote@</property>
<property name="context">@context;noquote@</property>

<if @package_slider_list@ ne "">
<table align=right><tr><td>
[ <%= [join $package_slider_list " | "] %> ]
</td></tr></table>
</if>

<blockquote>
<pre>
@source_text@
</pre>
</blockquote>


