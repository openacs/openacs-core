
<property name="context">{/doc/acs-messaging {ACS Messaging}} {ACS Messaging Requirements}</property>
<property name="doc(title)">ACS Messaging Requirements</property>
<master>
<h1>ACS Messaging Requirements</h1>

by <a href="mailto:akk\@arsdigita.com">Anukul Kapoor</a>
 and
<a href="mailto:akk\@arsdigita.com">Pete Su</a>
<em>This is only a DRAFT</em>
<h3>I. Introduction</h3>
<p>In ACS 3.x, each messaging application (e.g. bboard, general
comments, spam, ticket tracker and so on) used its own specialized
data model for representing and manipulating messages. ACS Messages
provides a common data model and API for these applications. The
service provides the following common mechanisms:</p>
<ul>
<li>A single data model for representing message objects. Message
objects model electronic messages between users of a collaborative
system. Mail messages, USENET news messages, Bboard messages, user
comments are all examples of applications that might use message
objects.</li><li>Storage of message objects.</li><li>Central support for attachments, threading, and search.</li><li>Mechanisms for sending and receiving message objects as
e-mail.</li>
</ul>
<h3>II. Vision Statement</h3>
<p>Messaging applications constitute some of the most useful forms
of web collaboration. Many of the application packages that have
been developed for ACS have a messaging component. Therefore, ACS
Messaging provides a standard set of abstractions for storing,
sending and receiving messages through a web service. Our goal is
to support a diverse group of messaging applications through a
single centralized facility.</p>
<h3>III. System/Application Overview</h3>
<p>The ACS Messaging package defines a data model and API for the
storage and retrieval of messages. While the package standarizes
how messages are stored, applications may use any data model they
want for higher level organization of messages into threads,
forums, and so on. ACS Messaging places no organizational
constraints on client applications.</p>
<p>The package consists of the following components:</p>
<ul>
<li>A data model for representing and storing messages.</li><li>A data model for representing and storing attachments to
messages.</li><li>A mechanism for sending messages as e-mail.</li><li>A mechanism for integrating the message store into site wide
search.</li>
</ul>
<h3>IV. Use-cases and User Scenarios</h3>
<p>ACS Messaging is generally not used directly by users, so there
are no user interface level scenarios to consider at this point.
It&#39;s possible that in the future we will want to extend the
system with generic administrative user interfaces, but this is not
clear right now.</p>
<p>We scenarios that we should consider are the kinds of
applications that we mean to support with this package, and what
the developers of those applications would like to see in the data
model and API.</p>
<p>The following applications in ACS 3.x could have been
implemented using this package:</p>
<ul>
<li>BBoard</li><li>Webmail</li><li>General Comments</li><li>Spam</li><li>Various parts of the ticket tracker.</li>
</ul>
<p>Each of these applications requires a message store and each
defines its own high level organization for messages within that
store.</p>
<ul>
<li>Bboard organizes messages into forums and categories and
threads. It also allows users to send and reply to messages via
e-mail.</li><li>Webmail organizes messages into mail folders.</li><li>General comments attaches messages to objects representing
static or other content.</li><li>Spam queues messages and sends them to groups of people as
e-mail.</li>
</ul>
<p>The main requirement of the ACS Messages package is to support
this diverse set of applications with a common infrastructure. This
is because all of these applications would like the following kinds
of common functionality:</p>
<ul>
<li>Reply chaining and threading.</li><li>Messages with attachments of various types.</li><li>Representing messages as multipart MIME e-mail.</li><li>Queuing and sending messages as e-mail.</li>
</ul>
<h3>V. Related Links</h3>
<ul><li><a href="design">Design Document</a></li></ul>
<h3>VI.A Requirements: Datamodel</h3>
<p><strong>10.0 Message Store</strong></p>
<p>ACS Messages should provide a single store for objects
representing messages.</p>
<p><strong>20.0 Message Content</strong></p>
<p>A message should have a primary content body consisting of a
specified MIME type and a block of storage holding the content. In
addition, applications may store one or more separate revisions of
a message.</p>
<p><strong>30.0 Attachments</strong></p>
<p>Messages may be composed of additional attachments. Each
attachment should be tagged with a MIME type to indicate what type
of data is stored there. Each attachment can only be attached to a
single parent message. In addition, the system must be able to
store one or more revisions of each attachment.</p>
<p><strong>40.0 Unique ID</strong></p>
<p>Messages should have universally unique identifiers to allow
global reference and RFC-822 compliance.</p>
<p><strong>50.0 Sender</strong></p>
<p>Messages should be related to the sending party.</p>
<p><strong>60.0 Threading</strong></p>
<p>The system model simple message threads, that is chains of
messages that are replies to each other. If message M is a reply to
some other message N, then M should be able to refer to N in a
straightforward way.</p>
<p><strong>70.0 Search</strong></p>
<p>Messages should be searchable as part of a site wide search.
Therefore, the data model must integrate with the data model for
site wide search.</p>
<h3>VI.B Requirements: API</h3>
<p><strong>80.0 Messages</strong></p>
<p>The system should provide the following interfaces for
manipulating messages:</p>
<blockquote>
<p><strong>80.10 Creation</strong></p><p>Applications should be able to create new messages objects.</p><p><strong>80.20 Revisions</strong></p><p>Applications should be able to create a new revision of a given
message object.</p><p><strong>80.30 Deletion</strong></p><p>Applications should be able to delete a message and all of its
revisions and attachments. (is this true?).</p><p>
<strong>80.40 Type Checking</strong> Applications should be able
to check whether or not a given object is a message.</p>
</blockquote>
<p><strong>90.0 Message Attachments</strong></p>
<p>The system should provide the following interfaces for
manipulating message attachments.</p>
<blockquote>
<p><strong>90.10 Creation</strong></p><p>Applications should be able to create new message attachments
and connect to their parent object.</p><p><strong>90.20 Revisions</strong></p><p>Applications should be able to create a new revision of a given
attachment.</p><p><strong>90.30 MIME Types</strong></p><p>Each attachment should have a MIME type. The system should be
able in principle to deal with an arbitrary collection of MIME
types, although initial implementations may be more limited.</p>
</blockquote>
<p><strong>100.0 Messages and E-Mail</strong></p>
<p>The system should provide the following interfaces for
integrating with existing E-mail systems. Note that these
requirements only deal with <em>sending</em> mail. Our feeling that
a separate package should be implemented to deal with
<em>receiving</em> mail that would use ACS Messages for storage of
incoming messages.</p>
<blockquote>
<p><strong>100.10 Sending Single Messages</strong></p><p>The system should provide a mechanism for specifying that a
message should be sent as outgoing E-mail. Outgoing messages should
be queued so that the system can maintain auditing information to
deal with transport failures and so on.</p><p><strong>100.20 Sending MIME Messages</strong></p><p>The system should be able to send messages with attachments as
multipart MIME messages.</p><p><strong>100.30 Sending Digests</strong></p><p>The system should be able to group multiple messages together as
a single e-mail digest. For example, all the messages in a single
bboard thread could be sent to a user as a digest.</p>
</blockquote>
<h3>VII. Revision History</h3>
<table cellpadding="2" cellspacing="2" width="90%" bgcolor="#EFEFEF">
<tr bgcolor="#E0E0E0">
<th width="10%">Document Revision #</th><th width="50%">Action Taken, Notes</th><th>When?</th><th>By Whom?</th>
</tr><tr>
<td>0.1</td><td>Creation</td><td>10/04/2000</td><td>Anukul Kapoor</td>
</tr><tr>
<td>0.2</td><td>Edited and extended for more general data model</td><td>11/07/2000</td><td>Pete Su</td>
</tr>
</table>
<hr>
<address><a href="mailto:kapoor\@maya.com"></a></address>

Last modified: $&zwnj;Id: requirements.html,v 1.3 2018/04/11 21:35:07
hectorr Exp $
