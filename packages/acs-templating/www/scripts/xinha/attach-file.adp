<master src="/www/blank-master">
  <property name="doc(title)">#acs-templating.HTMLArea_InsertLink#</property>
	<table border="0" width="100%" style="margin: 0 auto; text-align: left;padding: 0px;">
	  <tbody>
      <td valign="top">
	<if @write_p;literal@ true>
	    <formtemplate id="upload_form">
	<formwidget id="f_href">
			<input type="hidden" id="f_target"/>
			<input type="hidden" id="f_usetarget"/>
			<table cellspacing="2" cellpadding="2" border="0" width="100%">
					<tr class="form-group">
				<if @formerror.upload_file@ not nil>
					<td class="form-widget-error">
				</if>
	          	<else>
		    		<td class="form-widget">
				</else> 	
					<fieldset>
						<legend>#acs-templating.Title#</legend>
						<formwidget id="f_title">
		    				<formerror id="f_title">
		      				<div class="form-error">@formerror.f_title@</div>
		    			</formerror>
					</fieldset>
					You can link to the above text to a file. Select one of the options below.<br /><br />

					<if @recent_files_options@ ne "">
					<fieldset>
	        			<legend>#acs-templating.Choose_File#</legend>
						<formgroup id="choose_file">
							<if @formgroup.rownum@ odd and @formgroup.rownum@ gt 1><br /></if>
								@formgroup.widget;noquote@ 								<label for="upload_form:elements:choose_file:@formgroup.option@">@formgroup.label;noquote@</label>
							</formgroup>
		    				<formerror id="choose_file">
		      					<div class="form-error">@formerror.choose_file@</div>
		    				</formerror>
						<br /><formwidget id="select_btn">&nbsp;<input type="button" value="#acs-templating.HTMLArea_action_cancel#" name="cancel" onclick="javascript:onCancel();">
					</fieldset>
					</if>
					</td>
				</tr> 
		<tr class="form-element">
		  <if @formerror.f_title@ not nil>
		    <td class="form-widget-error">
		  </if>
		  <else>
		    <td class="form-widget">
		  </else>
	<fieldset>
	<legend>#acs-templating.Upload_a_New_File#</legend>                  
		<br />

		  <formwidget id="upload_file">
		    <formerror id="upload_file">
		      <div class="form-error">@formerror.upload_file@</div>
		    </formerror><br />
                        #acs-templating.This_file_can_be_reused_by#<br />
                        <formgroup id="share">
                          @formgroup.widget;noquote@ @formgroup.label@
		    <br /></formgroup>
                  <img src="/shared/images/info.gif" width="12" height="9" alt="[i]" title="Help text" border="0">
                  #acs-templating.This_file_can_be_reused_help#
                  		    <br />
		    <formerror id="share">
		      <div class="form-error">@formerror.share@</div>
		    </formerror>                        
	<formwidget id="ok_btn">&nbsp;<button type="button"
	name="cancel" onclick="return onCancel();">#acs-templating.HTMLArea_action_cancel#</button>
          </fieldset>
      </td>
    </tr>
    </table>
    </formtemplate>
    </fieldset>
    </if>
	</td>
	</tr>
	</tbody>
	</table>
</body>
</html>
