<master src="master">
  <property name="title">@page_title@</property>
  <property name="context_bar">@context_bar;noquote@</property>
  <property name="focus">search.q</property>

<formtemplate id="search"></formtemplate>

<if @submit_p@ true>
  <h2>Search Results</h2>
        
  <table cellpadding="0" cellspacing="0" border="0">
   <tr>
     <td style="background: #CCCCCC">
       <table cellpadding="4" cellspacing="1" border="0">
         <tr style="background: #FFFFe4">
           <th>Package</th>
           <th>Key</th>
           <th>Original Message</th>
           <th>Translated Message</th>
           <th>Action</th>
         </tr>
         <multiple name="messages">
           <tr style="background: #EEEEEE">
             <td><a href="@messages.package_url@" title="Batch edit messages in this package">@messages.package_key@</a></td>
             <td>@messages.message_key@</td>
             <td>@messages.default_message@</td>
             <td>@messages.translated_message@</td>
             <td>(<span class="edit-anchor"><a href="@messages.edit_url@" title="Localize this message">edit</a></span>)</td>
           </tr>
         </multiple>
      </table>
     </td>
   </tr>
 </table>

  
</if>
