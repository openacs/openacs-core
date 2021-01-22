<master>
<property name="doc(title)">@title;literal@</property>
<property name="context">@context;literal@</property>


<formtemplate id="grant">
<formwidget id="object_id">
<formwidget id="application_url">

<table>
  <tr valign="top">
    <td>#acs-subsite.Grant#: </td>

    <td>&nbsp;</td>

    <td>
      <formwidget id="privilege">
    </td>

    <td>&nbsp;</td>

    <td>#acs-subsite.on_name_to#</td>

    <td>&nbsp;</td>

    <td>
      <formwidget id="party_id"></formwidget>
      <if @formerror.party_id@ not nil>
      <br><formerror id="party_id"></formerror>
      </if>
    </td>

    <td>&nbsp;</td>

    <td>
      <input type="submit" value="OK">
    </td>

  </tr>

</table>

</formtemplate>

<p>

<p>

<em>#acs-subsite.Notes#</em>
<br>
<em>#acs-subsite.lt_Privileges_higher_implied#</em>
<br>
<em>#acs-subsite.When_leaving_checkbox_empty#</em>

