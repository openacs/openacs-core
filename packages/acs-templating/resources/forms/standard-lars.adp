
<!-- Dark blue frame -->
<table bgcolor=white cellspacing="1" cellpadding="0" border="0">
  <tr>
    <td>

      <table bgcolor=white cellspacing=0 cellpadding=6 border=0 width="100%">
        <tr>
          <td>

            <!-- Form elements -->
            <table cellspacing=2 cellpadding=2 border=0 width="100%">

  <multiple name=elements>

    <if @elements.section@ not nil>
      <tr bgcolor=white><td colspan=2 bgcolor=#eeeeee><b>@elements.section@</b></td></tr>
    </if>

    <group column="section">

    <if @elements.widget@ eq "hidden"> 
        <noparse><formwidget id=@elements.id@></noparse>
    </if>

    <else>
      <if @elements.widget@ eq "submit">
        <tr bgcolor=white><td align=center colspan=2>
          <noparse><formwidget id=@elements.id@></noparse>
        </td></tr>
      </if>
      <else>
       <tr bgcolor=white>
        <if @elements.label@ not nil>
	<td bgcolor="#ddddff" width="120"><b><font face="tahoma,verdana,arial,helvetica,sans-serif" size="-1">@elements.label@</font></b>&nbsp;&nbsp;
	  </td>
        </if>
	<if @elements.widget@ in radio checkbox>
            <if @elements.label@ nil><td colspan=2>></if>
	    <else><td></else>
	    <noparse>
            <table cellpadding=4 cellspacing=0 border=0>
	      <formgroup id=@elements.id@>
		<tr>
                  <td>\@formgroup.widget@</td>
                  <td>
                    <font face="tahoma,verdana,arial,helvetica,sans-serif" size="-1"><label for="@elements.form_id@:elements:@elements.id@:\@formgroup.option@">\@formgroup.label@</label></font>
                  </td>
                </tr>
	      </formgroup>
	      </table>
	      <formerror id=@elements.id@><br>
                <font face="tahoma,verdana,arial,helvetica,sans-serif" color="red"><b>\@formerror.@elements.id@\@</b></font>
              </formerror>
            </noparse>
            <if @elements.help_text@ not nil>
              <p>
                <font face="tahoma,verdana,arial,helvetica,sans-serif" size="-1">
                  <noparse>
                    <i><formhelp id=@elements.id@></i>
                  </noparse>
                </font>
              </p>
            </if>
	    </td>	    
	</if>
	<else> 
	    <if @elements.widget@ eq inform>
	      <td><font face="tahoma,verdana,arial,helvetica,sans-serif" size="-1">
		<noparse><formwidget id=@elements.id@></noparse>
	      </font></td>
	    </if>
	    <else>
              <if @elements.label@ nil><td colspan=2></if>
                <else><td></else>
		<noparse><font face="tahoma,verdana,arial,helvetica,sans-serif" size="-1"><formwidget id=@elements.id@></font>
		<formerror id=@elements.id@><br><font face="tahoma,verdana,arial,helvetica,sans-serif"
		   color="red"><b>\@formerror.@elements.id@\@<b></font>
                </formerror></noparse>
                <if @elements.help_text@ not nil>
                  <p>
                    <font face="tahoma,verdana,arial,helvetica,sans-serif" size="-1">
                      <noparse>
                        <i><formhelp id=@elements.id@></i>
                      </noparse>
                    </font>
                  </p>
                </if>
	      </td>
	    </else>
	</else>
       </tr>
      </else>
    </else>

    </group>

  </multiple>

</table>

          </td>
        </tr>

<if @form_properties.has_submit@ nil>
  <tr bgcolor=white>
    <td align=right>
      <input type=submit name="ok" value="     OK     ">
      <input type=submit name="cancel" value="Cancel">
    </td>
  </tr>
</if>

        <!-- End of light blue pad -->
      </table>

      <!-- Dark blue frame -->
    </td>
  </tr>
</table>
