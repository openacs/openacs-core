<table bgcolor=#6699CC cellspacing=0 cellpadding=4 border=0 width="95%">
<tr bgcolor="#FFFFFF">
  <td align=left><b>@form_properties.title@</b></td>
  <td align=right>&nbsp;</td>
</tr>

<if @elements:rowcount@ le 0>
  <tr><td colspan=2><i>No items</i></td></tr>
</if>
<else>

<tr>
<td colspan=2>

<table bgcolor=#99CCFF cellspacing=0 cellpadding=2 border=0 width="100%">
  <tr bgcolor="#99CCFF">
    <% set list_tag $form_properties(headers) %>
    <list name=list_tag>
      <th align=left>@list_tag:item@</th>
    </list>
  </tr>
  
<grid name=elements cols="@form_properties.cols@" orientation=horizontal>

  <if @elements.rownum@ le @elements:rowcount@>

    <if @elements.col@ eq 1>
      <if @elements.row@ odd><tr bgcolor=#ffffff></if>
      <else><tr bgcolor=#dddddd></else>
    </if>

   <if @elements.widget@ not in "hidden" "submit"> 
      <td nowrap>     

        <if @elements.widget@ in radio checkbox>
          <table cellpadding=4 cellspacing=0 border=0>
            <tr>
            ~formgroup id=@elements.id@>
              <td>+formgroup.widget+</td><td>+formgroup.label+</td>
            </formgroup>
            </tr>
          </table>
          ~formerror id=@elements.id@><br><font color="red"><b>+formerror.@elements.id@+<b></font>~/formerror>
        </if>
          
        <else>         
          <if @elements.widget@ eq inform>
            ~formwidget id=@elements.id@>
          </if>
          <else>
            ~formwidget id=@elements.id@>
            ~formerror id=@elements.id@><br><font color="red"><b>
                +formerror.@elements.id@+<b></font>~/formerror>
          </else>
        </else>

      </td>
      </if>
    </if>
    <else>
    </else>

    <if @elements.col@ eq @form_properties.cols@>
      </tr>
    </if>

</grid>

</table>

<if @form_properties.has_submit@ nil>
  <tr bgcolor="#FFFFFF">
    <td align=right colspan=2><input type=submit value=Submit></td>
  </tr>
</if>
<else>
  <multiple name=elements>
    <if @elements.widget@ eq "submit">
      <tr bgcolor="#FFFFFF">
        <td align=right colspan=2><input type=submit name=@elements.id@ value="@elements.label@"></td>
      </tr>  
    </if>
  </multiple>
</else>

</else>

</td></tr>
</table>

<multiple name=elements>
  <if @elements.widget@ eq "hidden">
     ~formwidget id=@elements.id@>
  </if>
</multiple> 





