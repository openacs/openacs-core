
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Security Design}</property>
<property name="doc(title)">Security Design</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="security-requirements" leftLabel="Prev"
			title="Chapter 15. Kernel
Documentation"
			rightLink="security-notes" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="security-design" id="security-design"></a>Security Design</h2></div></div></div><span style="color: red">&lt;authorblurb&gt;</span><p><span style="color: red">By Richard Li and Archit
Shah</span></p><span style="color: red">&lt;/authorblurb&gt;</span><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="security-design-essentials" id="security-design-essentials"></a>Essentials</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;"><li class="listitem"><p><a class="xref" href="security-requirements" title="Security Requirements">OpenACS 4 Security Requirements</a></p></li></ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="security-design-intro" id="security-design-intro"></a>Introduction</h3></div></div></div><p>This document explains security model design for OpenACS 4. The
security system with the OpenACS core must authenticate users in
both secure and insecure environments. In addition, this subsystem
provides sessions on top of the stateless HTTP protocol. This
system also provides session level properties as a generic service
to the rest of the OpenACS.</p><p>The atoms used in the implementation:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p>Cookies: <a class="ulink" href="http://web.mit.edu/rfc/rfc2109.txt" target="_top">RFC 2109, HTTP
State Management Mechanism</a>
</p><p>Cookies provide client side state. They are used to identify the
user. Expiration of cookies is used to demark the end of a
session.</p>
</li><li class="listitem">
<p>SHA: <a class="ulink" href="http://csrc.nist.gov/fips/fip180-1.txt" target="_top">SHA-1</a>
</p><p>This secure hash algorithm enables us to digitally sign cookies
which guarantee that they have not been tampered with. It is also
used to hash passwords.</p>
</li><li class="listitem">
<p>SSL with server authentication: <a class="ulink" href="http://home.netscape.com/eng/ssl3/ssl-toc.html" target="_top">SSL
v3</a>
</p><p>SSL provides the client with a guarantee that the server is
actually the server it is advertised as being. It also provides a
secure transport.</p>
</li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="security-design-design" id="security-design-design"></a>Design</h3></div></div></div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="sessions" id="sessions"></a>Sessions</h4></div></div></div><p>A session is defined as a series of clicks in which no two
clicks are separated by more than some constant. This constant is
the parameter SessionTimeout. Using the expiration time on the
signatures of the signed cookies, we can verify when the cookie was
issued and determine if two requests are part of the same session.
It is important to note that the expiration time set in the cookie
protocol is not trusted. Only the time inserted by the signed
cookie mechanism is trusted.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="authentication" id="authentication"></a>Authentication</h4></div></div></div><p>Two levels of access can be granted: insecure and secure. This
grant lasts for the remainder of the particular session. Secure
authentication tokens are only issued over secured connections.</p><p>One consequence of this security design is that secure tokens
are not automatically issued to users who authenticate themselves
over insecure connections. This means that users will need to
reauthenticate themselves over SSL when performing some action that
requires secure authentication.</p><p>Although this makes the site less user friendly, this design
significantly increases the security of the system because this
insures that the authentication tokens presented to a secure
section of the web site were not sniffed. The system is not
entirely secure, since the actual authentication password can be
sniffed from the system, after which the sniffer can apply for a
secure authentication token. However, the basic architecture here
lays the foundation for a secure system and can be easily adapted
to a more secure authentication system by forcing all logins to
occur over HTTPS.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="authentication-details" id="authentication-details"></a>Details</h4></div></div></div><p>The authentication system issues up to four signed cookies (see
below), with each cookie serving a different purpose. These cookies
are:</p><div class="informaltable"><table class="informaltable" cellspacing="0" border="1">
<colgroup>
<col><col><col><col>
</colgroup><tbody>
<tr>
<td><span class="strong"><strong>name</strong></span></td><td><span class="strong"><strong>value</strong></span></td><td><span class="strong"><strong>max-age</strong></span></td><td><span class="strong"><strong>secure?</strong></span></td>
</tr><tr>
<td>ad_session_id</td><td>session_id,user_id</td><td>SessionTimeout</td><td>no</td>
</tr><tr>
<td>ad_user_login</td><td>user_id</td><td>Infinity</td><td>no</td>
</tr><tr>
<td>ad_user_login_secure</td><td>user_id,random</td><td>Infinity</td><td>yes</td>
</tr><tr>
<td>ad_secure_token</td><td>session_id,user_id,random</td><td>SessionLifetime</td><td>yes</td>
</tr>
</tbody>
</table></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p>ad_session_id</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>reissued on any hit separated by more than SessionRenew seconds
from the previous hit that received a cookie</p></li><li class="listitem"><p>is valid only for SessionTimeout seconds</p></li><li class="listitem"><p>is the canonical source for the session ID in ad_conn</p></li>
</ul></div>
</li><li class="listitem">
<p>ad_user_login</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;"><li class="listitem"><p>is used for permanent logins</p></li></ul></div>
</li><li class="listitem">
<p>ad_user_login_secure</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>is used for permanent secure logins</p></li><li class="listitem"><p>contains random garbage (ns_time) to prevent attack against the
secure hash</p></li>
</ul></div>
</li><li class="listitem">
<p>ad_secure_token</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>is a session-level cookie from the browser&#39;s standpoint</p></li><li class="listitem"><p>its signature expires in SessionLifetime seconds</p></li><li class="listitem"><p>contains random garbage (ns_time) to prevent attack against the
secure hash</p></li><li class="listitem"><p>user_id is extraneous</p></li>
</ul></div>
</li>
</ul></div>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="authentication-process" id="authentication-process"></a>Authentication Process</h4></div></div></div><p>The Tcl function (<code class="computeroutput">sec_handler</code>) is called by the request
processor to authenticate the user. It first checks the
<code class="computeroutput">ad_session_id</code> cookie. If there
is no valid session in progress, a new session is created with
<code class="computeroutput">sec_setup_session</code>. If the user
has permanent login cookies (<code class="computeroutput">ad_user_login</code> and <code class="computeroutput">ad_user_login_secure</code>), then they are looked
at to determine what user the session should be authorized as.
Which cookie is examined is determined by whether or not the
request is on a secure connection. If neither cookie is present,
then a session is created without any authentication. If the
<code class="computeroutput">ad_session_id</code> cookie is valid,
the user_id and session_id are pulled from it and put into
ad_conn.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="secure-connections" id="secure-connections"></a>Authenticating Secure Connections</h4></div></div></div><p>Secure connections are authenticated slightly differently. The
function <code class="computeroutput">ad_secure_conn_p</code> is
used to determine whether or not the URL being accessed is requires
a secure login. The function simply checks if the location begins
with "https". (This is safe because the location is set
during the server initialization.)</p><p>If secure authentication is required, the <code class="computeroutput">ad_secure_token</code> cookie is checked to make
sure its data matches the data stored in <code class="computeroutput">ad_session_id</code>. This is true for all pages
except those that are part of the login process. On these pages,
the user can not yet have received the appropriate <code class="computeroutput">ad_secure_token</code> cookie, so no check against
it is performed. The set of pages that skip that processing are
determined by determined by <code class="computeroutput">ad_login_page</code>. Since the <code class="computeroutput">ad_secure_token</code> cookie is a session cookie,
it is deleted by the browser when the browser exits. Since an
attacker could conceivably store the secure cookie in a replay
attack (since expiration date is not validated), the data in the
secure cookie is never used to set any data in ad_conn; user_id and
session_id is set from the ad_session_id cookie.</p><p>It is important to note that the integrity of secure
authentication rests on the two Tcl function <code class="computeroutput">ad_secure_conn_p</code> and <code class="computeroutput">ad_login_page</code>. If <code class="computeroutput">ad_secure_conn_p</code> is false, secure
authentication is not required. If <code class="computeroutput">ad_login_page</code> is false, secure
authentication is not required.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="login-process" id="login-process"></a>Login Process</h4></div></div></div><p>The Tcl function <code class="computeroutput">ad_user_login</code> does two things. First it
performs the appropriate manipulation of the permanent login
cookies, and then it updates the current session to reflect the new
user_id. The manipulation of the permanent login cookies is based
on 3 factors:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>previous login: other user, same user</p></li><li class="listitem"><p>permanent: was a permanent login requested?</p></li><li class="listitem"><p>secure: is this a secure connection?</p></li>
</ul></div><p>Both the secure and insecure permanent login cookie can have one
of three actions taken on it:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>set: cookie with no expiration is set</p></li><li class="listitem"><p>delete: set to "" with max age of 0, so it is expired
immediately</p></li><li class="listitem"><p>nothing: if the cookie is present, it remains</p></li>
</ul></div><p>The current state of the permanent login cookies is not taken
into account when determining the appropriate action.</p><div class="informaltable"><table class="informaltable" cellspacing="0" border="1">
<colgroup>
<col><col><col><col><col>
</colgroup><tbody>
<tr>
<td><span class="strong"><strong>previous login
state</strong></span></td><td><span class="strong"><strong>permanent login
requested</strong></span></td><td><span class="strong"><strong>secure
connection</strong></span></td><td><span class="strong"><strong>action on
insecure</strong></span></td><td><span class="strong"><strong>action on
secure</strong></span></td>
</tr><tr>
<td>other</td><td>y</td><td>y</td><td>set</td><td>set</td>
</tr><tr>
<td>same</td><td>y</td><td>y</td><td>set</td><td>set</td>
</tr><tr>
<td>other</td><td>y</td><td>n</td><td>set</td><td>delete</td>
</tr><tr>
<td>same</td><td>y</td><td>n</td><td>set</td><td>nothing</td>
</tr><tr>
<td>same</td><td>n</td><td>y</td><td>nothing</td><td>delete</td>
</tr><tr>
<td>other</td><td>n</td><td>y</td><td>delete</td><td>delete</td>
</tr><tr>
<td>other</td><td>n</td><td>n</td><td>delete</td><td>delete</td>
</tr><tr>
<td>same</td><td>n</td><td>n</td><td>delete</td><td>delete</td>
</tr>
</tbody>
</table></div><p>
<code class="computeroutput">ad_user_login</code>
calls<code class="computeroutput">sec_setup_session</code> which
actually calls <code class="computeroutput">sec_generate_session_id_cookie</code> to generate
the new cookie with refer to the appropriate user_id. If the
connection is secure the <code class="computeroutput">ad_secure_token</code> cookie is generated by a
call to <code class="computeroutput">sec_generate_secure_token_cookie</code>. This
function is only called from <code class="computeroutput">sec_setup_session</code>. Only <code class="computeroutput">sec_handler</code> and <code class="computeroutput">sec_setup_session</code> call <code class="computeroutput">sec_generate_session_id_cookie</code>.</p><p>
<code class="computeroutput">ad_user_logout</code> logs the user
out by deleting all 4 cookies that are used by the authentication
system.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="session-creation" id="session-creation"></a>Session Creation</h4></div></div></div><p>The creation and setup of sessions is handled in <code class="computeroutput">sec_setup_session</code>, which is called either
to create a new session from <code class="computeroutput">sec_handler</code> or from <code class="computeroutput">ad_user_login</code> when there is a change in
authorization level. The session management code must do two
things: insure that session-level data does not float between
users, and update the users table which has columns for
<code class="computeroutput">n_sessions</code>, <code class="computeroutput">last_visit</code>, and <code class="computeroutput">second_to_last_visit</code>.</p><p>If there is no session already setup on this hit, a new session
is created. This happens when <code class="computeroutput">sec_setup_session</code> is called from
<code class="computeroutput">sec_handler</code>. If the login is
from a user to another user, a new session is created, otherwise,
the current session is continued, simply with a higher
authorization state. This allows for data associated with a session
to be carried over when a user logs in.</p><p>The users table is updated by <code class="computeroutput">sec_update_user_session_info</code> which is
called when an existing session is assigned a non-zero user_id, or
when a session is created with a non-zero user_id.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="passwords" id="passwords"></a>Passwords</h4></div></div></div><p>
<code class="computeroutput">ad_user_login</code> assumes a
password check has already been performed (this will change in the
future). The actual check is done by <code class="computeroutput">ad_check_password</code>. The database stores a
salt and a hash of the password concatenated with the salt.
Updating the password (<code class="computeroutput">ad_change_password</code>) simply requires getting
a new salt (ns_time) concatenating and rehashing. Both the salt and
the hashed password field are updated.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="performance-enhancements" id="performance-enhancements"></a>Performance Enhancements</h4></div></div></div><p>A session is labeled by a session_id sequence. Creating a
session merely requires incrementing the session_id sequence. We do
two things to improve the performance of this process. First,
sequence values are precomputed and cached in the Oracle SGA. In
addition, sequence values are incremented by 100 with each call to
nextval. These sequences values are cached on a per-thread basis.
The cost of allocating a new session thus becomes the cost of
executing an incr Tcl command per thread. This minimizes lock
contention for the session ID sequence and also minimizes the
number of DB requests, since each thread can allocate 100 sessions
before requiring another DB hit. This cache works by keeping two
counters: <code class="computeroutput">tcl_max_value</code> and
<code class="computeroutput">tcl_current_sequence_id</code>. When
<code class="computeroutput">tcl_current_sequence_id</code> is
greater than <code class="computeroutput">tcl_max_value</code> a
new value is requested from the db and <code class="computeroutput">tcl_max_value</code> is incremented by 100. This
is done on a per-thread basis so that no locking is required.</p><p>In addition, two procedures are dynamically generated at startup
in <code class="computeroutput">security-init.tcl</code>. These two
procedures use <code class="computeroutput">ad_parameter</code> to
obtain the constant value of a given parameter; these values are
used to dynamically generate a procedure that returns a constant.
This approach avoids (relatively) expensive calls to <code class="computeroutput">ad_parameter</code> in <code class="computeroutput">sec_handler</code>. The impact of this approach is
that these parameters cannot be dynamically changed at runtime and
require a server restart.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="session-properties" id="session-properties"></a>Session Properties</h4></div></div></div><p>Session properties are stored in a single table that maps
session IDs to named session properties and values. This table is
periodically purged. For maximum performance, the table is created
with nologging turned on and new extents are allocated in 50MB
increments to reduce fragmentation. This table is swept
periodically by <code class="computeroutput">sec_sweep_session</code> which removes sessions
whose first hit was more than SessionLifetime seconds (1 week by
default) ago. Session properties are removed through that same
process with cascading delete.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="secure-session-properties" id="secure-session-properties"></a>Secure Session Properties</h4></div></div></div><p>Session properties can be set as secure. In this case,
<code class="computeroutput">ad_set_client_property</code> will
fail if the connection is not secure. <code class="computeroutput">ad_get_client_property</code> will behave as if
the property had not been set if the property was not set
securely.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="digital-signatures" id="digital-signatures"></a>Digital Signatures &amp; Signed
Cookies</h4></div></div></div><p>Signed cookies are implemented using the generic secure digital
signature mechanism. This mechanism guarantees that the user can
not tamper with (or construct a value of his choice) without
detection. In addition, it provides the optional facility of timing
out the signature so it is valid for only a certain period of time.
This works by simply including an expiration time as part of the
value that is signed.</p><p>The signature produced by <code class="computeroutput">ad_sign</code> is the Tcl list of <code class="computeroutput">token_id,expire_time,hash</code>, where hash =
SHA1(value,token_id,expire_time,secret_token). The secret_token is
a forty character randomly generated string that is never sent to
any user agent. The scheme consists of one table:</p><pre class="programlisting">

create table secret_tokens (
    token_id                    integer
                                constraint secret_tokens_token_id_pk primary key,
    token                       char(40),
    token_timestamp             sysdate
);

</pre><p>
<code class="computeroutput">ad_verify_signature</code> takes a
value and a signature and verifies that the signature was generated
using that value. It works simply by taking the token_id and
expire_time from the signature, and regenerating the hash using the
supplied value and the secret_token corresponding to the token_id.
This regenerated hash is compared to the hash extracted from the
supplied signature. The expire_time is also verified to be greater
than the current time. An expire_time of 0 is also allowed, as it
indicates no time out on the signature.</p><p>Signed cookies include in their RFC2109 VALUE field a Tcl list
of the value and the signature. In addition to the expiration of
the digital signature, RFC 2109 specifies an optional max age that
is returned to the client. For most cookies, this max age matches
the expiration date of the cookie&#39;s signature. The standard
specifies that when the max age is not included, the cookie should
be "discarded when the user agent exits." Because we can
not trust the client to do this, we must specify a timeout for the
signature. The SessionLifetime parameter is used for this purpose,
as it represents the maximum possible lifetime of a single
session.</p><p>RFC 2109 specifies this optional "secure" parameter
which mandates that the user-agent use "secure means" to
contact the server when transmitting the cookie. If a secure cookie
is returned to the client over https, then the cookie will never be
transmitted over insecure means.</p><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="signature-performance" id="signature-performance"></a>Performance</h5></div></div></div><p>Performance is a key goal of this implementation of signed
cookies. To maximize performance, we will use the following
architecture. At the lowest level, we will use the <code class="computeroutput">secret_tokens</code> table as the canonical set of
secret tokens. This table is necessary for multiple servers to
maintain the same set of secret tokens. At server startup, a random
subset of these secret tokens will be loaded into an ns_cache
called <code class="computeroutput">secret_tokens</code>. When a
new signed cookie is requested, a random token_id is returned out
of the entire set of cached token_ids. In addition, a
thread-persistent cache called tcl_secret_tokens is maintained on a
per-thread basis.</p><p>Thus, the L2 ns_cache functions as a server-wide LRU cache that
has a minimum of 100 tokens in it. The cache has a dual
purpose:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>
<span class="strong"><strong>LRU cache</strong></span> Note that
cache misses will only occur in the multiple server case, where a
user agent may have a signature guaranteed by a secret token issued
by another server in the cluster.</p></li><li class="listitem"><p>
<span class="strong"><strong>signature cache</strong></span>
Since the cache always maintains a minimum of 100 (set by a
parameter) tokens populated at startup, it can be used to provide a
random token for signature purposes.</p></li>
</ul></div><p>The per-thread cache functions as an L1 cache that
indiscriminately caches all secret tokens. Note that this is
<span class="strong"><strong>not</strong></span> an LRU cache
because there is no cache eviction policy per se -- the cache is
cleared when the thread is destroyed by AOLserver.</p>
</div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="signature-security" id="signature-security"></a>Security</h5></div></div></div><p>Storing information on a client always presents an additional
security risk.</p><p>Since we are only validating the information and not trying to
protect it as a secret, we don&#39;t use salt. Cryptographic salt
is useful if you are trying to protect information from being read
(e.g., hashing passwords).</p>
</div>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="external-ssl" id="external-ssl"></a>External SSL</h4></div></div></div><p>External SSL mechanisms (firewall, dedicated hardware, etc.) can
be used by creating two pools of AOLservers. In one pool the
servers should be configured with the location parameter of nssock
module set to "https://yourservername". The servers in
the other pool are configured as normal. The external SSL agent
should direct SSL queries to the pool of secure servers, and it
should direct non-SSL queries to the insecure servers.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="PRNG" id="PRNG"></a>PRNG</h4></div></div></div><p>The pseudorandom number generator depends primarily on ns_rand,
but is also seeded with ns_time and the number of page requests
served since the server was started. The PRNG takes the
SHA1(seed,ns_rand,ns_time,requests,clicks), and saves the first 40
bits as the seed for the next call to the PRNG in a
thread-persistent global variable. The remaining 120 bits are
rehashed to produce 160 bits of output.</p>
</div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="security-design-api" id="security-design-api"></a>API</h3></div></div></div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="login-password-api" id="login-password-api"></a>Login/Password</h4></div></div></div><p>
<span class="strong"><strong>ad_user_login <span class="emphasis"><em>user_id</em></span>
</strong></span> Logs the user in
as user <span class="emphasis"><em>user_id</em></span>. Optional
forever flag determines whether or not permanent cookies are
issued.</p><p>
<span class="strong"><strong>ad_user_logout</strong></span> Logs
the user out.</p><p>
<span class="strong"><strong>ad_check_password <span class="emphasis"><em>user_id</em></span><span class="emphasis"><em>password</em></span>
</strong></span> returns 0 or
1.</p><p><span class="strong"><strong>ad_change_password <span class="emphasis"><em>user_id</em></span><span class="emphasis"><em>new
password</em></span>
</strong></span></p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="signature-api" id="signature-api"></a>Digital Signatures and Signed Cookies</h4></div></div></div><p>
<span class="strong"><strong>ad_sign <span class="emphasis"><em>value</em></span>
</strong></span> Returns the
digital signature of this value. Optional parameters allow for the
specification of the <span class="emphasis"><em>secret</em></span>
used, the <span class="emphasis"><em>token_id</em></span> used and
the <span class="emphasis"><em>max_age</em></span> for the
signature. <span class="strong"><strong>ad_verify_signature
<span class="emphasis"><em>value</em></span><span class="emphasis"><em>signature</em></span>
</strong></span>Returns 1 or 0
indicating whether or not the signature matches the value
specified. The <span class="emphasis"><em>secret</em></span>
parameter allows for specification of a different secret token to
be used.</p><p>
<span class="strong"><strong>ad_set_signed_cookie <span class="emphasis"><em>name</em></span><span class="emphasis"><em>data</em></span>
</strong></span> Sets a signed
cookie <span class="emphasis"><em>name</em></span> with value
<span class="emphasis"><em>data</em></span>.</p><p>
<span class="strong"><strong>ad_get_signed_cookie <span class="emphasis"><em>name</em></span>
</strong></span> Gets the signed
cookie <span class="emphasis"><em>name</em></span>. It raises an
error if the cookie has been tampered with, or if its expiration
time has passed.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="session-property-api" id="session-property-api"></a>Session Properties</h4></div></div></div><p>
<span class="strong"><strong>ad_set_client_property <span class="emphasis"><em>module</em></span><span class="emphasis"><em>name</em></span><span class="emphasis"><em>data</em></span>
</strong></span> Sets a session
property with <span class="emphasis"><em>name</em></span> to value
<span class="emphasis"><em>data</em></span> for the module
<span class="emphasis"><em>module</em></span>. The optional secure
flag specifies the property should only be set if the client is
authorized for secure access (<code class="computeroutput">ad_secure_conn_p</code> is true). There is also an
optional <span class="emphasis"><em>session_id</em></span> flag to
access data from sessions other than the current one.</p><p>
<span class="strong"><strong>ad_get_client_property <span class="emphasis"><em>module</em></span><span class="emphasis"><em>name</em></span><span class="emphasis"><em>data</em></span>
</strong></span> Gets a session
property with <span class="emphasis"><em>name</em></span> to for
the module <span class="emphasis"><em>module</em></span>. The
optional secure flag specifies the property should only be
retrieved if the client is authorized for secure access
(<code class="computeroutput">ad_secure_conn_p</code> is true).
There is also an optional <span class="emphasis"><em>session_id</em></span> flag to access data from
sessions other than the current one.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="parameters" id="parameters"></a>Parameters</h4></div></div></div><p>
<span class="strong"><strong>SessionTimeout</strong></span> the
maximum time in seconds (default 1200) between requests that are
part of the same session</p><p>
<span class="strong"><strong>SessionRenew</strong></span> the
time in seconds (default 300) between reissue of the session
cookie. The minimum time that can pass after a session cookie is
issued and before it is rejected is (SessionTimeout -
SessionRenew). This parameter is used so that only one session_id
cookie is set on a single page even if there are multiple images
that are being downloaded.</p><p>
<span class="strong"><strong>SessionLifetime</strong></span> the
maximum possible lifetime of a session in seconds (default 604800 =
7 days)</p><p>
<span class="strong"><strong>NumberOfCachedSecretTokens</strong></span> the
number of secret tokens to cache. (default 100)</p>
</div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="security-design-future" id="security-design-future"></a>Future Improvements</h3></div></div></div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="PRNG-impl" id="PRNG-impl"></a>PRNG
implementation</h4></div></div></div><p>The pseudorandom number generator used in the OpenACS is
cryptographically weak, and depends primarily on the randomness of
the <code class="computeroutput">ns_rand</code> function for its
randomness. The implementation of the PRNG could be substantially
improved.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="ad_user_login" id="ad_user_login"></a><code class="computeroutput">ad_user_login</code>
</h4></div></div></div><p>Add a password argument. It is non-optimal to make the default
behavior to assume that the password was provided.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="secret-tokens" id="secret-tokens"></a>Secret Tokens</h4></div></div></div><p>The secret tokens pool is currently static. Ideally, this pool
should be changed on a random but regular basis, and the number of
secret_tokens increased as the number of users come to the web
site.</p><p>Since the security of the entire system depends on the secret
tokens pool, access to the secret tokens table should be restricted
and accessible via a strict PL/SQL API. This can be done by
revoking standard SQL permissions on the table for the AOLserver
user and giving those permissions to a PL/SQL package.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="robots" id="robots"></a>Robots</h4></div></div></div><p>Deferring session to creation until the second hit from a
browser seems to be a good way of preventing a lot of overhead
processing for robots. If we do this, send cookie on first hit to
test if cookies are accepted, then actually allocate on second hit.
To preserve a record of the first hit of the session, just include
any info about that first hit in the probe cookie sent. Look at how
usca_p (user session cookie attempted) is used in OpenACS 3.x
ecommerce.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="client-property-future" id="client-property-future"></a>Client properties</h4></div></div></div><p>Currently there are only session properties. Because sessions
have a maximum life, properties have a maximum life. It would be
nice to expand the interface to allow for more persistent
properties. In the past, there was a sec_browser_properties table
that held permanent properties about each unique visitor (for
logged in users, these are just user properties). This was
unscalable because there was no way to delete these properties, and
the table tended to grow to millions of rows. It would be nice to
view browser and session properties as two types of client
properties, but with different deletion patterns (there are other
differences as well, browser properties can be shared between
concurrent sessions). The applications should have control over the
deletion patterns, but should not be able to ignore the amount of
data stored.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="session-information" id="session-information"></a>Session information</h4></div></div></div><p>It would be nice to keep some info about sessions: first hit,
last hit, and URLs visited come to mind. Both logging and API for
accessing this info would be nice. WimpyPoint is an application
that already wants to use this information to show how long the
current presentation has been viewed. The right way may be to put
the session_id into the access log and use log analyzers (leaving
it in server memory for applications to access). Putting it into
the database at all is probably too big a hammer. Certainly putting
it into the database on every hit is too big a hammer.</p>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="cookieless-sessions" id="cookieless-sessions"></a>Cookieless Sessions</h4></div></div></div><p>Two trends drive the requirement for removing cookie dependence.
WAP browsers that do not have cookies, and publc perceptions of
cookies as an invasion of privacy. The rely on the cookies
mechanism in HTTP to distinguish one request from the next, and we
trust it to force requests from the same client to carry the same
cookie headers. The same thing can be accomplished by personalizing
the URLs sent back to each browser. If we can store an identifier
in the URL and get it back on the next hit, the sessions system
would continue to work.</p><p>Problems that arise:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>URL sharing could be dangerous. If I happen to be browsing
Amazon while logged in and I email a friend, he could conceivably
receive it and follow it before my session has expired, gaining all
of the privileges I had.</p></li><li class="listitem"><p>User-entered URLs are harder to handler. If a user is in the
middle of a session and then types in the URL of some page, he
could be kicked out of his session.</p></li>
</ul></div><p>Both of these problems can be mitigated by doing detection of
cookie support (see the section on robot detection). To help deal
with the first problem, One could also make the restriction that
secure sessions are only allowed over cookied HTTP.</p>
</div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="security-design-vulnerability" id="security-design-vulnerability"></a>Vulnerability Analysis</h3></div></div></div><p>This section is not meant to be a comprehensive analysis of the
vulnerabilities of the security system. Listed below are possible
attack points for the system; these vulnerabilities are currently
theoretical in nature. The major cryptographic vulnerability of the
system stems from the pseudorandom nature of the random number
generators used in the system.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>
<span class="strong"><strong>Cryptographically weak
PRNG</strong></span> see above.</p></li><li class="listitem"><p>
<span class="strong"><strong>Dependence on <code class="computeroutput">sample</code> SQL command</strong></span> The list
of random token that are placed in the secret tokens cache is
randomly chosen by the Oracle <code class="computeroutput">sample</code> command. This command may not be
entirely random, so predicting the contents of the secret tokens
cache may not be as difficult as someone may anticipate.</p></li><li class="listitem"><p>
<span class="strong"><strong>Dependence on <code class="computeroutput">ns_rand</code>
</strong></span> The actual token
that is chosen from the cache to be used is chosen by a call to
<code class="computeroutput">ns_rand</code>.</p></li><li class="listitem"><p>
<span class="strong"><strong><code class="computeroutput">ad_secure_conn_p</code></strong></span> As
discussed above, the security of the secure sessions authentication
system is dependent upon this function.</p></li>
</ul></div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="security-requirements" leftLabel="Prev" leftTitle="Security Requirements"
			rightLink="security-notes" rightLabel="Next" rightTitle="Security Notes"
			homeLink="index" homeLabel="Home" 
			upLink="kernel-doc" upLabel="Up"> 
		    