<table cellpadding="0" cellspacing="0" border="0" bgcolor="#999999" width="100%" height="0">
  <tr bgcolor="#999999">
    <td>
      <table cellpadding="0" cellspacing="0" border="0" bgcolor="#DDDDDD" width="100%">
        <tr align="center">
          <multiple name=elements>
            <if @elements.current@ eq 1><td bgcolor="#FFFFFF"></if>
            <else>
              <td bgcolor="#99CCFF">
              <table border="0" cellpadding="2" cellspacing="1" width="100%" 
                 bgcolor="#6699cc">
              <tr align="center" bgcolor="#99ccff"><td>
            </else>
              &nbsp;<font size="-1"><noparse><formwidget id="@elements.id@"></noparse></font>
              &nbsp;
            </td>
            <if @elements.current@ ne 1></tr></table></td></if>
          </multiple>
        </tr>    
       </table>
    </td>
  </tr>
</table> 

