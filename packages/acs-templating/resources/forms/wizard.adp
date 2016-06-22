<!-- Dark blue frame -->
<table bgcolor="#6699CC" cellspacing="0" cellpadding="4" border="0">
<tr><td>

<!-- Light blue pad -->
<table bgcolor="#99CCFF" cellspacing="0" cellpadding="6" border="0" width="100%">
<tr><td>

<table bgcolor="#99CCFF" cellspacing="0" cellpadding="2" border="0" width="100%">

  <multiple name=elements>
  
    <if @elements.section@ not nil>
      <tr><td colspan="2" bgcolor="#eeeeee"><strong>@elements.section;noquote@</strong></td></tr>
    </if>

    <group column="section">

    <if @elements.widget@ eq "hidden"> 
        <noparse><formwidget id=@elements.id@></noparse>
    </if>

    <else>
      <if @elements.widget@ in "submit" "button">
        <!-- put it at the bottom -->
      </if>
      <else>
        <!-- If the widget is wide, display it in its own section -->
        <if @elements.wide@ not nil>
          <tr><td colspan="2" bgcolor="#eeeeee"><strong>@elements.label;noquote@</strong></td></tr>
          <tr><td colspan="2">
        </if>
        <else>
          <tr><td><strong>@elements.label@</strong>&nbsp;&nbsp;
          <if @elements.help_text@ not nil>
            <br>&nbsp;&nbsp;
            <font size=-1><noparse><formhelp id=@elements.id;noquote@></noparse></font><br>
          </if></td>
        </else>

          <if @elements.widget@ eq radio or @elements.widget@ eq checkbox>
            <if @elements.wide@ not nil>
              <if @elements.help_text@ not nil>
                &nbsp;&nbsp;
                <font size=-1><noparse><formhelp id=@elements.id;noquote@></noparse></font><br>
              </if>
            </if><else><td></else>
              <noparse>
		<table cellpadding="4" cellspacing="0" border="0">

		<formgroup id="@elements.id@" cols="4">
		  <if \@formgroup.col@ eq 1><tr></if>

		  <if \@formgroup.rownum@ le \@formgroup:rowcount@>
		    <td align="right">&nbsp;\@formgroup.widget;noquote@</td>      
		    <td align="left"><label for="@elements.form_id@:elements:@elements.id@:\@formgroup.option@">\@formgroup.label@</label></td> 
		  </if><else><td>&nbsp;</td><td>&nbsp;</td></else>

		<if \@formgroup.col@ eq 4></tr></if>

		</formgroup>

		</table>
		<formerror id=@elements.id;noquote@><br>
		  <font color="red"><strong>\@formerror.@elements.id@;noquote\@</strong></font>
		</formerror>
              </noparse>
	    </td>
	  </if>
	  <else> 
	    <if @elements.widget@ eq inform>
	      <if @elements.wide@ not nil>
                <noparse>
                  <formerror  id=@elements.id;noquote@><br>
                    <font color="red"><strong>\@formerror.@elements.id@;noquote\@</strong></font><br>
                  </formerror>
                </noparse>
              </if><else><td bgcolor="#EEEEEE"></else>
		<noparse><formwidget id="@elements.id;noquote@"></noparse>
	      </td>
	    </if>
	    <else>
	      <if @elements.wide@ not nil></if><else><td nowrap></else>
		<noparse><formwidget id="@elements.id@">
		<formerror id="@elements.id@"><br><font 
		   color="red"><strong>\@formerror.@elements.id@;noquote\@<strong></font>
                </formerror></noparse>
	      </td>
	    </else>
	  </else>
      </tr>
      </else>
    </else>

    </group>

  </multiple>

</td></tr>

<tr>
  <td align="right" colspan="2">
    <multiple name="elements">
      <if @elements.widget@ in "submit" "button">
        <noparse><formwidget id=@elements.id;noquote@></noparse>
      </if>
    </multiple>
  </td>
</tr>
 
</table>

<!-- Light blue pad -->
</td></tr>
</table>

<!-- Dark blue frame -->
</td></tr>
</table>


