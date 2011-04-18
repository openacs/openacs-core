<master>
<property name="doc(title)">@doc.title@</property>
<property name="context">@context;noquote@</property>

<h1>@doc.title@</h1>

<p>@intro_text@</p>

<if @view_by@ eq group_type>
    <strong>
    #acs-subsite.by_group_type#
    |
    <a href="@this_url@?view_by=rel_type">#acs-subsite.relationship_to_site#</a>
    </strong>

    <include src="elements-by-group-type" group_id=@subsite_group_id;noquote@>
</if>
<else>
    <strong>
    <a href="@this_url@?view_by=group_type">#acs-subsite.by_group_type#</a>
    |
    #acs-subsite.relationship_to_site#
    </strong>

    <include src="elements-by-rel-type" group_id=@subsite_group_id;noquote@>
</else>

<p>#acs-subsite.To_add_a_group_first_select_a_group_type_above_or_go_to_the#</p>
