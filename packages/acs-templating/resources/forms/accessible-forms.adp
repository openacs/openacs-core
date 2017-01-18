<!-- Form elements -->

  <multiple name=elements>
  <if @elements.section@ not nil>
	  <fieldset>
    <legend>@elements.section@</legend>
  </if>
  
  <group column="section">
    <if @elements.widget@ eq "hidden"> 
      <noparse><div><formwidget id="@elements.id@"></div></noparse>
    </if>
    
    <else>
      <br>
        <if @elements.widget@ eq "submit">
	  <span class="form-element">
	    <group column="widget">
	      <noparse><formwidget id="@elements.id@"></noparse>
	    </group>
	    <br>
	    <br>
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
	    <label for="@elements.id@">
	      @elements.label;noquote@
	    </label>

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
		<label for="@elements.form_id@:elements:@elements.id@:\@formgroup.option@">
		  \@formgroup.label;noquote@
		</label>
	      </formgroup>
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
		  \@formerror.@elements.id@;noquote\@
	    </formerror>
	  </noparse>

	  <if @elements.help_text@ not nil>
	    <p class="form-help-text">
	      <noparse>
		<formhelp id="@elements.id@">
	      </noparse>
	    </p>
	  </if>

	</span>	  
        </else>
    </else>
  </group>
	<if @elements.section@ not nil>
	</fieldset>
	  </if>
  </multiple>
 
