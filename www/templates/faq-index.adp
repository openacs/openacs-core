<master>
<property name="title">@pa.title@</property>
<property name="context_bar">@pa.context_bar;noquote@</property>

<if @pa.content@ not nil>
<span class="reg">@pa.content@</span>
</if>
<span class="two">
Frequently Asked Questions:</span>
<ol>
<multiple name="content_items">
<li><span class="reg">
<a href="#@content_items.rownum@">@content_items.title@</a></span>
</li>
</multiple>
</ol>
<hr color="#999999" size="1" noshade>

<span class="three">
Questions and Answers:</span>
<ol>
<multiple name="content_items">
<a name="@content_items.rownum@"></a>
<li><span class="reg">
<b>Q: <i>@content_items.title@</i></b>
<br>
<b>A:</b> 
@content_items.content;noquote@
<br><br></span>
</li>
</multiple>
</ol>
