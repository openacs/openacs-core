<%
# @author Miguel Marin (miguelmarin@viaro.net)
# @author Viaro Networks www.viaro.net
# @creation-date 2005-08-16
# 
# Displays all filters as a select box to save space
%>

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
	                <select name="@filters.filter_label@" onchange="window.location = this.options[this.selectedIndex].value">		       <if @filters.filter_clear_url@ not nil>
		               <option value="@filters.filter_clear_url@"> - - - - - </option>
                            </if>
                            <else>
		               <option value=""> - - - - - </option>
			    </else>
      	                    <group column="filter_name">
	                    <if @filters.selected_p@ true>
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
