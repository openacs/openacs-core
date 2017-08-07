
<property name="context">{/doc/search {Search}} {How to make an object type searchable?}</property>
<property name="doc(title)">How to make an object type searchable?</property>
<master>
<blockquote>
<h2>How to make an object type searchable?</h2>
by Neophytos Demetriou (<a href="mailto:k2pts\@cytanet.com.cy">k2pts\@cytanet.com.cy</a>)
<hr>
Making an object type searchable involves three steps:
<ul>
<li>Choose the object type</li><li>Implement FtsContentProvider</li><li>Add triggers</li>
</ul><h3>Choose the object type</h3>
In most of the cases, choosing the object type is straightforward.
However, if your object type uses the content repository then you
should make sure that your object type is a subclass of the
"content_revision" class. You should also make sure all
content is created using that subclass, rather than simply create
content with the "content_revision" type.
<ul>
<li>Object types that don&#39;t use the CR, can be specified using
<code>acs_object_type__create_type</code>, but those that use the
CR need to use <code>content_type__create_type</code>.
<code>content_type__create_type</code> overloads
<code>acs_object_type__create_type</code> and provides two views
for inserting and viewing content data, and the CR depends on these
views.</li><li>Whenever you call content_item__new, call it with
'content_revision' as the item_subtype and
'your_content_type' as the content_type.</li>
</ul><h3>Implement FtsContentProvider</h3>
FtsContentProvider is comprised of two abstract operations, namely
<code>datasource</code> and <code>url</code>. The specification for
these operations can be found in
<code>packages/search/sql/postgresql/search-sc-create.sql</code>.
You have to implement these operations for your object type by
writing concrete functions that follow the specification. For
example, the implementation of <code>datasource</code> for the
object type <code>note</code>, looks like this:
<pre><code>ad_proc notes__datasource {
    object_id
} {
    \@author Neophytos Demetriou
} {
    db_0or1row notes_datasource {
        select n.note_id as object_id, 
               n.title as title, 
               n.body as content,
               'text/plain' as mime,
               '' as keywords,
               'text' as storage_type
        from notes n
        where note_id = :object_id
    } -column_array datasource

    return [array get datasource]
}
</code></pre>
When you are done with the implementation of
<code>FtsContentProvider</code> operations, you should let the
system know of your implementation. This is accomplished by an SQL
file which associates the implementation with a contract name. The
implementation of <code>FtsContentProvider</code> for the object
type <code>note</code> looks like:
<pre><code>select acs_sc_impl__new(
           'FtsContentProvider',                -- impl_contract_name
           'note',                              -- impl_name
           'notes'                              -- impl_owner_name
);
</code></pre>
You should adapt this association to reflect your implementation.
That is, change <code>impl_name</code> with your object type and
the <code>impl_owner_name</code> to the package key. Next, you have
to create associations between the operations of
<code>FtsContentProvider</code> and your concrete functions.
Here&#39;s how an association between an operation and a concrete
function looks like:
<pre><code>select acs_sc_impl_alias__new(
           'FtsContentProvider',                -- impl_contract_name
           'note',                              -- impl_name
           'datasource',                        -- impl_operation_name
           'notes__datasource',                 -- impl_alias
           'TCL'                                -- impl_pl
);
</code></pre>
Again, you have to make some changes. Change the
<code>impl_name</code> from <code>note</code> to your object type
and the <code>impl_alias</code> from <code>notes__datasource</code>
to the name that you gave to the function that implements the
operation <code>datasource</code>.
<h3>Add triggers</h3>
If your object type uses the content repository to store its items,
then you are done. If not, an extra step is required to inform the
search_observer_queue of new content items, updates or deletions.
We do this by adding triggers on the table that stores the content
items of your object type. Here&#39;s how that part looks like for
<code>note</code>.
<pre><code>create function notes__itrg ()
returns opaque as $$
begin
    perform search_observer__enqueue(new.note_id,'INSERT');
    return new;
end;
$$ language plpgsql;

create function notes__dtrg ()
returns opaque as $$
begin
    perform search_observer__enqueue(old.note_id,'DELETE');
    return old;
end;
$$ language plpgsql;

create function notes__utrg ()
returns opaque as $$
begin
    perform search_observer__enqueue(old.note_id,'UPDATE');
    return old;
end;
$$ language plpgsql;


create trigger notes__itrg after insert on notes
for each row execute procedure notes__itrg (); 

create trigger notes__dtrg after delete on notes
for each row execute procedure notes__dtrg (); 

create trigger notes__utrg after update on notes
for each row execute procedure notes__utrg (); 
</code></pre><h3>Questions &amp; Answers</h3><ol>
<li>Q: If content is some binary file (like a pdf file stored in
file storage, for example), will the content still be
indexable/searchable?<br><br>
A: For each mime type we require some type of handler. Once the
handler is available, i.e. pdf2txt, it is very easy to incorporate
support for that mime type into the search package. Content items
with unsupported mime types will be ignored by the indexer.<br><br>
</li><li>Q: Can the search package handle lobs and files?<br><br>
A: Yes, the search package will convert everything into text based
on the content and storage_type attributes. Here is the convention
to use while writing the implementation of datasource:<br><br><ul>
<li>Content is a filename when storage_type='file'.</li><li>Content is a lob id when storage_type='lob'.</li><li>Content is text when storage_type='text'.</li>
</ul>
</li>
</ol>
</blockquote>
