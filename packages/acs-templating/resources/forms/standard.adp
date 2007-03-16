<multiple name=elements>
	<if @elements.section@ not nil>
		<fieldset id="@elements.section@" @elements.sec_fieldset;noquote@><!-- section fieldset -->
        <legend @elements.sec_legend;noquote@>@elements.sec_legendtext@</legend>
	</if>
	
	<group column="section">
		<if @elements.widget@ eq "hidden"> 
			<noparse><formwidget id=@elements.id@></noparse>
		</if>
  
		<else>
			<if @elements.widget@ eq "submit"><!-- if form submit button wrap it in the form-button class -->
  				<div class="form-button">
        			<group column="widget">
             				<noparse><formwidget id="@elements.id@"></noparse>
           			</group>
  				</div>
       			</if>
        
			<else> <!-- wrap the form item in the form-item-wrapper class -->
				<div class="form-item-wrapper">
					<if @elements.widget@ in radio checkbox> <!-- radio button groups and checkbox groups get their own fieldsets -->
						<fieldset @elements.fieldset;noquote@>
				          <legend @elements.legend;noquote@>@elements.legendtext@</legend>
				    </if>
					<if @elements.label@ not nil>
						<noparse>
							<if \@formerror.@elements.id@\@ not nil>
								<div class="form-label form-label-error">
                                  <if @elements.widget@ in radio checkbox date>
									@elements.label;noquote@
                                  </if>
                                  <else>
									<label for="@elements.id@">@elements.label;noquote@</label>
                                  </else>
							</if>
							<else>
								<div class="form-label">
                                  <if @elements.widget@ in radio checkbox date>
									@elements.label;noquote@
                                  </if>
                                  <else>
									<label for="@elements.id@">@elements.label;noquote@</label>
                                  </else>
							</else>
						</noparse>

						<if @form_properties.show_required_p@ true>
							<if @elements.optional@ nil and @elements.mode@ ne "display" and @elements.widget@ ne "inform">
								<div class="form-required-mark">
								(#acs-templating.required#)
								</div>
							</if>
						</if>

								</div> <!-- /form-label or /form-error -->
					</if>
					<else>
						<noparse>
						<if \@formerror.@elements.id@\@ not nil>
							<div class="form-error">
						</if>
						<else>
							<div class="form-label">
						</else>
						</noparse>
						<if @elements.optional@ nil and @elements.mode@ ne "display" and @elements.widget@ ne "inform">
							<div class="form-required-mark">
								#acs-templating.required#
							</div>
						</if>

								</div><!-- /form-label or /form-error -->
					</else>

					<noparse>
					<if \@formerror.@elements.id@\@ not nil>
						<div class="form-widget form-widget-error">
					</if>
					
					<else>
						<div class="form-widget">
					</else>
					</noparse>
	
					<if @elements.widget@ in radio checkbox>
						<noparse>
							<formgroup id="@elements.id@">			
									\@formgroup.widget;noquote@
								<label for="@elements.form_id@:elements:@elements.id@:\@formgroup.option@">
										\@formgroup.label;noquote@
								</label><br/>
							</formgroup>
						</noparse>
					</if>

					<else>
						<noparse>
						<formwidget id="@elements.id@">
						</noparse>
              				</else>							
							
						</div> <!-- /form-widget -->
						
					<noparse>
					<formerror id="@elements.id@">
						<div class="form-error">
							\@formerror.@elements.id@;noquote\@
						</div> <!-- /form-error -->
					</formerror>
					</noparse>

					<if @elements.help_text@ not nil>
						<div class="form-help-text">
							<img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0">
							<noparse><formhelp id="@elements.id@"></noparse>
						</div> <!-- /form-help-text -->
					</if>

					<if @elements.widget@ in radio checkbox> <!-- radio button groups and checkbox groups get their own fieldsets -->
						</fieldset>
				    </if>
				</div>
       		</else>
	</else>
</group>

<if @elements.section@ not nil>
	</fieldset> <!-- section fieldset -->
</if>
</multiple>
