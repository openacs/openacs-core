<html>
  <head>
  <style>
    h1 { font-family: Arial, Helvetica }
    th { font-family: Arial, Helvetica }
    td { font-family: Arial, Helvetica }
  </style>
  </head>
  <body bgcolor="#FFFFCC">
  <h1>Customize a Sandwich</h1>
<hr>

  <formtemplate id="sandwich">

    <formwidget id="grid">

    <table border=0 >
      <tr><td>
        <table bgcolor=#99CCFF cellpadding=4 cellspacing=0 border=1 >
          <tr>
            <td><b>Sandwich Name</b>&nbsp;&nbsp;</td>
	    <td><formwidget id=nickname>
                <if @formerror.nickname@ not nil><br><font color="red"><b>@formerror.nickname@<b></font></if>
            </td>

          </tr>
          <tr>
	    <td><b>Protein</b>&nbsp;&nbsp;</td>
	    <td>
	      <table cellpadding=4 cellspacing=0 border=0>
                <formgroup id=protein cols=2>
                  <if @formgroup.col@ eq "1">
                    <tr>
                  </if>
                  <td>
                    <if @formgroup.rownum@ le @formgroup:rowcount@>
                      @formgroup.widget@ @formgroup.label@
                    </if>
                    <else>
                      &nbsp;
                    </else>
                  </td>
                  <if @formgroup.col@ eq "2">
                    </tr>
                  </if>
                </formgroup> 
	      </table>
              <if @formerror.protein@ not nil><br><font color="red"><b>@formerror.protein@<b></font></if>
	    </td>
	  </tr>
	  <tr>
	    <td><b>Vitamins</b>&nbsp;&nbsp;</td>
	    <td> 
	      <table cellpadding=4 cellspacing=0 border=0>
               <formgroup id=vitamins cols=2>
                  <if @formgroup.col@ eq "1">
                    <tr>
                  </if>
                  <td>
                    <if @formgroup.rownum@ le @formgroup:rowcount@>
                      @formgroup.widget@ @formgroup.label@
                    </if>
                    <else>
                      &nbsp;
                    </else>
                  </td>
                  <if @formgroup.col@ eq "2">
                   </tr>
                  </if>
                </formgroup> 
	      </table>
              <if @formerror.vitamins@ not nil><br><font color="red"><b>@formerror.vitamins@<b></font></if>
            </td>
          </tr>
        </table>
      </td></tr>
      <tr>
        <td align=center><br><input type=submit value=Submit></td>
      </tr>
    </table>

  </formtemplate>
<hr>
</body>
</html>