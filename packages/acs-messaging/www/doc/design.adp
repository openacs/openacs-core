
<property name="context">{/doc/acs-messaging {Messaging}} {ACS Messaging Design}</property>
<property name="doc(title)">ACS Messaging Design</property>
<master>

<body>
<h2>ACS Messaging Design</h2>
ACS Messaging was born out of the design of the new bboard. One
thing we discovered when researching requirements for bboard and
discussion software in general was that there are a variety of ways
one may wish to structure and organize threads of messages e.g. in
discrete forums with tagged categories, attached to other user
objects annotated with user ratings, etc.,. Our design addressed
this by separating the store of messages from the organizational
data model and any user interfaces.ACS Messaging is this separate
layer. Built atop the content repository, it provides the storage
and retrieval of messages. We take messages to be objects that
consist of a sender (an ACS party), a text body, an optional
reference to a parent message, optional file attachments, and some
miscellaneous auditing data.With these constraining constraining
set of semantics, we can build a library of component functionality
to operate on messages. For example: code that displays a message,
forwards a message, compiles a set of messages into a digest,
displays a specific attachment, etc., This functionality can then
be reused across messaging applications such as bboard, webmail,
and general comments. We can maintain user preferences on HTML vs.
text email, inline attachments vs. URLs across the system, and have
simple procedures that do the right thing when sending email.
Another example: if we built the IMAP server functionality 3.4
webmail provides against acs-messaging, then bboard forums, pages
of comments, and webmail folders could be viewed uniformly through
your email client. The IMAP mapping isn't quite trivial, but you
can see the idea.To reiterate, if applications are storing the same
sort of data (a text-ish messages with optional attachments and
replies), they should store them the same way. Then code from
particular applications can possibly be refactored into generic
functionality.spam/general alerts/etc isn't meant to be replaced by
ACS Messaging, at least not with what is there currently. Currently
it is just a store; but we intend it to be the canonical store for
messages that need to be stored in the database. If messages are
automatically generated from other user objects, they might need to
be queue'd up or archived in the RDBMS. If so this should be done
in the acs-messaging tables. We can implement the generic incoming
email system by stashing messages in acs-messaging, then
dispatching the message id to package specific code for
processing.Currently (11/2000), ACS Messaging is very slim; it just
supports bboard. We intend to add attachments (most likely
implemented as content repository items that are children of the
message), extensible headers (just like the webmail datamodel), and
versioning as provided by the content repository.
<h2>API</h2>
ACS Messaging provides the <code>acs_messages_all</code> view as
the primary mechanism for message queries.
<blockquote><pre><code>create or replace view acs_messages_all as
    select m.message_id, m.reply_to, o.context_id, r.title, r.publish_date,
           r.mime_type, r.content, o.creation_user
    ...
  </code></pre></blockquote>
ACS Messaging provides the PL/SQL function acs_message.post to add
new messages.
<hr><address>akk\@arsdigita.com</address>
</body>
