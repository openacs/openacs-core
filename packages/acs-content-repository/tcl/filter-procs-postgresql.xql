<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="content::get_folder_labels.get_url">      
      <querytext>

    select
      0 as tree_level, '' as name , 'Home' as title
    from
      dual
    UNION
    select
      t.tree_level, i.name, content_item.get_title(t.context_id) as title
    from (
      select 
        o2.context_id, tree_level(o2.tree_sortkey) as tree_level
      from 
        (select * from acs_objects where object_id = :item_id) o1, 
        acs_objects o2
      where
        context_id <> content_item__get_root_folder()
      and
        o2.tree_sortkey <= o1.tree_sortkey
      and 
        o1.tree_sortkey like (o2.tree_sortkey || '%')
      ) t, cr_items i
    where
      i.item_id = t.context_id
    order by
      tree_level

      </querytext>
</fullquery>

<fullquery name="content::init.get_item_info">      
      <querytext>

    select 
      item_id, content_type
    from 
      cr_items
    where
      item_id = content_item__get_id(:url, :content_root, 'f')

      </querytext>
</fullquery>

<fullquery name="content::init.get_template_url">      
      <querytext>

        select 
          content_template__get_path(
          content_item__get_template(:item_id, :context),:template_root) as template_url 
        from 
          dual

      </querytext>
</fullquery>

</queryset>
