<!-- Form elements -->
  <multiple name=elements>

    <if @elements.section@ not nil>
      <span class="form-section">@elements.section@</span>
    </if>

    <group column="section">
      <if @elements.widget@ eq "hidden"> 
        <noparse><div><formwidget id=@elements.id@></div></noparse>
      </if>
  
      <else>

        <if @elements.widget@ eq "submit">
            <span class="form-element">
              <group column="widget">
                <noparse><formwidget id="@elements.id@"></noparse>
              </group>
                </span>
        </if>

        <else>
            <if @elements.label@ not nil>
              <noparse>
                <if \@formerror.@elements.id@\@ not nil>
                  <span class="form-label-error">
                  </if>
                <else>
                  <span class="form-label">
                  </else>
              </noparse>
                    @elements.label;noquote@
                <if @form_properties.show_required_p;literal@ true>
                <if @elements.optional@ nil and @elements.mode@ ne "display" and @elements.widget@ ne "inform" and @elements.widget@ ne "select"><span class="form-required-mark">*</span></if>
                </if>
              </span>
            </if>
            <else>
              <span class="form-label">
                &nbsp;
              </span>
            </else>
              <noparse>
                <if \@formerror.@elements.id@\@ not nil>
                  <span class="form-widget-error">
              </if>
                <else>
                  <span class="form-widget">                  
                </else>
              </noparse>

              <if @elements.widget@ in radio checkbox>
                <noparse>
                    <formgroup id="@elements.id@">
                        \@formgroup.widget;noquote@
                          <font face="tahoma,verdana,arial,helvetica,sans-serif">
                            <label for="@elements.form_id@:elements:@elements.id@:\@formgroup.option@">
                              \@formgroup.label@
                            </label>
                          </font>

                      </tr>
                    </formgroup>
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

        </else>
      </else>
    </group>
  </multiple>
 
