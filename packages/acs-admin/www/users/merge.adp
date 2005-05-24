  <master>
    <property name=title>Merge account system</property>
    <property name="context">@context;noquote@</property>
    <property name="header_stuff">
      <link rel="stylesheet" type="text/css" href="/resources/acs-admin/um-more-info.css" media="all">-->
    </property    
    <h2>User Account Merge</h2>
    
    This is the user acccount merge quick wizard. You selected these accounts to merge:
    <p/>
      <table align=center>
	<tr>
	  <td valign=top>
	    <table style="background-color:#006666;border-width:2px;">
	      <tr>
		<td>
		  <table style="background-color:#D1FFFF">
		    <tr>
		      <td>
			<center>
			<b>ACCOUNT ONE</b>
			  <p/>
			  <img border=2 width="80" height="80" src="@one_img_src@" alt="Portrait of @user_id@" />
			    <h3>General Information of user one (<b>@one_email@</b>):</h3>
			</center>
			<ul>
			  <li>
			    Name:
			    <i>@one_first_names@ @one_last_name@</i>
			  </li>
			  <li>
			    Email:
			    <b><a href="mailto:@one_email@">@one_email@</a></b>
			  </li>
			  <li>
			    Scren name:
			    <b>@one_screen_name@</b>
			  </li>
			  <li>
			    Username:
			    <b>@one_username@</b>
			  </li>

			  <li>
			    User id:
			    @user_id@
			  </li>

			  <li>
			    URL:
			    @one_url@
			  </li>

			  <li>
			    Registration date:
			    @one_creation_date@
			  </li>

			  <li>
			    Registration IP:
			    @one_creation_ip@
			  </li>

			  <li>
			    Registration user:
			    @one_creation_user@
			  </li>

			  <li>
			    Last modified date:
			    @one_last_modified@
			  </li>

			  <li>
			    Modifying IP:
			    @one_modifying_ip@
			  </li>

			  <li>
			    Modifying user:
			    @one_modifying_user@
			  </li>

			  <li>
			    Last visit:
			    @one_last_visit@
			  </li>

			  <li>
			    Member state:
			    @one_member_state@
			  </li>
			</ul>
			  <center>
			    (<a href="javascript:void(d=document);void(el=d.getElementsByTagName('div'));for(i=0;i&lt;el.length;i++){if(el[i].className=='um-more-info'){void(el[i].className='um-more-info-off')}else{if(el[i].className=='um-more-info-off'){void(el[i].className='um-more-info')}}};" class="off" title="Toggle Footer display">more information</a>)
			  </center>
			    
    <div class="um-adp-box-off">
      <div class="um-more-info-off">
		
			      <multiple name="one_user_contributions">
			    
				<h2>@one_user_contributions.pretty_plural@</h2>
				<ul>
				  
				  <group column="pretty_name">
				    <li>@one_user_contributions.creation_date@: <a href="@one_user_contributions.one_item_object_url@" >@one_user_contributions.object_name@</a></li>
				  </group>
				</ul>
				
			      </multiple>
			      <p/>
				<center>
				  <h3>.LRN Information:</h3>
				</center>		  
				<if @one_dotlrn_user_p@ eq 1>
				  <ul>
				    <li>
				      User type:
				      <%= [lang::util::localize @one_pretty_type@] %>
				    </li>
				    <li>
				      Access Level
				      <if @one_can_browse_p@>Full</if>
				      <else>Limited </else>
				    </li>
				    <li>
				      Guest?
				      <if @one_guest_p@ eq t>Yes</if>
				      <else>No</else>
				    </li>
				    <li>
				      ID
				      <if @one_id@ nil>none</if>
				      <else>@one_id@</else>
				    </li>
				    <br>
				  </ul>
				  <if @one_member_classes:rowcount@ gt 0>
				    <blockquote>
				      <h4>Classes:</h4>
				      <ul>
					<multiple name="one_member_classes">
					  <li>
					    <a href="@one_member_classes.url@">@one_member_classes.pretty_name@</a>
					    @one_member_classes.term_name@ @one_member_classes.term_year@
					    (@one_member_classes.role_pretty_name@)
					  </li>
					</multiple>
				      </ul>
				    </blockquote>
				  </if>
				  
				  <if @one_member_clubs:rowcount@ gt 0>
				    <blockquote>
				      <h4>Communities: </h4>
				      <ul>
					<multiple name="one_member_clubs">
					  <li>
					    <a href="@one_member_clubs.url@">@one_member_clubs.pretty_name@</a>
					    (@one_member_clubs.role_pretty_name@)
					  </li>
					</multiple>
				      </ul>
				    </blockquote>
				  </if>
				  
				  <if @one_member_subgroups:rowcount@ gt 0>
				    <blockquote>
				      <h4>Sugroups: </h4>
				      <ul>
					<multiple name="one_member_subgroups">
					  <li>
					    <a href="@one_member_subgroups.url@">@one_member_subgroups.pretty_name@</a>
					    (@one_member_subgroups.role_pretty_name@)
					  </li>
					</multiple>
				      </ul>
				    </blockquote>
				  </if>
				</if>
				<else>
				  No information was found
				</else>
			  </div>
			</div>
		      </td>
		    </tr>
		  </table>
		</td>
	      </tr>
	    </table>
	  </td>
	  <td  valign=top>
	    <table>
	      <tr>
		<td>
		  <form action=merge-confirm method=get>
		    <center>		  
		      <b>Wich is the good account?</b>
		      <p/>
		      <input type="radio" name="merge_action" value="0" />
		      <img src="/resources/acs-admin/left.gif" alt="left one" />
		    </center>
		</td>
	      </tr>
	      <tr>
		<td>
		  <center>
		    <input type="radio" name="merge_action" value="1" />
		      <img src="/resources/acs-admin/right.gif" alt="right one">
		  </center>
		</td>
	      </tr>
	      <tr>
		<td>
		  <input type="hidden" name=from_user_id value="@user_id@" />
		  <input type="hidden" name=to_user_id value="@user_id_from_search@" />
		  <center>
		    <input type="submit" value="Continue"/>
		  </center>
		  </form>
		</td>
	      </tr>
	    </table>
	  </td>
      <td  valign=top>
	<table style="background-color:#FFA217">
	  <tr>
	    <td>
	      <table style="background-color:#FFE3B9">
		<tr>
		  <td>
		    <center>
		      <b>ACCOUNT TWO</b><p/>
			  <img border=2 width="80" height="80" src="@two_img_src@" alt="Portrait of @user_id_from_search@" />
			    <h3>General Information of user two (<b>@two_email@</b>):</h3>
			</center>
			<ul>
			  <li>
			    Name:
			    <i>@two_first_names@ @two_last_name@</i>
			  </li>
			  
			  <li>
			    Email:
			    <b><a href="mailto:@two_email@">@two_email@</a></b>
			  </li>
			  
			  <li>
			    Scren name:
			    <b>@two_screen_name@</b>
			  </li>
			  
			  <li>
			    Username:
			    <b>@two_username@</b>
			  </li>

			  <li>
			    User id:
			    @user_id_from_search@
			  </li>

			  <li>
			    URL:
			    @two_url@
			  </li>

			  <li>
			    Registration date:
			    @two_creation_date@
			  </li>

			  <li>
			    Registration IP:
			    @two_creation_ip@
			  </li>

			  <li>
			    Registration user:
			    @two_creation_user@
			  </li>

			  <li>
			    Last modified date:
			    @two_last_modified@
			  </li>

			  <li>
			    Modifying IP:
			    @two_modifying_ip@
			  </li>

			  <li>
			    Modifying user:
			    @two_modifying_user@
			  </li>

			  <li>
			    Last visit:
			    @two_last_visit@
			  </li>

			  <li>
			    Member state:
			    @two_member_state@
			  </li>
			</ul>
	
		    <center>
		      (<a href="javascript:void(d=document);void(el=d.getElementsByTagName('div'));for(i=0;i&lt;el.length;i++){if(el[i].className=='um-more-info2'){void(el[i].className='um-more-info-off2')}else{if(el[i].className=='um-more-info-off2'){void(el[i].className='um-more-info2')}}};" class="off" title="Toggle Footer display">more information</a>)
		    </center>
 		    
		    <div class="um-adp-box-off2">
		      <div class="um-more-info-off2">
		      <multiple name="two_user_contributions">
			
			<h2>@two_user_contributions.pretty_plural@</h2>
			<ul>
			  
			  <group column="pretty_name">
			    <li>@two_user_contributions.creation_date@: <a href="@two_user_contributions.two_item_object_url@"> @two_user_contributions.object_name@ </a></li>
			  </group>
			</ul>
			 
		      </multiple>
		      <p/>
			  <center>
			    <h3>.LRN Information:</h3>
			  </center>		  
			  <if @two_dotlrn_user_p@ eq 1>
			    <ul>
			      <li>
				User type:
				<%= [lang::util::localize @two_pretty_type@] %>
			      </li>
			      <li>
				Access Level
				<if @two_can_browse_p@>Full</if>
				<else>Limited </else>
			      </li>
			      <li>
				Guest?
				<if @two_guest_p@ eq t>Yes</if>
				<else>No</else>
			      </li>
			      <li>
				ID
				<if @two_id@ nil>none</if>
				<else>@two_id@</else>
			      </li>
			      <br>
			    </ul>
			    <if @two_member_classes:rowcount@ gt 0>
			      <blockquote>
				<h4>Classes:</h4>
				<ul>
				  <multiple name="two_member_classes">
				    <li>
				      <a href="@two_member_classes.url@">@two_member_classes.pretty_name@</a>
				      @two_member_classes.term_name@ @two_member_classes.term_year@
				      (@two_member_classes.role_pretty_name@)
				    </li>
				  </multiple>
				</ul>
			      </blockquote>
			    </if>

			    <if @two_member_clubs:rowcount@ gt 0>
			      <blockquote>
				<h4>Communities: </h4>
				<ul>
				  <multiple name="two_member_clubs">
				    <li>
				      <a href="@two_member_clubs.url@">@two_member_clubs.pretty_name@</a>
				      (@two_member_clubs.role_pretty_name@)
				    </li>
				  </multiple>
				</ul>
			      </blockquote>
			    </if>
      
			    <if @two_member_subgroups:rowcount@ gt 0>
			      <blockquote>
				<h4>Sugroups: </h4>
				<ul>
				  <multiple name="two_member_subgroups">
				    <li>
				      <a href="@two_member_subgroups.url@">@two_member_subgroups.pretty_name@</a>
				      (@two_member_subgroups.role_pretty_name@)
				    </li>
				  </multiple>
				</ul>
			      </blockquote>
			    </if>
			  </if>
			  <else>
			    No information was found
			  </else>
		      </div>
		    </div>
		      </td>
		    </tr>
		  </table>
		</td>
	      </tr>
	    </table>
	  </td>
	</tr>
      </table>
