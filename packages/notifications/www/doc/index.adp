<master>
<h2>Notifications Package</h2>
<hr><p>

<h2>The Idea</h2>

<blockquote>
<i>
Every program attempts to expand until it can read mail.<br>
Those programs which cannot so expand are replaced by ones which can.<br>
</i>
-- Zawinski's Law
</i>
</blockquote>

<p>

<blockquote>
<i>
Every web-based application attempts to expand until it can <b>send</b> mail.<br>
Those applications which cannot so expand are replaced by ones which can.<br>
</i>
-- The OpenACS Corollary to Zawinski's Law
</blockquote>

At some point, your web application - your OpenACS package, that is -
needs to send email to your users. The usual way to do this is to:
<ul>
<li> add a bunch of <tt>ns_sendmail</tt> calls to your code

<li> suddenly realize that the users are getting too much email: find a way to
batch up the emails using a sweeper proc
<li> suddenly note that different alerts have different priorities:
add user preferences for immediate notifications or batched alerts
<li> slap your forehead when you note that you've reimplemented bboard
notifications.
</ul>

<p>

The <b>goal</b> of the Notifications package is to provide the
following functionality:
<ul>
<li> a generalized means of creating notification types (e.g. "bboard
notifications")

<li> a generalized means of subscribing to notification types
(e.g. "subscribe to OpenACS 4.0 Design Forum")
<li> a generalized means for a user to control his notifications:
frequency, format (HTML, text), delivery method (email, IM, etc..).
<li> a generalized and <b>simple</b> means for an application to add to the
notification queue for a given notification type (e.g. "notify all
interested parties that a new message has been added to the OpenACS
4.0 Design Forum").
</ul>

<p>

<h2>Use Cases</h2>

There are two main actors of the notifications package:

<ul>
<li> OpenACS end-users
<li> OpenACS packages that want to notify users
</ul>

<p>

<b>Success for this package will be gauged by how many packages choose
to use it instead of going the ns_sendmail/iteration route</b>.

<h4>Web Application End-User</h4>

A web application end-user can:
<ul>
<li> view all of his notifications, organized by category

<li> edit frequency and format of notifications
<li> remove notification requests
<li> suspend notifications for a while (i.e. vacation)
</ul>

<h4>Sample Package: Forums</h4>

The Forums package will need to use notifications, specifically as
follows:

<ul>
<li> set up notifications for a user who is subscribed to a forum or thread
<li> easily add a message to the notification queue for a forum or thread

</ul>

<h2>Data Types</h2>

<h4>Notification Type</h4>

A <b>notification type</b> is a category of notifications that fit a
certain application. "Forum Notifications" is one example. It is
conceivable that one application would have more than one notification
type if it performs very different types of notifications.

<p>

A notification type may store additional data about the notification
itself. Thus, a "notification type" is also characterized by the specific
data it must keep track of.

<h4>Notification Request</h4>

Given a certain notification type (e.g. "Forum Notificaton"), a
notification request is an association of a party, a notification
type, and an object for which this notification type applies.

<p>

An example would be "Ben Adida requests a Forum
Notification on OpenACS 4.x Design":
<ul>
<li> <b>The Party ID</b>: Ben Adida
<li> <b>The Notification Type</b>: Forum Notification
<li> <b>The Object ID</b>: The OpenACS 4.0 Design Forum
</ul>

<h4>Notification Preferences</h4>

A user or party may request certain preferences on their notification
requests. Some of these preferences will be on a per request
basis. Others will be on a party-wide basis:

<ul>
<li> frequency of notifications
<li> format of notification (HTML or text)
<li> destination of notification (which email address, or which IM)
</ul>

<h4>Notification</h4>

The <b>notification</b> is the actual message that goes out and
summarizes information that needs to be communicated. A notification
is the result of processing all the messages for a particular
notification type, and sending them to all the parties who have
requested this notification type, using the preferences indicated.


<p>

<h2>Under The Hood: OpenACS Constructs</h2>

The Notification package declares an initial <tt>notification_request</tt>
OpenACS object type. This is <b>the base type for all notification
requests</b>. Creating a new <b>notification type</b> involves subtyping

<tt>notification_request</tt>. For ease of programming, an additional
table <tt>notification_types</tt> is kept which mirrors that
<tt>acs_object_types</tt> table for all subtypes of <tt>notification_request</tt>.

<p>

Notification messages are queued as individual OpenACS objects. A
<b>mapping table</b> of which notification messages have been sent to
which users is kept. Whenever the pending list of users for a
particular notification is emptied, the notification object and its
associated mapping table rows are removed. There is no need to keep a
history of these notifications (not now).

<p>

The process for <b>delivering</b> a notification is implemented as a
service contract in order to enable other means of notification (IM,
SMS, snail mail - who knows!). Instead of attempting to make the
notifications package too smart, we expect packages to come up with
different notification types (i.e. short vs. long) that will fit the
type of delivery in question. A long notification sent to SMS is
probably not a good idea. But we can't expect the Notification package
to be super smart about "summarizing" information down to a smaller
message.

<p>

<b>Email delivery</b> is implemented using <tt>acs-mail-lite</tt> for reliability.

<h2>Supplemental discussions</h2>
<p>
There are some additional docs and discussions on the forums at 
<a href="http://openacs.org/forums/message-view?message_id=108283">here</a> and 
<a href="http://openacs.org/forums/message-view?message_id=155375">here</a>
</p>

<p>&copy; 2002 OpenForce, Inc.</p>
