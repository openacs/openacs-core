
<property name="context">{/doc/acs-core-docs {Documentation}} {Notifications}</property>
<property name="doc(title)">Notifications</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="tutorial-upgrades" leftLabel="Prev"
		    title="
Chapter 10. Advanced Topics"
		    rightLink="tutorial-hierarchical" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="tutorial-notifications" id="tutorial-notifications"></a>Notifications</h2></div></div></div><div class="authorblurb">
<p>by <a class="ulink" href="mailto:dave\@student.usyd.edu.au" target="_top">David Bell</a> and <a class="ulink" href="mailto:simon\@collaboraid.net" target="_top">Simon
Carstensen</a>
</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><p>The notifications package allows you to send notifications
through any defined communications medium (e.g. email, sms) upon
some event occuring within the system.</p><p>This tutorial steps through the process of integrating the
notifications package with your package.</p><p>First step is to create the notification types. To do this a
script similar to the one below needs to be loaded into Postgresql.
I create this script in a
package-name/sql/postgresql/package-name-notifications-init.sql
file. I then load this file from my create sql file. The following
code snippet is taken from Weblogger. It creates a
lars_blogger_notif notification type (which was created above).</p><pre class="programlisting">
    create function inline_0() returns integer as $$
    declare
            impl_id integer;
            v_foo   integer;
    begin
        -- the notification type impl
        impl_id := acs_sc_impl__new (
                      'NotificationType',
                      'lars_blogger_notif_type',
                      'lars-blogger'
        );

        v_foo := acs_sc_impl_alias__new (
                    'NotificationType',
                    'lars_blogger_notif_type',
                    'GetURL',
                    'lars_blogger::notification::get_url',
                    'TCL'
        );

        v_foo := acs_sc_impl_alias__new (
                    'NotificationType',
                    'lars_blogger_notif_type',
                    'ProcessReply',
                    'lars_blogger::notification::process_reply',
                    'TCL'
        );

        PERFORM acs_sc_binding__new (
                    'NotificationType',
                    'lars_blogger_notif_type'
        );

        v_foo:= notification_type__new (
                NULL,
                impl_id,
                'lars_blogger_notif',
                'Blog Notification',
                'Notifications for Blog',
                now(),
                NULL,
                NULL,
                NULL
        );

        -- enable the various intervals and delivery methods
        insert into notification_types_intervals
        (type_id, interval_id)
        select v_foo, interval_id
        from notification_intervals where name in ('instant','hourly','daily');

        insert into notification_types_del_methods
        (type_id, delivery_method_id)
        select v_foo, delivery_method_id
        from notification_delivery_methods where short_name in ('email');

        return (0);
    end;
    $$ language plpgsql;

    select inline_0();
    drop function inline_0();
    
</pre><p>You also need a drop script. This is untested for comptability
with the above script.</p><pre class="programlisting">
      -- \@author gwong\@orchardlabs.com,ben\@openforce.biz
      -- \@creation-date 2002-05-16
      --
      -- This code is newly concocted by Ben, but with significant concepts and code
      -- lifted from Gilbert's UBB forums. Thanks Orchard Labs.
      -- Lars and Jade in turn lifted this from gwong and ben.

create function inline_0 ()
returns integer as $$
declare
    row                             record;
begin
    for row in select nt.type_id
               from notification_types nt
               where nt.short_name in ('lars_blogger_notif_type','lars_blogger_notif')
    loop
        perform notification_type__delete(row.type_id);
    end loop;

    return null;
end;
$$ language plpgsql;

select inline_0();
drop function inline_0 ();

--
-- Service contract drop stuff was missing - Roberto Mello 
--

create function inline_0() returns integer as $$
declare
        impl_id integer;
        v_foo   integer;
begin

        -- the notification type impl
        impl_id := acs_sc_impl__get_id (
                      'NotificationType',               -- impl_contract_name
                      'lars_blogger_notif_type'         -- impl_name
        );

        PERFORM acs_sc_binding__delete (
                    'NotificationType',
                    'lars_blogger_notif_type'
        );

        v_foo := acs_sc_impl_alias__delete (
                    'NotificationType',                 -- impl_contract_name   
                    'lars_blogger_notif_type',          -- impl_name
                    'GetURL'                            -- impl_operation_name
        );

        v_foo := acs_sc_impl_alias__delete (
                    'NotificationType',                 -- impl_contract_name   
                    'lars_blogger_notif_type',          -- impl_name
                    'ProcessReply'                      -- impl_operation_name
        );

        select into v_foo type_id 
          from notification_types
         where sc_impl_id = impl_id
          and short_name = 'lars_blogger_notif';

        perform notification_type__delete (v_foo);

        delete from notification_types_intervals
         where type_id = v_foo 
           and interval_id in ( 
                select interval_id
                  from notification_intervals 
                 where name in ('instant','hourly','daily')
        );

        delete from notification_types_del_methods
         where type_id = v_foo
           and delivery_method_id in (
                select delivery_method_id
                  from notification_delivery_methods 
                 where short_name in ('email')
        );

        return (0);
end;
$$ language plpgsql;

select inline_0();
drop function inline_0();
    
</pre><p>The next step is to setup our notification creation. A new
notification must be added to the notification table for each blog
entry added. We do this using the notification::new procedure</p><pre class="programlisting">
        notification::new \
            -type_id [notification::type::get_type_id \
            -short_name lars_blogger_notif] \
            -object_id $blog(package_id) \
            -response_id $blog(entry_id) \
            -notif_subject $blog(title) \
            -notif_text $new_content
    
</pre><p>This code is placed in the tcl procedure that creates blog
entries, right after the entry gets created in the code. The
<code class="computeroutput">$blog(package_id)</code> is the
OpenACS object_id of the Weblogger instance to which the entry has
been posted to and the <code class="computeroutput">$new_content</code> is the content of the entry.
This example uses the package_id for the object_id, which results
in setting up notifications for all changes for blogger entries in
this package. However, if you instead used the blog_entry_id or
something like that, you could set up per-item notifications. The
forums packages does this -- you can look at it for an example.</p><p>The final step is to setup the notification subscription
process. In this example we want to let a user find out when a new
entry has been posted to the blog. To do this we put a link on the
blog that allows them to subscribe to notifications of new entries.
The notifications/requests-new page is very handy in this
situation.</p><p>Such a link can be created using the <code class="computeroutput">notification::display::request_widget</code>
proc:</p><pre class="programlisting">
    set notification_chunk [notification::display::request_widget \
        -type lars_blogger_notif \
        -object_id $package_id \
        -pretty_name [lars_blog_name] \
        -url [lars_blog_public_package_url] \
    ]
    
</pre><p>which will return something like</p><pre class="programlisting">
    You may &lt;a href="/notifications/request-new?..."&gt;request notification&lt;/a&gt; for Weblogger.
</pre><p>which can be readily put on the blog index page. The
<code class="computeroutput">pretty_name</code> parameter is what
appears at the end of the text returned (i.e. "... request
notification&lt;/a&gt; for pretty_name"), The <code class="computeroutput">url</code> parameter should be set to the address
we want the user to be redirected to after they have finished the
subscription process.</p><p>This should be all you need to implement a notification system.
For more examples look at the forums package.</p>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="tutorial-upgrades" leftLabel="Prev" leftTitle="Distributing upgrades of your
package"
		    rightLink="tutorial-hierarchical" rightLabel="Next" rightTitle="Hierarchical data"
		    homeLink="index" homeLabel="Home" 
		    upLink="tutorial-advanced" upLabel="Up"> 
		