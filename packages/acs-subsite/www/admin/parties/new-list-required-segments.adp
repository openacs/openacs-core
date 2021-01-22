<master>
<property name="context">@context;literal@</property>
<property name="doc(title)">Create a new user</property>

<blockquote>

In order to create a new @object_type_pretty_name@ with @rel_type_pretty_name@
to @group_name@, the @object_type_pretty_name@ must be added to other
groups with other relationships.

<p>

<multiple name="required_segments">

<if @required_segments.rownum;literal@ true>
    You can <a href="new?@export_url_vars@&amp;add_to_group_id=@required_segments.group_id@&amp;add_with_rel_type=@required_segments.rel_type_enc@">begin</a>
    the process of adding a new @object_type_pretty_name@ and giving it the
    following relationships to the necessary groups:

    <ul>
</if>  

<li> @required_segments.rel_type_pretty_name@ to @required_segments.group_name@

</multiple>

</ul>

</blockquote>
