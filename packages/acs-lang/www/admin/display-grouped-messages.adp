<master src="master">
 <property name="title">@page_title;noquote@</property>
 <property name="context_bar">@context_bar;noquote@</property>

<div>

<p>Your locale is <strong>@locale_label@</strong> [ <tt>@current_locale@</tt> ]</p>

<p>
  <b>&raquo;</b> <a href="@message_search_url@">Search localized messages</a>
</p>

<if @missing_translation_group:rowcount@ eq 0>

  <p>Note from the system: <strong>NO</strong> messages need to be translated. <emphasis>Job well done</emphasis> <tt>:-)</tt></p>

</if>

<table cellpadding="2" cellspacing="4" border="0" width="100%">
 <tr>
  <td valign="top">

   <!-- All Packages -->

   <table cellpadding="0" cellspacing="0" border="0" width="100%">
    <tr>
     <td style="background: #CCCCCC">
      <table cellpadding="2" cellspacing="1" border="0" width="100%">
       <tr valign="middle" style="background: #CCCCFF">
        <th colspan="2">All Packages</th>
       </tr>
       <tr style="background: #FFFFFF">
        <td align="left">
         <table cellpadding="0" cellspacing="0" border="0">
          <tr>
           <td style="background: #CCCCCC">
            <table cellpadding="4" cellspacing="1" border="0">
             <tr valign="middle" style="background: #FFFFE4">
              <th>Package</th>
              <th>Action</th>
             </tr>
             <multiple name="all_packages_group">
             <tr style="background: #EEEEEE">
              <td>@all_packages_group.package_key@</td>
              <td>
               (<span class="edit-anchor"><a href="batch-editor?package_key=@all_packages_group.package_key_encoded@&amp;locale=@all_packages_group.locale_encoded@&translated_p=0">batch edit</a></span>)
               <if @new_allowed_p@ eq 1>
                (<span class="edit-anchor"><a href="localized-message-new?package_key=@all_packages_group.package_key_encoded@&amp;locale=@all_packages_group.locale_encoded@">new message key</a></span>)
               </if>
              </td>
             </tr>
             </multiple>
            </table>
           </td>
          </tr>
         </table>
        </td>
       </tr>
      </table>
     </td>
    </tr>
   </table>
  </td>
  <td valign="top">

   <!-- Not Translated -->

   <table cellpadding="0" cellspacing="0" border="0" width="100%">
    <tr>
     <td style="background: #CCCCCC">
      <table cellpadding="2" cellspacing="1" border="0" width="100%">
       <tr valign="middle" style="background: #CCCCFF">
        <th colspan="2">Need Translation</th>
       </tr>
       <tr style="background: #FFFFFF">
        <td align="left">
         <table cellpadding="0" cellspacing="0" border="0">
          <tr>
           <td style="background: #CCCCCC">
            <table cellpadding="4" cellspacing="1" border="0">
             <tr valign="middle" style="background: #FFFFE4">
              <th>Package</th>
              <th>Action</th>
             </tr>
             <multiple name="missing_translation_group">
             <tr style="background: #EEEEEE">
              <td>@missing_translation_group.package_key@</td>
              <td>
               (<span class="edit-anchor"><a href="display-localized-messages?package_key=@missing_translation_group.package_key_encoded@&amp;locale=@missing_translation_group.locale_encoded@&translated_p=0">edit untranslated</a></span>)
               <if @new_allowed_p@ eq 1>
                (<span class="edit-anchor"><a href="localized-message-new?package_key=@missing_translation_group.package_key_encoded@&amp;locale=@missing_translation_group.locale_encoded@">new message key</a></span>)
               </if>
              </td>
             </tr>
             </multiple>
            </table>
           </td>
          </tr>
         </table>
        </td>
       </tr>
      </table>
     </td>
    </tr>
   </table>
  </td>
  <td align="center" valign="top">

   <!-- Translated -->

   <table cellpadding="0" cellspacing="0" border="0" width="100%">
    <tr>
     <td style="background: #CCCCCC">
      <table cellpadding="2" cellspacing="1" border="0" width="100%">
       <tr style="background: #CCCCFF">
        <th colspan="2">
         Already translated
        </th>
       </tr>
       <tr style="background: #FFFFFF">
        <td align="left">
         <table cellpadding="0" cellspacing="0" border="0">
          <tr>
           <td style="background: #CCCCCC">
            <table cellpadding="4" cellspacing="1" border="0">
             <tr valign="middle" style="background: #FFFFE4">
              <th>Package</th>
              <th>Action</th>
             </tr>
             <multiple name="translated_messages_group">
             <tr style="background: #EEEEEE">
              <td>@translated_messages_group.package_key@</td>
              <td>
               (<span class="edit-anchor"><a href="display-localized-messages?package_key=@translated_messages_group.package_key_encoded@&amp;locale=@translated_messages_group.locale_encoded@&translated_p=1">edit translated</a></span>)
               <if @new_allowed_p@ eq 1>
                (<span class="edit-anchor"><a href="localized-message-new?package_key=@translated_messages_group.package_key_encoded@&amp;locale=@translated_messages_group.locale_encoded@">new message key</a></span>)
               </if>
              </td>
             </tr>
             </multiple>
            </table>
           </td>
          </tr>
         </table>
        </td>
       </tr>
      </table>
     </td>
    </tr>
   </table>
  </td>
 </tr>
</table>

</div>
