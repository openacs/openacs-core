<master>
  <property name="title">@page_title@</property>
  <property name="context">@context@</property>

<p>
  Are you sure you want to delete <if @num@ eq 1>this application</if><else>these @num@ applications</else>?
</p>

<p>
  <a href="@yes_url@">Delete</a> - <a href="@no_url@">Cancel, do not delete</a>
</p>
