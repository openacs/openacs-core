<table bgcolor="#CACACA" width="70%" border="0" cellspacing="0" cellpadding="0">
  <tr width="100%">
    <td width="100%">
      <table width="100%" border="0" cellspacing="1" cellpadding="1" bgcolor="#000000">

        <multiple name=elements>

          <if @elements.section@ not nil>
            <tr bgcolor="#5F6090">
              <td colspan="3" align="center" class="textstyle1">
                <font face="Verdana, Arial, Helvetica, sans-serif" size="2" color="#FFFFCC">
                  <strong>@elements.section@</font></strong>
                </font>
              </td>
            </tr>
          </if>

          <group column="section">

            <if @elements.widget@ eq "hidden"> 
              <noparse><formwidget id=@elements.id@></noparse>
            </if>

            <else>
              <if @elements.widget@ eq "submit">
               <tr bgcolor="#5F6090">
                 <td align="center" colspan="3">
                   <group column="widget">
                     <noparse><formwidget id=@elements.id@></noparse>
                   </group>
                 </td>
               </tr>
              </if>
              <else>
                <tr bgcolor="#5F6090">
                  <if @elements.label@ not nil>
  	            <td width="40%" align="right" valign="middle" class="textstyle1">
                      @elements.label;noquote@
                      <if @elements.help_text@ not nil>
                        <br>&nbsp;&nbsp;
                        <span style="font-size: 90%"><noparse><formhelp id=@elements.id@></noparse></span><br>
                      </if>
  	            </td>
                  </if>
                  <if @elements.widget@ eq radio or @elements.widget@ eq checkbox>
                     <if @elements.label@ nil><td colspan="3" align="center" class="textstyle1"></if>
  	             <else>
                       <td width="2%" align="center" valign="middle" class="textstyle1">: </td> 
                       <td width="40%" align="left" valign="middle" class="textstyle1">
                     </else>
  	             <noparse>
                       <table cellpadding="4" cellspacing="0" border="0">
  	                 <formgroup id=@elements.id@>
  		           <tr bgcolor="#5F6090">
                             <td>\@formgroup.widget@</td>
                             <td class="textstyls1"><label for="@elements.form_id@:elements:@elements.id@:\@formgroup.option@">\@formgroup.label@</label></td>
                           </tr>
  	                 </formgroup>
  	               </table>
  	               <formerror id=@elements.id@><br>
                         <span style="color: Red; font-weight: bold">\@formerror.@elements.id@;noquote\@</span>
                       </formerror>
                     </noparse>
  	             </td>	    
  	          </if>
  	          <else> 
  	            <if @elements.widget@ eq inform>
                      <if @elements.label@ nil>
  	                <td colspan="3" align="center" class="textstyle1">
                      </if>
                      <else>
                        <td width="2%" align="center" valign="middle" class="textstyle1">: </td> 
  	                <td width="40%" class="textstyle1" align="center">
                      </else>
                      <font face="Verdana, Arial, Helvetica, sans-serif" size="2" color="#FFFFCC">
  		        <strong><noparse><formwidget id=@elements.id@></noparse><strong>
                      </font>
  	              </td>
  	            </if>
  	            <else>
                      <if @elements.label@ nil><td nowrap="nowrap" colspan="3" align="center" class="textstyle1"></if>
                      <else>
                        <td width="2%" align="center" valign="middle" class="textstyle1">: </td> 
                        <td bgcolor="#5F6090" width="40%" class="textstyle1" nowrap="nowrap">
                      </else>
  		      <noparse><formwidget id=@elements.id@>
  		        <formerror id=@elements.id@><br>
                          <span style="font-weight: bold; color: red">\@formerror.@elements.id@;noquote\@</span>
                        </formerror>
                      </noparse>
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
</table>

