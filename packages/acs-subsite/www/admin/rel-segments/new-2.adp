<master>
<property name="context">@context;noquote@</property>
<property name="title">Create relational segment</property>
<property name="focus">segment_new.segment_name</property>

You are creating a segment to represent all @role_pretty_plural@ of 
<if @subsite_group_id@ eq @group_id@>
    <a href=../groups/index?view_by=rel_type>@group_name@</a>
</if>
<else>
    <a href=../groups/one?group_id=@group_id@>@group_name@</a>
</else>

<p>

<form name=segment_new method=get action=new-3>
@export_vars;noquote@

Segment Name:
  <input type=text name=segment_name maxlength=230>

<p><center><input type=submit value="Create"></center>

</form>

</else>