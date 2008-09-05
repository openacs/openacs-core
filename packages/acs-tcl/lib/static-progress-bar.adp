<if @total@ gt 1>
<table width="100%" border="0" cellpadding="2" cellspacing="3">
  <tr style="color: @header_color@; font-weight: bold;">
    <td>#acs-tcl.Percentage_complete#</td>
    <td align="right">#acs-tcl.Page_current_of_total#</td>
  </tr>
  <tr>
    <td colspan="2" style="background-color:@bgcolor@">
      <table width="100%" border="0" cellpadding="0" cellspacing="0" style="border: 1px solid white;">
        <tr>
        <if @percentage_done@ gt 0>
          <td style="background-color:@bgcolor@; width:@percentage_done@%" align="right"><span style="font-weight: bold; color: @fontcolor@;">@percentage_done@ %</span>&nbsp;</td>
          <td style="background-color:white; width:100%"> </td>
        </if>
        <else>
          <td style="background-color:white" colspan="2">&nbsp;<span style="font-weight: bold;">0 %</span></td>
        </else>
        </tr>
      </table>
    </td> 
  </tr>
</table>
<br>
</if>
