<table cellspacing="1" cellpadding="0" border="0">
  <tr>
    <td>

      <table cellspacing="0" cellpadding="6" border="0" width="100%">
        <tr>
          <td>


<!-- Form elements -->
<table cellspacing="2" cellpadding="2" border="0" width="100%">
  <multiple name=elements>

    <if @elements.section@ not nil>
      <tr bgcolor="#ccccff"><th colspan="2">@elements.section@</th></tr>
    </if>

    <group column="section">
      <if @elements.widget@ eq "hidden"> 
        <noparse><formwidget id=@elements.id@></noparse>
      </if>
  
      <else>

        <if @elements.widget@ eq "submit">
          <tr bgcolor="white">
            <td align="center" colspan="2">
              <noparse>
                <formwidget id="@elements.id@">
              </noparse>
            </td>
          </tr>
        </if>

        <else>
          <tr bgcolor=white>

            <if @elements.label@ not nil>
              <noparse>
                <if \@formerror.@elements.id@\@ not nil>
                  <td bgcolor="#ffaaaa" width="120" align="right" style="padding-left: 4px; padding-right: 12px;">
                </if>
                <else>
                  <td bgcolor="#e0e0f9" width="120" align="right" style="padding-left: 4px; padding-right: 12px;">
                </else>
              </noparse>
                <font face="tahoma,verdana,arial,helvetica,sans-serif" size="-1">
                  @elements.label@
                  <if @form_properties.show_required_p@ true>
                    <if @elements.optional@ nil and @elements.mode@ ne "display" and @elements.widget@ ne "inform" and @elements.widget@ ne "select"><font color="red">*</font></if>
                  </if>
                </font>
              </td>
            </if>
            <else>
              <td bgcolor="#ddddff" width="120">
                &nbsp;
              </td>
            </else>

              <noparse>
                <if \@formerror.@elements.id@\@ not nil>
                  <td style="border: 1px dotted red;">
                </if>
                <else>
                  <td>
                </else>
              </noparse>

              <if @elements.widget@ in radio checkbox>
                <noparse>
                  <table cellpadding="4" cellspacing="0" border="0">
                    <formgroup id="@elements.id@">
                      <tr>
                        <td>\@formgroup.widget@</td>
                        <td>
                          <font face="tahoma,verdana,arial,helvetica,sans-serif" size="-1">
                            <label for="@elements.form_id@:elements:@elements.id@:\@formgroup.option@">
                              \@formgroup.label@
                            </label>
                          </font>
                        </td>
                      </tr>
                    </formgroup>
                  </table>
                </noparse>
              </if>

              <else>
                <font face="tahoma,verdana,arial,helvetica,sans-serif" size="-1">
                  <noparse>
                    <formwidget id="@elements.id@">
                  </noparse>
                </font>
              </else>

              <noparse>
                <formerror id="@elements.id@">
                  <br>
                  <span style="font-family: tahoma,verdana,arial,helvetica,sans-serif; color: red; font-size: 100%;">
                    \@formerror.@elements.id@\@
                  </span>
                </formerror>
              </noparse>

              <if @elements.help_text@ not nil>
                <p style="margin-top: 4px; margin-bottom: 2px; color: #666666; font-family: tahoma,verdana,arial,helvetica,sans-serif; font-size: 75%;">
                  <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0">
                  <noparse><formhelp id="@elements.id@"></noparse>
                </p>
              </if>

            </td>
          </tr>

        </else>
      </else>
    </group>
  </multiple>

</table>

          </td>
        </tr>

<if @buttons:rowcount@ gt 0>
  <tr>
    <td>
      <multiple name="buttons">
        <input type="submit" name="@buttons.name@" value="@buttons.label@">
      </multiple>
    </td>
  </tr>
</if>

      </table>

    </td>
  </tr>
</table>
