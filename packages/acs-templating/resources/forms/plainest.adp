<table bgcolor="#FFFFFF" cellspacing="0" cellpadding="6" border="0">
<tr><td>

<!-- Form elements -->
<table bgcolor="#FFFFFF" cellspacing="0" cellpadding="2" border="0" width="100%">

  <multiple name=elements>

    <if @elements.section@ not nil>
      <tr><td colspan="2">@elements.section@</td></tr>
    </if>

    <group column="section">

    <if @elements.widget@ eq "hidden"> 
        <noparse><formwidget id=@elements.id@></noparse>
    </if>

    <else>
      <if @elements.widget@ eq "submit">
        <tr><td align="center" colspan="2">
          <noparse><formwidget id=@elements.id@></noparse>
        </td></tr>
      </if>
      <else>
       <tr>
        <if @elements.label@ not nil>
	<td>@elements.label@&nbsp;&nbsp;
          <if @elements.help_text@ not nil>
            <br />&nbsp;&nbsp;
            <span style="font-size: 90%"><noparse><formhelp id=@elements.id@></noparse></span><br />
          </if>
	  </td>
        </if>
	<if @elements.widget@ in radio checkbox>
            <if @elements.label@ nil><td colspan="2"></if>
	    <else><td></else>
	    <noparse>
            <table cellpadding="4" cellspacing="0" border="0">
	      <formgroup id=@elements.id@>
		<tr><td>\@formgroup.widget@</td>
                    <td>\@formgroup.label@</td></tr>
	      </formgroup>
	      </table>
	      <formerror id=@elements.id@><br>
                <span style="color: Red; font-weight: bold">\@formerror.@elements.id@\@</span>
              </formerror>
            </noparse>
	    </td>	    
	</if>
	<else> 
	    <if @elements.widget@ eq inform>
              <if @elements.label@ nil><td style="background: #EEEEEE" colspan="2"></if>
	      <else><td style="background: #EEEEEE"></else>
		<noparse><formwidget id=@elements.id@></noparse>
	      </td>
	    </if>
	    <else>
              <if @elements.label@ nil><td nowrap="nowrap" colspan="2"></if>
                <else><td nowrap="nowrap"></else>
		<noparse><formwidget id=@elements.id@>
		<formerror id=@elements.id@><br />
                 <span style="font-weight: bold; color: red">\@formerror.@elements.id@\@</span>
                </formerror></noparse>
	      </td>
	    </else>
	</else>
       </tr>
      </else>
    </else>

    </group>

  </multiple>

  </table>

</td></tr>

<if @form_properties.has_submit@ nil>
  <tr>
    <td align="center"><br /><input type="submit" value="Submit" /></td>
  </tr>
</if>

</table>
