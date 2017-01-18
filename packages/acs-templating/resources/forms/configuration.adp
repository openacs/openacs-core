        <ul>
  <multiple name="elements">
    <if @elements.section@ not nil>
      <li><a href="#@elements.section@">@elements.section@</a></li>
    </if>
    <group column="section">
      <if @elements.widget@ eq "hidden"> 
        <noparse><formwidget id=@elements.id@></noparse>
      </if>
    </group>
  </multiple>
</ul>

<table cellpacing="2" cellpadding="2" border="0">
  <multiple name="elements">

    <if @elements.section@ not nil>
      <tr>
        <td colspan="2">
          <a name="@elements.section@"><strong>@elements.section@</strong></a>
          <hr>
        </td>
      </tr>
    </if>

    <group column="section">

      <if @elements.widget@ eq "hidden">
      </if>
      <else>
        <if @elements.widget@ eq "submit"> 
          <tr>
            <td colspan="2">
              <group column="widget">
                <noparse><formwidget id=@elements.id@></noparse>
              </group>
            </td>
          </tr>
        </if>
        <else>
          <tr>
            <td width="40%">
              <if @elements.help_text@ not nil>
                <span class="form-configuration-help-text">@elements.help_text@</span>
              </if>
            </td>
            <td width="60%">
              <if @elements.label@ not nil>
                <span class="form-configuration-label">@elements.label;noquote@:</span>
                <br>
              </if>
              <if @form_properties.show_required_p;literal@ true>
                <if @elements.optional@ nil and @elements.mode@ ne "display" and @elements.widget@ ne "inform" and @elements.widget@ ne "select"><font color="red">*</font></if>
              </if>

              <if @elements.widget@ eq radio or @elements.widget@ eq checkbox>
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
                <noparse>
                  <formwidget id="@elements.id@">
                </noparse>
              </else>
              <noparse>
                <formerror id="@elements.id@">
                  <br>
                  \@formerror.@elements.id@\@
                </formerror>
              </noparse>
            </td>
          </tr>
        </else>
        <tr>
          <td colspan="2">
            <hr>
          </td>
        </tr>
      </else>
    </group>
  </multiple>
</table>
