
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Programming with AOLserver}</property>
<property name="doc(title)">Programming with AOLserver</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="object-identity" leftLabel="Prev"
		    title="
Chapter 11. Development Reference"
		    rightLink="form-builder" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="programming-with-aolserver" id="programming-with-aolserver"></a>Programming with AOLserver</h2></div></div></div><div class="authorblurb">
<p>By Michael Yoon, Jon Salz and Lars Pind.</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="programming-aolserver-global" id="programming-aolserver-global"></a>The <code class="computeroutput">global</code> command</h3></div></div></div><p>When using AOLserver, remember that there are effectively
<span class="emphasis"><em>two</em></span> types of global
namespace, not one:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>
<span class="emphasis"><em>Server</em></span>-global: As
you&#39;d expect, there is only one server-global namespace per
server, and variables set within it can be accessed by any Tcl code
running subsequently, in any of the server&#39;s threads. To
set/get server-global variables, use AOLserver 3's <a class="ulink" href="http://www.aolserver.com/docs/nsv.adp" target="_top">
<code class="computeroutput">nsv</code> API</a> (which
supersedes <code class="computeroutput">ns_share</code> from the
pre-3.0 API).</p></li><li class="listitem"><p>
<span class="emphasis"><em>Script</em></span>-global: Each Tcl
script (ADP, Tcl page, registered proc, filter, etc.) executing
within an AOLserver thread has its own global namespace. Any
variable set in the top level of a script is, by definition,
script-global, meaning that it is accessible only by subsequent
code in the same script and only for the duration of the current
script execution.</p></li>
</ol></div><p>The Tcl built-in command <a class="ulink" href="http://aolserver.com/docs/tcl/tcl8.3/TclCmd/global.htm" target="_top"><code class="computeroutput">global</code></a> accesses
script-global, <span class="emphasis"><em>not</em></span>
server-global, variables from within a procedure. This distinction
is important to understand in order to use <code class="computeroutput">global</code> correctly when programming
AOLserver.</p><p>Also, AOLserver purges all script-global variables in a thread
(i.e., Tcl interpreter) between HTTP requests. If it didn&#39;t,
that would affect (and complicate) our use of script-global
variables dramatically, which would then be better described as
<span class="emphasis"><em>thread</em></span>-global variables.
Given AOLserver&#39;s behaviour, however, "script-global"
is a more appropriate term.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="programming-aolserver-sched-procs" id="programming-aolserver-sched-procs"></a>Threads and Scheduled
Procedures</h3></div></div></div><p>
<code class="computeroutput">ns_schedule_proc</code> and
<code class="computeroutput">ad_schedule_proc</code> each take a
<code class="computeroutput">-thread</code> flag to cause a
scheduled procedure to run asychronously, in its own thread. It
almost always seems like a good idea to specify this switch, but
there&#39;s a problem.</p><p>It turns out that whenever a task scheduled with <code class="computeroutput">ns_schedule_proc -thread</code> or <code class="computeroutput">ad_schedule_proc -thread t</code> is run,
AOLserver creates a brand new thread and a brand new interpreter,
and reinitializes the procedure table (essentially, loads all
procedures that were created during server initialization into the
new interpreter). This happens <span class="emphasis"><em>every
time</em></span> the task is executed - and it is a very expensive
process that should not be taken lightly!</p><p>The moral: if you have a lightweight scheduled procedure which
runs frequently, don&#39;t use the <code class="computeroutput">-thread</code> switch.</p><div class="blockquote"><blockquote class="blockquote"><p><span class="emphasis"><em>Note also that thread is initialized
with a copy of what was installed during server startup, so if the
procedure table have changed since startup (e.g. using the
<a class="link" href="apm-design" title="Package Manager Design">APM</a> watch facility), that will not be
reflected in the scheduled thread.</em></span></p></blockquote></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="programming-aolserver-return" id="programming-aolserver-return"></a>Using <code class="computeroutput">return</code>
</h3></div></div></div><p>The <code class="computeroutput">return</code> command in Tcl
returns control to the caller procedure. This definition allows
nested procedures to work properly. However, this definition also
means that nested procedures cannot use <code class="computeroutput">return</code> to end an entire thread. This
situation is most common in exception conditions that can be
triggered from inside a procedure e.g., a permission denied
exception. At this point, the procedure that detects invalid
permission wants to write an error message to the user, and
completely abort execution of the caller thread. <code class="computeroutput">return</code> doesn&#39;t work, because the
procedure may be nested several levels deep. We therefore use
<a class="ulink" href="/api-doc/proc-view?proc=ad%5fscript%5fabort" target="_top"><code class="computeroutput">ad_script_abort</code></a> to abort the remainder
of the thread. Note that using <code class="computeroutput">return</code> instead of <code class="computeroutput">ad_script_abort</code> may raise some security
issues: an attacker could call a page that performed some DML
statement, pass in some arguments, and get a permission denied
error -- but the DML statement would still be executed because the
thread was not stopped. Note that <code class="computeroutput">return -code return</code> can be used in
circumstances where the procedure will only be called from two
levels deep.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="programming-aolserver-more-values" id="programming-aolserver-more-values"></a>Returning More Than One
Value From a Function</h3></div></div></div><p>Many functions have a single return value. For instance,
<a class="ulink" href="/api-doc/proc-view?proc=util_email_valid_p" target="_top"><code class="computeroutput">util_email_valid_p</code></a> returns a number: 1
or 0. Other functions need to return a composite value. For
instance, consider a function that looks up a user&#39;s name and
email address, given an ID. One way to implement this is to return
a three-element list and document that the first element contains
the name, and the second contains the email address. The problem
with this technique is that, because Tcl does not support
constants, calling procedures that returns lists in this way
necessitates the use of magic numbers, e.g.:</p><pre class="programlisting">
set user_info [ad_get_user_info $user_id]
set first_name [lindex $user_info 0]
set email [lindex $user_info 1]
</pre><p>AOLserver/Tcl generally has three mechanisms that we like, for
returning more than one value from a function. When to use which
depends on the circumstances.</p><p>Using Arrays and Pass-By-Value</p><p>The one we generally prefer is returning an <a class="ulink" href="http://aolserver.com/docs/tcl/tcl8.3/TclCmd/array.htm#M8" target="_top"><code class="computeroutput">array
get</code></a>-formatted list. It has all the nice properties of
pass-by-value, and it uses Tcl arrays, which have good native
support.</p><pre class="programlisting">
ad_proc ad_get_user_info { user_id } {
    db_1row user_info { select first_names, last_name, email from users where user_id = :user_id }
    return [list \
        name "$first_names $last_name" \
    email $email \
    namelink "&lt;a href=\"/shared/community-member?user_id=[ns_urlencode $user_id]\"&gt;$first_names $last_name&lt;/a&gt;" \
    emaillink "&lt;a href=\"mailto:$email\"&gt;$email&lt;/a&gt;"]
}

array set user_info [ad_get_user_info $user_id]

doc_body_append "$user_info(namelink) ($user_info(emaillink))"
</pre><p>You could also have done this by using an array internally and
using <code class="computeroutput">array get</code>:</p><pre class="programlisting">

ad_proc ad_get_user_info { user_id } {
    db_1row user_info { select first_names, last_name, email from users where user_id = :user_id }
    set user_info(name) "$first_names $last_name"
    set user_info(email) $email
    set user_info(namelink) "&lt;a href=\"/shared/community-member?user_id=[ns_urlencode $user_id]\"&gt;$first_names $last_name&lt;/a&gt;"
    set user_info(emaillink) "&lt;a href=\"mailto:$email\"&gt;$email&lt;/a&gt;"
    return [array get user_info]
}

</pre><p>Using Arrays and Pass-By-Reference</p><p>Sometimes pass-by-value incurs too much overhead, and you&#39;d
rather pass-by-reference. Specifically, if you&#39;re writing a
proc that uses arrays internally to build up some value, there are
many entries in the array, and you&#39;re planning on iterating
over the proc many times. In this case, pass-by-value is expensive,
and you&#39;d use pass-by-reference.</p><div class="blockquote"><blockquote class="blockquote"><p><span class="emphasis"><em>The transformation of the array into
a list and back to an array takes, in our test environment,
approximately 10 microseconds per entry of 100 character&#39;s
length. Thus you can process about 100 entries per milisecond. The
time depends almost completely on the number of entries, and almost
not at all on the size of the entries.</em></span></p></blockquote></div><p>You implement pass-by-reference in Tcl by taking the name of an
array as an argument and <code class="computeroutput">upvar</code>
it.</p><pre class="programlisting">

ad_proc ad_get_user_info { 
    -array:required
    user_id 
} {
    upvar $array user_info
    db_1row user_info { select first_names, last_name, email from users where user_id = :user_id }
    set user_info(name) "$first_names $last_name"
    set user_info(email) $email
    set user_info(namelink) "&lt;a href=\"/shared/community-member?user_id=[ns_urlencode $user_id]\"&gt;$first_names $last_name&lt;/a&gt;"
    set user_info(emaillink) "&lt;a href=\"mailto:$email\"&gt;$email&lt;/a&gt;"
}

ad_get_user_info -array user_info $user_id

doc_body_append "$user_info(namelink) ($user_info(emaillink))"

</pre><p>We prefer pass-by-value over pass-by-reference.
Pass-by-reference makes the code harder to read and debug, because
changing a value in one place has side effects in other places.
Especially if have a chain of <code class="computeroutput">upvar</code>s through several layers of the call
stack, you&#39;ll have a hard time debugging.</p><p>Multisets: Using <code class="computeroutput">ns_set</code>s and
Pass-By-Reference</p><p>An array is a type of <span class="emphasis"><em>set</em></span>, which means you can&#39;t have
multiple entries with the same key. Data structures that can have
multiple entries for the same key are known as a <span class="emphasis"><em>multiset</em></span> or <span class="emphasis"><em>bag</em></span>.</p><p>If your data can have multiple entries with the same key, you
should use the AOLserver built-in <a class="ulink" href="http://www.aolserver.com/docs/tcldev/tapi-120.htm#197598" target="_top"><code class="computeroutput">ns_set</code></a>. You can also
do a case-insensitive lookup on an <code class="computeroutput">ns_set</code>, something you can&#39;t easily do
on an array. This is especially useful for things like HTTP
headers, which happen to have these exact properties.</p><p>You always use pass-by-reference with <code class="computeroutput">ns_set</code>s, since they don&#39;t have any
built-in way of generating and reconstructing themselves from a
string representation. Instead, you pass the handle to the set.</p><pre class="programlisting">

ad_proc ad_get_user_info {
    -set:required
    user_id
} {
    db_1row user_info { select first_names, last_name, email from users where user_id = :user_id }
    ns_set put $set name "$first_names $last_name"
    ns_set put $set email $email
    ns_set put $set namelink "&lt;a href=\"/shared/community-member?user_id=[ns_urlencode $user_id]\"&gt;$first_names $last_name&lt;/a&gt;"
    ns_set put $set emaillink "&lt;a href=\"mailto:$email\"&gt;$email&lt;/a&gt;"
}

set user_info [ns_set create]
ad_get_user_info -set $user_info $user_id

doc_body_append "[ns_set get $user_info namelink] ([ns_set get $user_info emaillink])"

</pre><p>We don&#39;t recommend <code class="computeroutput">ns_set</code> as a general mechanism for passing
sets (as opposed to multisets) of data. Not only do they inherently
use pass-by-reference, which we dis-like, they&#39;re also somewhat
clumsy to use, since Tcl doesn&#39;t have built-in syntactic
support for them.</p><p>Consider for example a loop over the entries in a <code class="computeroutput">ns_set</code> as compared to an array:</p><pre class="programlisting">

# ns_set variant
set size [ns_set size $myset]
for { set i 0 } { $i &lt; $size } { incr i } {
    puts "[ns_set key $myset $i] = [ns_set value $myset $i]"
}

# array variant
foreach name [array names myarray] {
    puts "$myarray($name) = $myarray($name)"
}

</pre><p>And this example of constructing a value:</p><pre class="programlisting">

# ns_set variant
set myset [ns_set create]
ns_set put $myset foo $foo
ns_set put $myset baz $baz
return $myset

# array variant
return [list
    foo $foo
    baz $baz
]

</pre><p>
<code class="computeroutput">ns_set</code>s are designed to be
lightweight, so memory consumption should not be a problem.
However, when using <code class="computeroutput">ns_set get</code>
to perform lookup by name, they perform a linear lookup, whereas
arrays use a hash table, so <code class="computeroutput">ns_set</code>s are slower than arrays when the
number of entries is large.</p><div class="cvstag">($&zwnj;Id: programming-with-aolserver.xml,v 1.7.2.1
2017/06/17 10:28:29 gustafn Exp $)</div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="object-identity" leftLabel="Prev" leftTitle="Object Identity"
		    rightLink="form-builder" rightLabel="Next" rightTitle="Using Form Builder: building html
forms dynamically"
		    homeLink="index" homeLabel="Home" 
		    upLink="dev-guide" upLabel="Up"> 
		