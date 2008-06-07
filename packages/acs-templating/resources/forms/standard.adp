<multiple name=elements>
	<if @elements.section@ not nil>
		<fieldset id="@elements.form_id@:@elements.section@" @elements.sec_fieldset;noquote@><!-- section fieldset -->
        <legend @elements.sec_legend;noquote@><span>@elements.sec_legendtext@</span></legend>
	</if>
	
	<group column="section">
      <if @elements.widget@ eq "hidden"> 
		<noparse><div><formwidget id=@elements.id@></div></noparse>
	  </if>
  
	  <else>
		<if @elements.widget@ eq "submit"><!-- if form submit button wrap it in the form-button class -->
  		 <div class="form-button">
           <group column="widget">
             <noparse><formwidget id="@elements.id@">&nbsp;</noparse>
           </group>
  		 </div>
       </if>
        
	   <else> <!-- wrap the form item in the form-item-wrapper class -->
	     <div class="form-item-wrapper">
           <noparse>
			 <formerror id="@elements.id@">
			   <div class="form-error">
				 \@formerror.@elements.id@;noquote\@
			   </div> <!-- /form-error -->
			 </formerror>
		   </noparse>

		   <if @elements.widget@ in radio checkbox> 
             <if @elements.legendtext@ defined>
			   <fieldset @elements.fieldset;noquote@>
                 <!-- radio button groups and checkbox groups get their own fieldsets -->
				 <legend @elements.legend;noquote@><span>@elements.legendtext@</span></legend>
             </if>
		   </if>
           <div class="form-label">
             <if @elements.label@ not nil>
			   <noparse>
                 <if @form_properties.mode@ eq display or @elements.widget@ in radio checkbox date inform>
                   <if \@formerror.@elements.id@\@ not nil>
				     <span class="form-label-error">@elements.label;noquote@</span>
                   </if>
                   <else>@elements.label;noquote@</else>
                 </if>
                 <else>
				   <label for="@elements.id@">
                     <if \@formerror.@elements.id@\@ not nil>
                       <span class="form-label-error">@elements.label;noquote@</span>
                     </if>
                     <else>@elements.label;noquote@</else>
                 </else>
			   </noparse>

			   <if @form_properties.show_required_p@ true>
			     <if @elements.optional@ nil and @elements.mode@ ne "display" and @elements.widget@ ne "inform">
				   <span class="form-required-mark">
				     (#acs-templating.required#)
				   </span>
				 </if>
			   </if>

               <if @form_properties.mode@ eq display or @elements.widget@ in radio checkbox date inform><!-- dummy --></if>
               <else></label></else>
		     </if>
		     <else>
		       <if @elements.optional@ nil and @elements.mode@ ne "display" and @elements.widget@ ne "inform">
			     <div class="form-required-mark">
			       #acs-templating.required#
			     </div>
			   </if>
		     </else>
           </div> <!-- /form-label -->

           <div class="form-widget">
	
		     <if @elements.widget@ in radio checkbox>
			   <noparse>
			     <formgroup id="@elements.id@">			
				   <label for="@elements.form_id@:elements:@elements.id@:\@formgroup.option@">
				     \@formgroup.widget;noquote@
					 \@formgroup.label;noquote@
				   </label><br>
				 </formgroup>
			   </noparse>
             </if>
			 <else>
			   <noparse>
			     <formwidget id="@elements.id@">
			   </noparse>
             </else>							
							
		   </div> <!-- /form-widget -->
						
           <if @elements.help_text@ not nil>
             <div class="form-help-text">
               <img src="/shared/images/info.gif" width="12" height="9" alt="Help" title="Help text" style="border:0">
                 <noparse><formhelp id="@elements.id@"></noparse>
             </div> <!-- /form-help-text -->
           </if>

		   <if @elements.widget@ in radio checkbox> 
             <if @elements.legendtext@ defined>
               <!-- radio button groups and checkbox groups get their own fieldsets -->
			   </fieldset>
             </if>
		   </if>
		 </div>
       </else>
	</else>
  </group>

  <if @elements.section@ not nil>
    </fieldset> <!-- section fieldset -->
  </if>
</multiple>
