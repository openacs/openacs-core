<style>

/* First level tabs */

#navbar-div {
  border-bottom: 1px solid #666;
}
#navbar-container {
  height: 35px;
  position: relative;
}
#navbar { 
  position: absolute;
  height: 21px;
  margin: 0px;
  padding: 0px 0px 0px 0px;
  left: 10px;
  bottom: -2px;
  margin-top: 10px;
  font-family: Arial, sans-serif;
  font-size: 80%;
  font-weight: bold;
}
html>body #navbar { bottom: 0px }

#navbar .tab { 
  height: 16px;
  float: left; 
  background-color: #eeeeee; 
  border: 1px solid #666;
  padding: 2px 5px 2px 5px;
  margin: 0px 2px 0px 2px;
}
#navbar a {
  text-decoration: none;
  color: black;
}
#navbar a:hover {
  text-decoration: underline;
}
#navbar #navbar-here { 
  border-bottom-color: white;
  background-color: white;
}
#navbar #navbar-here a {
  color: black;
}

#navbar-body { 
  border-bottom: 1px solid #016799;
  background-color: white;
  clear: both;
  padding-top: 4px;
  padding-left: 12px;
  padding-right: 12px;
  padding-bottom: 12px;
}

</style>
<multiple name="authorities">
<if @authorities.authority_id@ eq @selected_authority_id@>
<include src="@authorities.form_include;literal@" authority_id="@authorities.authority_id;literal@" search_text="@search_text;literal@" return_url="@return_url;literal@" orderby="@orderby;literal@" member_url="@member_url;literal@" group_id="@group_id;literal@" &="rel_type" &="object_id" &="privilege"></if>
</multiple>

<div id="navbar-div">
  <div id="navbar-container">
    <div id="navbar"> 
      <multiple name="authorities">
        <if @selected_authority_id@ eq @authorities.authority_id@>	
          <div class="tab" id="navbar-here">
@authorities.pretty_name@
          </div>
        </if>
        <else>
          <div class="tab">
              <a href="@authorities.search_url@" title="@authorities.pretty_name@">@authorities.pretty_name@
</a>
          </div>
        </else>
      </multiple>
    </div>
  </div>
</div>
<div id="navbar-body">

<if @authorities:rowcount@ gt 1>
<h2>#acs-authentication.lt_Not_getting_the_results_you_expected#
<multiple name="authorities">
<if @authorities.authority_id@ ne @authority_id@>
<a href="@authorities.search_url@">@authorities.pretty_name@</a><if @authorities.rownum@ lt @authorities:rowcount@> </if>
</if>
</multiple>
</h2>
</if>
<listtemplate name="users"></listtemplate>
</div>