<master>
<property name="title">@title@</property>
<property name="context">@context@</property>


<formtemplate id="grant">
<formwidget id="object_id">
<formwidget id="application_url">
<table>
  <tr valign="center">
    <td>Grant: </td>

    <td>&nbsp;</td>

    <td>

      <table border="0">
        @first_tr;noquote@
        <multiple name="mu_privileges">
        <tr>
          <td colspan="@mu_privileges.level@">&nbsp;&nbsp;&nbsp;</td>
          <td colspan="@mu_privileges.inverted_level@">
            <input type="checkbox" name="privileges" id="@mu_privileges.id@" value="@mu_privileges.privilege@" @mu_privileges.selected@>
            <if @mu_privileges.standard_priv_p@ true>
            <em><label for="@mu_privileges.id@">@mu_privileges.privilege@</label></em>
            </if>
            <else>
            <label for="@mu_privileges.id@">@mu_privileges.privilege@</label>
            </else>
          </td>
        </tr>
        </multiple>
      </table>

    </td>

    <td>&nbsp;</td>

    <td>on @name@ to:</td>

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

<i>Notes:</i>
<br>
<i>Privileges higher in the hierarchy imply all the privileges below, e.g. when you grant admin, then read, write etc. are implied automatically.</i>
<br>
<i>When you leave a checkbox empty here then that privilege will be revoked from the party you choose in case it has been granted to that party before.</i>
