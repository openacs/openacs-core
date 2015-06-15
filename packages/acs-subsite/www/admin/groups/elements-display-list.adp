<if @admin_p@ eq 1>
<if @ancestor_rel_type@ eq membership_rel>
    <multiple name="possible_member_states">

        <if @possible_member_states.rownum@ gt 1>
            &nbsp;|&nbsp;
        </if>

        <if @member_state@ ne @possible_member_states.val@>
            <a href="@possible_member_states.url@">@possible_member_states.label@</a>
        </if><else>
            <b>@possible_member_states.label@</b>
        </else>

    </multiple>
</if>
</if>

<if @rels:rowcount@ eq 0>
<ul>
  <li>(none)</li>
</ul>
</if>
<else>
<ol>
 <multiple name="rels">
  <li> <a href="../relations/one?rel_id=@rels.rel_id@">@rels.element_name@</a>
  <if @delete_p@ eq 1>
    (<a href="../relations/remove?rel_id=@rels.rel_id@&amp;return_url=@return_url_enc@">remove</a>)
  </if>
  </li>
 </multiple>
</ol>
</else>
