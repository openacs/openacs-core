<table cellspacing="2" cellpadding="2" border="0">
  <multiple name=elements>

    <if @elements.section@ not nil>
      <tr class="form-section"><th colspan="2">@elements.section@</th></tr>
    </if>

    <group column="section">
      <if @elements.widget@ eq "hidden"> 
        <noparse><formwidget id=@elements.id@></noparse>
      </if>
  
      <else>

        <if @elements.widget@ eq "submit">
          <tr class="form-element">
            <td align="left" colspan="2">
              <group column="widget">
                <noparse><formwidget id="@elements.id@"></noparse>
              </group>
            </td>
          </tr>
        </if>
        <else>
          <tr class="form-element">

            <if @elements.label@ not nil>
              <noparse>
                <if \@formerror.@elements.id@\@ not nil>
                  <td class="form-label-error">
                </if>
                <else>
                  <td class="form-label">
                </else>
              </noparse>
                @elements.label;noquote@
                <if @form_properties.show_required_p@ true>
                  <if @elements.optional@ nil and @elements.mode@ ne "display" and @elements.widget@ ne "inform" and @elements.widget@ ne "select"><span class="form-required-mark">*</span></if>
                </if>
               </td>
            </if>
            <else>
              <td class="form-label">
                &nbsp;
              </td>
            </else>

              <noparse>
                <if \@formerror.@elements.id@\@ not nil>
                  <td class="form-widget-error">
                </if>
                <else>
                  <td class="form-widget">
                </else>
              </noparse>

              <if @elements.widget@ in radio checkbox>
                <noparse>
                  <table cellpadding="4" cellspacing="0" border="0">
                    <formgroup id="@elements.id@">
                      <tr>
                        <td>\@formgroup.widget;noquote@</td>
                        <td class="form-widget">
                          <label for="@elements.form_id@:elements:@elements.id@:\@formgroup.option@">
                            \@formgroup.label;noquote@
                          </label>
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
                  <div class="form-error">
                    \@formerror.@elements.id@;noquote\@
                  </div>
                </formerror>
              </noparse>

              <if @elements.help_text@ not nil and @elements.mode@ ne "display">
                <div class="form-help-text">
                  <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0">
                  <noparse><formhelp id="@elements.id@"></noparse>
                </div>
              </if>

            </td>
          </tr>

        </else>
      </else>
    </group>
  </multiple>

</table>

<multiple name="elements">
  <if @form_properties.show_required_p@ true>
    <if @elements.optional@ nil and @elements.mode@ ne "display" and @elements.widget@ ne "inform" and @elements.widget@ ne "select" and @elements.widget@ ne "hidden" and @elements.widget@ ne "submit">
       <span class="form-required-mark">*</span> #acs-templating.required# <% break %>
    </if>
  </if>
</multiple>

