  <master>
    <property name="title">Merge account system</property>
    <property name="context">@context;noquote@</property>

    <h2>User Account Merge</h2>
    
    This is the user acccount merge wizard. You selected these accounts to merge:
    <p/>
      <table align="center">
	<tr>
	  <td valign="top">
	    <table style="background-color:#006666;border-width:2px;">
	      <tr>
		<td>
		  <table style="background-color:#D1FFFF">
		    <tr>
		      <td>
			<center>
			<b>ACCOUNT ONE</b>
			  <p/>
			  <img style="border:2" width="80" height="80" src="@one_img_src@" alt="Portrait of @user_id@">
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
			     @user_id_one_items_html;noquote@
			  </div>
			</div>
		      </td>
		    </tr>
		  </table>
		</td>
	      </tr>
	    </table>
	  </td>

	  <td  valign="top">
	    <form action="merge-confirm" method="get">
	      <table>
		<tr>
		  <td>
		    <center>		  
		      <b>Which is the good account?</b>
		      <p/>
			<input type="radio" name="merge_action" value="0">
			  <img src="/resources/acs-admin/left.gif" alt="left one">
		    </center>
		  </td>
		</tr>
		<tr>
		  <td>
		    <center>
		      <input type="radio" name="merge_action" value="1">
			<img src="/resources/acs-admin/right.gif" alt="right one">
		    </center>
		  </td>
		</tr>
		<tr>
		  <td>
		    <input type="hidden" name="from_user_id" value="@user_id@">
                    <input type="hidden" name="to_user_id" value="@user_id_from_search@">
                    <center>
		      <input type="submit" value="Continue">
                    </center>
                  </td>
	        </tr>
	      </table>
            </form>
	  </td>

	  <td  valign="top">
	    <table style="background-color:#FFA217">
	      <tr>
		<td>
		  <table style="background-color:#FFE3B9">
		    <tr>
		      <td>
			<center>
			  <b>ACCOUNT TWO</b>
			  <p/>
			    <img style="border:2" width="80" height="80" src="@two_img_src@" alt="Portrait of @user_id_from_search@">
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
			    @user_id_two_items_html;noquote@
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
