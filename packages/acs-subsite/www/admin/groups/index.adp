<master>
<property name="context">@context;noquote@</property>
<property name="title">Group administration</property>

Currently, the @instance_name@ has the following groups:

<p>

<if @view_by@ eq group_type>
    <b>
    by group type
    |
    <a href=@this_url@?view_by=rel_type>relationship to site</a>
    </b>

    <include src="elements-by-group-type" group_id=@subsite_group_id;noquote@>
</if>
<else>
    <b>
    by <a href=@this_url@?view_by=group_type>group type</a>
    |
    relationship to site
    </b>

    <include src="elements-by-rel-type" group_id=@subsite_group_id;noquote@>
</else>

To add a group, first select a group type above or go to the <a href=../group-types/>group type administration</a> page