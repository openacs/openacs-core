<master src="/www/site-master">
<if @doc@ defined><property name="&doc">doc</property></if>
<if @body@ defined><property name="&body">body</property></if>
<if @head@ not nil><property name="head">@head;literal@</property></if>
<if @focus@ not nil><property name="focus">@focus;literal@</property></if>
<property name="skip_link">@skip_link;literal@</property>

<div id="wrapper">
  <div id="system-name">
    <if @system_url@ not nil><a href="@system_url@">@system_name@</a></if>
    <else>@system_name@</else>
  </div>
  <div id="header">
    <div class="block-marker">Begin header</div>
    <div id="header-navigation">
      <ul class="compact">
        <li>
          <if @untrusted_user_id@ ne 0>#acs-subsite.Welcome_user#</if>
          <else>#acs-subsite.Not_logged_in#</else> | 
        </li>
        <li><a href="@whos_online_url@" title="#acs-subsite.view_all_online_members#">@num_users_online@ <if @num_users_online;literal@ true>#acs-subsite.Member#</if><else>#acs-subsite.Members#</else> #acs-subsite.Online#</a> |</li>
        <if @pvt_home_url@ not nil>
          <li><a href="@pvt_home_url@" title="#acs-subsite.Change_pass_email_por#">@pvt_home_name@</a> |</li>
        </if>
        <if @login_url@ not nil>
          <li><a href="@login_url@" title="#acs-subsite.Log_in_to_system#">#acs-subsite.Log_In#</a></li>
        </if>
        <if @logout_url@ not nil>
          <li><a href="@logout_url@" title="#acs-subsite.Logout_from_system#">#acs-subsite.Logout#</a></li>
        </if>
      </ul>
    </div>
    <div id="breadcrumbs">
      <if @context_bar@ not nil>
        @context_bar;noquote@
      </if>
      <else>
        <if @context:rowcount@ not nil>
        <ul class="compact">
          <multiple name="context">
          <if @context.url@ not nil>
            <li><a href="@context.url@">@context.label@</a> :</li>
          </if>
          <else>
            <li>@context.label@</li>
          </else>
          </multiple>
        </ul>
        </if>
      </else>
    </div>
  </div> <!-- /header -->

  <div id="content-wrapper">
    <div class="block-marker">Begin main content</div>
    <div id="inner-wrapper">
        
     <if @user_messages:rowcount@ gt 0>
       <div id="alert-message">
         <multiple name="user_messages">
           <div class="alert">
             <strong>@user_messages.message;noquote@</strong>
           </div>
         </multiple>
       </div>
     </if>

     <div id="navbar-div">
       <div id="navbar-container">
         <div id="navbar"> 
           <multiple name="sections">
             <if @sections.selected_p;literal@ true>
               <div class="tab" id="navbar-here">
                 <if @sections.link_p;literal@ true>
                   <a href="@sections.url@" title="@sections.title@">@sections.label@</a>
                 </if>
                 <else>        
                   @sections.label@
                 </else>
               </div>
             </if>
             <else>
               <div class="tab">
                 <if @sections.link_p;literal@ true>
                   <a href="@sections.url@" title="@sections.title@">@sections.label@</a>
                 </if>
                 <else>        
                   @sections.label@
                 </else>
               </div>
             </else>
           </multiple>
         </div>
       </div>
     </div>
     <div id="navbar-body">
     <!-- Second level navigation -->
       <if @subsections:rowcount@ gt 0>
         <div id="subnavbar-div">
           <div id="subnavbar-container">
             <div id="subnavbar">
               <multiple name="subsections">
                 <if @subsections.selected_p;literal@ true>
                   <div class="tab" id="subnavbar-here">
                     <if @subsections.link_p;literal@ true>
                       <a href="@subsections.url@" title="@subsections.title@">@subsections.label@</a>
                     </if>
                     <else>        
                       @subsections.label@
                     </else>
                   </div>
                 </if>
                 <else>
                   <div class="tab">
                     <if @subsections.link_p;literal@ true>
                       <a href="@subsections.url@" title="@subsections.title@">@subsections.label@</a>
                     </if>
                     <else>        
                       @subsections.label@
                     </else>
                   </div>
                 </else>
               </multiple>
             </div>
           </div>
         </div>
         <div id="subnavbar-body">
       </if>

       <div id="main">
         <div id="main-content">
           <div class="main-content-padding">
             <slave />
           </div>
         </div>
       </div>

       <if @subsections:rowcount@ gt 0>
         </div>
       </if>

    </div>
  </div> <!-- /content-wrapper -->

  <comment>
    TODO: remove this and add a more systematic / package independent way 
    TODO  of getting this content here
  </comment>
  <if @curriculum_bar_p;literal@ true><include src="/packages/curriculum/lib/bar" ></if>

  <div id="footer">
    <div class="block-marker">Begin footer</div>
    <div id="footer-links">
      <ul class="compact">
      <if @num_of_locales@ gt 1>
        <li><a href="@change_locale_url@">#acs-subsite.Change_locale_label#</a></li>
      </if>
      <else>
        <if @locale_admin_url@ not nil>
          <li><a href="@locale_admin_url@">Install locales</a></li>
        </if>
      </else>
      </ul>
    </div>
    </div>
  </div> <!-- /footer -->

</div> <!-- /wrapper -->
