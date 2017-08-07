<master>
<property name="doc(title)">Notification Package Documentation</property>

<h1>Notifications Package</h1>

<h2>The Idea</h2>

<p>The Zawinski's Law:</p>
<blockquote>
<p>
Every program attempts to expand until it can read mail. Those programs which cannot so expand are replaced by ones which can.
</p>
</blockquote>

<p>The OpenACS Corollary to Zawinski's Law:</p>

<blockquote>
<p>
Every web-based application attempts to expand until it can <strong>send</strong> mail. Those applications which cannot so expand are replaced by ones which can.
</p>
</blockquote>

<p>At some point, your web application - your OpenACS package, that is -
needs to send email to your users. The usual way to do this is to:</p>

<ul>
<li> add a bunch of <code>acs_mail_lite::send</code> calls to your code</li>
<li> suddenly realize that the users are getting too much email: find a way to
batch up the emails using a sweeper proc</li>
<li> suddenly note that different alerts have different priorities:
add user preferences for immediate notifications or batched alerts</li>
<li> slap your forehead when you note that you've reimplemented bboard
notifications.</li>
</ul>

<p>
The <strong>goal</strong> of the Notifications package is to provide the
following functionality:
</p>

<ul>
<li> a generalized means of creating notification types (e.g. "bboard
notifications")</li>
<li> a generalized means of subscribing to notification types
(e.g. "subscribe to OpenACS Design Forum")</li>
<li> a generalized means for a user to control his notifications:
frequency, format (HTML, text), delivery method (email, IM, etc..).</li>
<li> a generalized and <strong>simple</strong> means for an application to add to the
notification queue for a given notification type (e.g. "notify all
interested parties that a new message has been added to the OpenACS
Design Forum").</li>
</ul>

<h2>Use Cases</h2>

<p>There are two main actors of the notifications package:</p>

<ul>
<li> OpenACS end-users</li>
<li> OpenACS packages that want to notify users</li>
</ul>

<p>
<strong>Success for this package will be gauged by how many packages choose
to use it instead of going the <code>acs_mail_lite::send/iteration</code> route</strong>.

<h3>Web Application End-User</h3>

<p>A web application end-user can:</p>

<ul>
<li> view all of his notifications, organized by category</li>
<li> edit frequency and format of notifications</li>
<li> remove notification requests</li>
<li> suspend notifications for a while (i.e. vacation)</li>
</ul>

<h3>Sample Package: Forums</h3>

<p>The Forums package will need to use notifications, specifically as
follows:</p>

<ul>
<li> set up notifications for a user who is subscribed to a forum or thread</li>
<li> easily add a message to the notification queue for a forum or thread</li>
</ul>

<h2>Data Types</h2>

<h3>Notification Type</h3>

<p>
A <strong>notification type</strong> is a category of notifications that fit a
certain application. "Forum Notifications" is one example. It is
conceivable that one application would have more than one notification
type if it performs very different types of notifications.
</p>
<p>
A notification type may store additional data about the notification
itself. Thus, a "notification type" is also characterized by the specific
data it must keep track of.
</p>

<h3>Notification Request</h3>

<p>
Given a certain notification type (e.g. "Forum Notificaton"), a
notification request is an association of a party, a notification
type, and an object for which this notification type applies.
</p>
<p>
An example would be "Ben Adida requests a Forum
Notification on OpenACS Design":
</p>

<ul>
<li> <strong>The Party ID</strong>: Ben Adida</li>
<li> <strong>The Notification Type</strong>: Forum Notification</li>
<li> <strong>The Object ID</strong>: The OpenACS Design Forum</li>
</ul>

<h3>Notification Preferences</h3>

<p>
A user or party may request certain preferences on their notification
requests. Some of these preferences will be on a per request
basis. Others will be on a party-wide basis:
</p>

<ul>
<li> frequency of notifications</li>
<li> format of notification (HTML or text)</li>
<li> destination of notification (which email address, or which IM)</li>
</ul>

<h3>Notification</h3>
<p>
The <strong>notification</strong> is the actual message that goes out and
summarizes information that needs to be communicated. A notification
is the result of processing all the messages for a particular
notification type, and sending them to all the parties who have
requested this notification type, using the preferences indicated.
</p>

<h2>Under The Hood: OpenACS Constructs</h2>

<p>
The Notification package declares an initial <code>notification_request</code>
OpenACS object type. This is <strong>the base type for all notification
requests</strong>. Creating a new <strong>notification type</strong> involves subtyping
<code>notification_request</code>. For ease of programming, an additional
table <code>notification_types</code> is kept which mirrors that
<code>acs_object_types</code> table for all subtypes of <code>notification_request</code>.
</p>

<p>
Notification messages are queued as individual OpenACS objects. A
<strong>mapping table</strong> of which notification messages have been sent to
which users is kept. Whenever the pending list of users for a
particular notification is emptied, the notification object and its
associated mapping table rows are removed. There is no need to keep a
history of these notifications (not now).
</p>

<p>
The process for <strong>delivering</strong> a notification is implemented as a
service contract in order to enable other means of notification (IM,
SMS, snail mail - who knows!). Instead of attempting to make the
notifications package too smart, we expect packages to come up with
different notification types (i.e. short vs. long) that will fit the
type of delivery in question. A long notification sent to SMS is
probably not a good idea. But we can't expect the Notification package
to be super smart about "summarizing" information down to a smaller
message.
</p>

<p>
<strong>Email delivery</strong> is implemented using <code>acs-mail-lite</code> for reliability.
</p>

<h2>Supplemental discussions</h2>
<p>
There are some additional docs and discussions on the forums in the following threads:
</p>
<ul>
<li><a href="http://openacs.org/forums/message-view?message_id=108283">Notifications tutorial</a></li>
<li><a href="http://openacs.org/forums/message-view?message_id=155375">How do I use notifications?</a></li>
</ul>
<h2>Release Notes</h2>

<p>Please file bugs in the <a href="http://openacs.org/bugtracker/openacs/">Bug Tracker</a>.</p>
<p>&copy; 2002 OpenForce, Inc.</p>
