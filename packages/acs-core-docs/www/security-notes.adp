
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Security Notes}</property>
<property name="doc(title)">Security Notes</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="security-design" leftLabel="Prev"
		    title="
Chapter 15. Kernel Documentation"
		    rightLink="rp-requirements" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="security-notes" id="security-notes"></a>Security Notes</h2></div></div></div><div class="authorblurb">
<p>By Richard Li</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><p>The security system was designed for security. Thus, decisions
requiring trade-offs between ease-of-use and security tend to
result in a system that may not be as easy to use but is more
secure.</p><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="security-notes-https-sessions" id="security-notes-https-sessions"></a>HTTPS and the sessions
system</h3></div></div></div><p>If a user switches to HTTPS after logging into the system via
HTTP, the user must obtain a secure token. To insure security, the
<span class="emphasis"><em>only way</em></span> to obtain a secure
token in the security system is to authenticate yourself via
password over an HTTPS connection. Thus, users may need to log on
again to a system when switching from HTTP to HTTPS. Note that
logging on to a system via HTTPS gives the user both insecure and
secure authentication tokens, so switching from HTTPS to HTTP does
not require reauthentication.</p><p>This method of authentication is important in order to
establish, in as strong a manner as possible, the identity of the
owner of the secure token. In order for the security system to
offer stronger guarantees of someone who issues a secure token, the
method of authentication must be as strong as the method of
transmission.</p><p>If a developer truly does not want such a level of protection,
this system can be disabled via source code modification only. This
can be accomplished by commenting out the following lines in the
<code class="computeroutput">sec_handler</code> procedure defined
in <code class="computeroutput">security-procs.tcl</code>:</p><pre class="programlisting">

    if { [ad_secure_conn_p] &amp;&amp; ![ad_login_page] } {
        set s_token_cookie [ns_urldecode [ad_get_cookie "ad_secure_token"]]
        
        if { $s_token_cookie eq "" || $s_token_cookie ne [lindex [sec_get_session_info $session_id] 2]} {
        # token is incorrect or nonexistent, so we force relogin.
        ad_returnredirect "/register/index?return_url=[ns_urlencode [ad_conn url]?[ad_conn query]]"
        }
    }

</pre><p>The source code must also be edited if the user login pages have
been moved out of an OpenACS system. This information is contained
by the <code class="computeroutput">ad_login_page</code> procedure
in <code class="computeroutput">security-procs.tcl</code>:</p><pre class="programlisting">

ad_proc -private ad_login_page {} {
    
    Returns 1 if the page is used for logging in, 0 otherwise. 

} {

    set url [ad_conn url]
    if { [string match "*register/*" $url] || [string match "/index*" $url] } {
    return 1
    }

    return 0
}

</pre><p>The set of string match expressions in the procedure above
should be extended appropriately for other registration pages. This
procedure does not use <code class="computeroutput">ad_parameter</code> or regular expressions for
performance reasons, as it is called by the request processor.</p><div class="cvstag">($&zwnj;Id: security-notes.xml,v 1.7 2014/10/27
16:39:32 victorg Exp $)</div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="security-design" leftLabel="Prev" leftTitle="Security Design"
		    rightLink="rp-requirements" rightLabel="Next" rightTitle="Request Processor Requirements"
		    homeLink="index" homeLabel="Home" 
		    upLink="kernel-doc" upLabel="Up"> 
		