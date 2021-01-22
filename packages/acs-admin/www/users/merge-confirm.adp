  <master>
    <property name="doc(title)">Merge account system</property>
    <property name="context">@context;literal@</property>
    
    <h2>Confirm Merge</h2>
    
    <center>
    <p/>
    <strong>
      The user @from_first_names@ @from_last_name@ (@from_email@) will be deleted.
    </strong>
    <p/>
    <strong style="color:red">
      These accounts will be merged and the <u>good and final account</u> will be: 

    <p/>
    <img style="border:2" width="80" height="80" src="@to_img_src@" alt="Portrait of @to_user_id@">
		    <br>
    <span style="font-size:14pt;">@to_first_names@ @to_last_name@ (@to_email@)</span>	      
    <p/>

    </strong>
    <p/>
      <strong>WARNING:</strong> Are you are absolutely sure to merge these accounts? 
    <p/>
    <form action=merge-final method=get>
      <table>
	<tr>
	  <td>
	    <input type="radio" name="merge_p" value="1">
	  </td>
	  <td> 
	    Yes, I'm sure that I don't need the account @from_email@ anymore!.
	  </td>
        </tr>
        <tr>
	  <td>
            <input  checked=checked type="radio" name="merge_p" value="0" >
          </td>
          <td>
	    No, I'm not sure.
	  </td>
	</tr>
	<tr>
	  <td colspan="2" align="center">
            <input type="hidden" name="from_user_id" value="@from_user_id@">
            <input type="hidden" name="to_user_id" value="@to_user_id@">
	    <input type="submit" value="OK">
          </td>
	</tr>
      </table>
    </form>
    </center>

	