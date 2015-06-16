<!-- Start Tab bar -->
<table border="0" cellspacing="0" cellpadding="0">
  <tr>
    <td>&nbsp;</td>
      <multiple name="tabs">
        <if @tabs.key@ eq @tab@>
          <td class="tab_selected">&nbsp;@tabs.name@&nbsp;</td>
        </if>
        <else>
          <td>&nbsp;<a href="@tabs.url@">@tabs.name@</a>&nbsp;</td>
        </else>
      </multiple>
    <td width="100%">&nbsp;</td>
  </tr>
  <tr style="background: #333366;">
    <td colspan="<%=[expr {${tabs:rowcount}+2}]%>">
      <table border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td height="5">
          </td>
        </tr>
      </table>
    </td>
  </tr>
</table>
<!-- End Tab bar -->
