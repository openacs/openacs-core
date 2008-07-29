<master>
<property name=title>Search Admin Page</property>
<property name="context">@context;noquote@</property>
<table border=1>
  <tr>
    <th>Object Type</th>
    <th align="right">#Objects in the Index</th>
    <th align="right">#Objects that should be in the Index</th>
    <th></th>
  </tr>
  <multiple name="object_type_count">
    <tr>
      <td><a href="list-objects?object_type=@object_type_count.object_type@">@object_type_count.object_type@</a></td>
      <td>@object_type_count.count_object_type@</td>
      <td>
        <switch @object_type_count.object_type@>
          <case value="cal_item">@count_cal_item@</case>
          <case value="file_storage_object">@count_file_storage_object@</case>
          <case value="static_portal_content">@count_static_portal_content@</case>
          <case value="forums_message">@count_forums_message@</case>
          <case value="forums_forum">@count_forums_forum@</case>
          <case value="news">@count_news@</case>
          <case value="faq">@count_faq@</case>
          <case value="survey">@count_survey@</case>
          <case value="phb_person">@count_phb_person@</case>
        </switch>
      </td>
      <td><a href="delete-object-type-from-index?object_type=@object_type_count.object_type@">Delete @object_type_count.object_type@ from index</a></td>
    </tr>
  </multiple>
</table>                                                                                                                   

<h2>Search Observer Queue</h2>

<p>Items in the search observer queue: @search_observer_queue_count@

<h2>Reindexing</h2>
<ul>
  <li><a href="reindex-calitem">Reindex cal_item</a>
  <li><a href="reindex-file-storage">Reindex file_storage_object</a>
  <li><a href="reindex-forums">Reindex forums-forum</a>
  <li><a href="reindex-forums-message">Reindex forums-message</a>
  <li><a href="reindex-news">Reindex news</a>
  <li><a href="reindex-faq">Reindex faq</a>
  <li><a href="reindex-phb-person">Reindex phb_person</a>
  <li><a href="reindex-static-portal">Reindex static_portal_content</a>
  <li><a href="reindex-survey">Reindex survey</a>
</ul>

<h2>Index objects missing from the index</h2>
<ul>
  <li><a href="index-missing-objects?object_type=file_storage_object">Index file_storage_object objects not in the index</a>
</ul>

<h2>Index particular objects</h2>
<p>
<form action="reindex-one-item" method="GET">
  <input type="text" name="object_id">
  <input type="button" value="Reindex the item with this object_id">
</form>

<p>
<form action="index-one-item" method="GET">
  <input type="text" name="object_id">
  <input type="button" value="Index the item with this object_id">
</form>
