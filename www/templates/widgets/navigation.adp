<multiple name="navigation">
<if @navigation.subdir_p@ eq 0>
  <if @navigation.chosen_p@ eq 1>
    <if @navigation.rownum@ gt 1>
      <td width="10%">&#8226;</td>
    </if>
    <td><span class="chosen">@navigation.item@</span></td>
  </if>
  <else>
    <if @navigation.rownum@ gt 1>
      <td width="10%">&#8226;</td>
    </if>
    <td><a href="@navigation.url@">@navigation.item@</a></td>
  </else>
</if>
<else>
  <if @navigation.rownum@ eq 1>
    <td>SYNTAX ERROR IN NAVIGATION CODE</td>
  </if>
</else>
</multiple>