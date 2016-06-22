<!-- Form elements -->
<table cellspacing="2" cellpadding="2" border="0">
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
          <tr>
            <td align="center" colspan="2">
              <group column="widget">
                <noparse>
                  <formwidget id="@elements.id@">
                </noparse>
              </group>
            </td>
          </tr>
        </if>

        <else>
          <tr>

            <if @elements.label@ not nil>
              <noparse>
                <if \@formerror.@elements.id@\@ not nil>
                  <td bgcolor="#ffaaaa">
                </if>
                <else>
                  <td bgcolor="#ddddff">
                </else>
              </noparse>
                <strong>
                  <font face="tahoma,verdana,arial,helvetica,sans-serif">
                    @elements.label;noquote@
                  </font>
                </strong>
                &nbsp;&nbsp;
              </td>
            </if>
            <else>
              <td bgcolor="#ddddff">
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

              <if @elements.widget@ eq radio or @elements.widget@ eq checkbox>
                <noparse>
                  <table cellpadding="4" cellspacing="0" border="0">
                    <formgroup id="@elements.id@">
                      <tr>
                        <td>\@formgroup.widget;noquote@</td>
                        <td>
                          <font face="tahoma,verdana,arial,helvetica,sans-serif">
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
                <font face="tahoma,verdana,arial,helvetica,sans-serif">
                  <noparse>
                    <formwidget id="@elements.id@">
                  </noparse>
                </font>
              </else>

              <noparse>
                <formerror id="@elements.id@">
                  <br>
                  <font face="tahoma,verdana,arial,helvetica,sans-serif" color="red">
                    <strong>\@formerror.@elements.id@;noquote\@<strong>
                  </font>
                </formerror>
              </noparse>

              <if @elements.help_text@ not nil>
                <p style="margin-top: 4px; margin-bottom: 2px;">
                  <font face="tahoma,verdana,arial,helvetica,sans-serif">
                    <noparse>
                      <em><formhelp id="@elements.id@"></em>
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
