<master>
<property name="title">@pa.title;noquote@</property>
<property name="context_bar">@pa.context_bar;noquote@</property>

<span class="reg">
<!-- <b>@pa.description;noquote@</b>
<br>
-->
</span>
<div id="page-body">
@pa.content;noquote@
</div>
<br clear="left">

<if @comments_link@ not nil>
  @comments;noquote@
  <p>
    @comments_link;noquote@
  </p>
</if>

