<table bgcolor="#6699CC" cellspacing="0" cellpadding="4" border="0" width="95%">
<tr bgcolor="#FFFFFF">
  <td align="left"><strong>@form_properties.title@</strong></td>
  <td align="right">&nbsp;</td>
</tr>

<if @elements:rowcount@ le 0>
  <tr><td colspan="2"><em>No items</em></td></tr>
</if>
<else>

<tr>
<td colspan="2">

<table bgcolor="#99CCFF" cellspacing="0" cellpadding="2" border="0" width="100%">
  <tr bgcolor="#99CCFF">
    <% set list_tag $form_properties(headers) %>
    <list name="list_tag">
      <th align="left">@list_tag:item@</th>
    </list>
  </tr>
  
<grid name=elements cols="@form_properties.cols@" orientation=horizontal>

  <if @elements.rownum@ le @elements:rowcount@>

    <if @elements.col@ eq 1>
      <if @elements.row@ odd><tr bgcolor="#ffffff"></if>
      <else><tr bgcolor="#dddddd"></else>
    </if>

   <if @elements.widget@ not in "hidden" "submit"> 
      <td nowrap>     

        <if @elements.widget@ eq radio or @elements.widget@ eq checkbox>
          <table cellpadding="4" cellspacing="0" border="0">
            <tr>
              <noparse>
                <formgroup id="@elements.id@">
                  <td>\@formgroup.widget;noquote\@</td><td><label for="@elements.form_id@:elements:@elements.id@:\@formgroup.option\@">\@formgroup.label\@</label></td>
                </formgroup>
              </noparse>
            </tr>
          </table>
          <noparse><formerror id="@elements.id@"><br><font color="red"><strong>\@formerror.@elements.id@\@<strong></font></formerror></noparse>
        </if>
          
        <else>         
          <if @elements.widget@ eq inform>
            <noparse><formwidget id="@elements.id@"></noparse>
          </if>
          <else>
            <noparse>
              <formwidget id="@elements.id@">
              <formerror id="@elements.id@"><br><font color="red"><strong>
                \@formerror.@elements.id@\@<strong></font></formerror>
            </noparse>
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

<multiple name=elements>
  <if @elements.widget@ eq "submit">
    <tr bgcolor="#FFFFFF">
      <td align="right" colspan="2"><input type="submit" name="@elements.id@" value="@elements.label@"></td>
    </tr>  
  </if>
</multiple>

</else>

</td></tr>
</table>

<multiple name=elements>
  <if @elements.widget@ eq "hidden">
     <noparse><formwidget id="@elements.id@"></noparse>
  </if>
</multiple> 
