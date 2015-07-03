<master>
  <property name="doc(title)">@page_title;literal@</property>
  <property name="context">@context;literal@</property>

<h2>@page_title@</h2>
@listing;noquote@

<p>
  Are you sure you want to delete <if @num@ eq 1>this application</if><else>these @num@ applications</else>?
</p>

<p>
  <a href="@yes_url@" class="button">Delete</a> 
  &nbsp;&nbsp;&nbsp;&nbsp;
  <a href="@no_url@" class="button">Cancel, do not delete</a>
</p>
