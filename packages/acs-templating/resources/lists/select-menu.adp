<%
# @author Miguel Marin (miguelmarin@viaro.net)
# @author Viaro Networks www.viaro.net
# @creation-date 2005-08-16
# 
# Displays all filters as a select box to save space, also
# has a javascript to manage filters that are of type multival
#
# USAGE: 
# <listfilters name="list_name" style="select-menu"></listfilters>
# <listtemplate name="list_name"></listtemplate>
#
# 
# NOTE: to use the multival filter you need to specify it in the
# template::list::create in the filters section like this:
#
# -filters {
#     filter_name {
#          label "Filter Label"
#          type multival
#	   values { {first_value 1 } {second_value 2} }
#	   where_clause { filter_where_cluse }
#     }
#  }
#  - The receiving page variable must be of the type :multiple
#    since the filter sends the values in the following way:
#    filter_name=filter_value&amp;filter_name=filter_value&....&amp;extra_variables=extra_values
%>


<tcl>
template::add_body_script -script {
function getSelectedValues (select_name, filter_url, filter_name) {

  var r = new Array();
  url = getPageURL(filter_url);
  extra_vars = getExtraVars( filter_name, filter_url);

  // We get all the values of the selected options for the filter
  // using the filter name.
  for (var i = 0; i < select_name.options.length; i++)
      if (select_name.options[i].selected) {
	  
          // Since the filter values is the whole url then we need to split it
          var value_array = (select_name.options[i].value).split(filter_name+'=');
          if ( (value_array[1]).search('&') == -1 ) 
          {
	      // The variables part has only the filter value
              r[r.length] = value_array[1];
          } 
          else
          {
	      // The variables part has more variables so we 
	      // split to get only the filter value
              filter_array = (value_array[1]).split('&');
              r[r.length] = filter_array[0];
          } 
      }	

  if (extra_vars.length > 0 ) {
      // There are extra variables, so we send then using along with the filter value
      return (url+'?'+filter_name+'='+r.join('&'+filter_name+'=')+'&'+extra_vars);
  } 
  else 
  {
      // Just send the filter value
      return (url+'?'+filter_name+'='+r.join('&'+filter_name+'='));
  } 
}

function getExtraVars (filter_name, filter_url) {
   var r = new Array();

   // Take the variables of the url only
   url_array = filter_url.split("?");
   variables = url_array[1];

   // Split all variables by "&"
   var_array = variables.split("&");

   // We store only the varaibles that are not equal to 
   // the filter name
   for ( var i = 0; i < var_array.length; i++) 
       if ( var_array[i].search(filter_name) == -1) 
           r[r.length] = var_array[i];
 
   // We return the variables joined by "&"
   return r.join("&");
}

function getPageURL (filter_url) {
   // Get the part of the location of the url
   var filter_array = filter_url.split("?");
   var url = filter_array[0];
   return url;
}
}
</tcl>

<table border="0">
<tr>
    <multiple name="filters">
        <td valign="top">
            <table border="0" cellspacing="0" cellpadding="2" width="100%">
		<tr>
        	    <td colspan="3" class="list-filter-header">
	                @filters.filter_label@
	                <if @filters.filter_clear_url@ not nil>
           		    (<a href="@filters.filter_clear_url@" title="Clear the currently selected @filters.filter_label@">clear</a>)
	                </if>
	            </td>
                </tr>
                <tr>
                    <td>
		        <if @filters.type@ eq "multival">
 	                    <select id="list-filter-@filters.rownum;literal@" name="@filters.filter_label@" multiple size="3">
			    <tcl>template::add_event_listener -id "list-filter-$filters(rownum)" -event change -script [subst {
	                          window.location = getSelectedValues(this,'$filters(url)','$filters(filter_name)');
	                    }]</tcl>
			</if>
		        <else>
 	                    <select id="list-filter-@filters.rownum;literal@" name="@filters.filter_label@">
			    <tcl>template::add_event_listener -id "list-filter-$filters(rownum)" -event change -script {
	                          window.location = this.options[this.selectedIndex].value;
	                    }</tcl>
			</else>
			    <if @filters.filter_clear_url@ nil>
		               <option value="#">- - - - -</option>
			    </if>
      	                    <group column="filter_name">
	                    <if @filters.selected_p;literal@ true>
			         <option value="@filters.url@" selected>
			             @filters.label@
                                 </option>
	                    </if>
        	            <else>
	        	         <option value="@filters.url@">
		    	             @filters.label@
                                 </option>
		            </else>
	                    </group>
	                </select>	
                    </td>
	        </tr>
            </table>
        </td>
    </multiple>
</tr>
</table>
