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
                  <td bgcolor="#ffaaaa" width="120">
                </if>
                <else>
                  <td bgcolor="#ddddff" width="120">
                </else>
              </noparse>
                <b>
                  <font face="tahoma,verdana,arial,helvetica,sans-serif" size="-1">
                    @elements.label@
                  </font>
                </b>
                &nbsp;&nbsp;
              </td>
            </if>
            <else>
              <td bgcolor="#ddddff" width="120">
                &nbsp;
              </td>
            </else>

              <noparse>
                <if \@formerror.@elements.id@\@ not nil>
                  <td style="border: 2px solid red;">
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
                  <font face="tahoma,verdana,arial,helvetica,sans-serif" color="red">
                    <b>\@formerror.@elements.id@\@<b>
                  </font>
                </formerror>
              </noparse>

              <if @elements.help_text@ not nil>
                <p style="margin-top: 4px; margin-bottom: 2px;">
                  <font face="tahoma,verdana,arial,helvetica,sans-serif" size="-1">
                    <noparse>
                      <i><formhelp id="@elements.id@"></i>
                    </noparse>
                  </font>
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
