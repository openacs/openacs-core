<master>
  <property name="context">@context;noquote@</property>
  <property name="title">@subsite_name;noquote@</property>


<h1>Welcome to OpenACS/dotLRN</h1>
This is the default page for your site.
<p />

<table>
  <tr>
    <td valign="top">
<h2>How do I work with OpenACS?</h2>
You can start by reading the <a href="/doc/">documentation</a>, specifically <a href="/doc/configuring-new-site.html">tips on customizing</a>, the <a href="/doc/tutorial.html">developer's tutorial</a>, and

<a href="http://www.openacs.org//faq/">the FAQs</a>. There is a <a href="http://www.openacs.org/wiki">OpenACS Wiki</a> and a <a href="http://www.openacs.org/projects/openacs/packages/">list of packages</a> that extend OpenACS. <p>For professional help, contact <a href="http://www.openacs.org/community/companies">one of the OpenACS companies</a>.

<div class="portlet-wrapper">
      <div class="portlet">
        <h2>#acs-subsite.Applications#</h2>
        <div class="portlet">
          <include src="/packages/acs-subsite/lib/applications">
        </div>
      </div>
</div>
    </td>
    <td valign="top">
<h2>Developer Community</h2>
One of the strengths of the OpenACS project is the community surrounding it:
<ul>
<li><a href="http://www.openacs.org/forums/">Discussion forums</a></li>

<li><a href="http://www.openacs.org/blog/">Tips and hints blog</a></li>
<li><a href="http://www.openacs.org/irc/">IRC</a> at <code><a href="irc://irc.freenode.net/#openacs">irc://irc.freenode.net/#openacs</a></code></li>
<li><a href="http://www.openacs.org/irc/log/">Chatroom logs</a> and <a href="http://www.openaccs.org/irc/log/logger/current">today's log</a></li>
<li><a href="http://www.openacs.org/contribute/">How to contribute</a></li>
</ul>


<h2>Standards Compliance</h2>
We aim to comply with all the major web and elearning standards including:
<p>
 <a href="http://jigsaw.w3.org/css-validator/">
  <img style="border:0;width:88px;height:31px"
       src="http://jigsaw.w3.org/css-validator/images/vcss" 
       alt="Valid CSS!">
 </a>
</p>

<p>
    <a href="http://validator.w3.org/check?uri=referer"><img
        src="http://www.w3.org/Icons/valid-html401"
        alt="Valid HTML 4.01 Transitional" height="31" width="88"></a>
  </p>

<a href="http://validator.w3.org/check/referer">HTML 4.01</a>,
 <a href="http://jigsaw.w3.org/css-validator/check/referer">CSS</a>,
 <a href="http://feedvalidator.org/check?url=http://129.78.27.9:8200//">RSS</a>,
 <a href="http://www.contentquality.com/mynewtester/cynthia.exe?Url1=http://129.78.27.9:8200//" title="Please note that no software can truly test your site for accessibility compliance.">508</a>,
<a href="http://www.adlnet.org/scorm/adopters/index.cfm">SCORM</a>

      <div class="portlet">
        <h2>#acs-subsite.Subsites#</h2>
        <div class="portlet-body">
          <include src="/packages/acs-subsite/lib/subsites">
        </div>
      </div>
    </td>
  </tr>

  <tr>
    <td valign="top" colspan="2">
      <div class="portlet">
        <if @show_members_page_link_p@>
          <a href="members/" class="button">#acs-subsite.Members#</a>
        </if>
	  <a href="site-map/" class="button">#acs-subsite.UserSiteMap#</a>
        <if @untrusted_user_id@ ne 0>
          <if @main_site_p@ false>  
            <if @group_member_p@ true>
              <a href="group-leave" class="button" title="#acs-subsite.Leave_this_subsite#">#acs-subsite.Leave_subsite#</a>
            </if>
            <else>
              <if @can_join_p@ true>
                <if @group_join_policy@ eq "open">
                  <a href="register/user-join" class="button" title="#acs-subsite.Join_this_subsite">#acs-subsite.Join_subsite#</a>
                </if>
                <else>
                  <a href="register/user-join" class="button" title="#acs-subsite.Req_membership_subs#">#acs-subsite.Request_membership#</a>
                </else>
              </if>
            </else>
          </if>
        </if>
        <if @admin_p@ true> 
          <a href="admin/" class="button" title="#acs-subsite.Administer_subsite#">#acs-kernel.common_Administration#</a>
        </if>
      </div>
    </td>
  </tr>
</table>
  

