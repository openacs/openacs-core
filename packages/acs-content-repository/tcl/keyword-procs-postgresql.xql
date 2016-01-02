<?xml version="1.0"?>
<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="cr::keyword::new.content_keyword_new">
        <querytext>
            select content_keyword__new (
                :heading,    
                :description,
                :parent_id,  
                :keyword_id, 
                current_timestamp,
                :user_id,      
                :creation_ip,  
                :object_type,
                :package_id
            )
        </querytext>
    </fullquery>

    <fullquery name="cr::keyword::delete.delete_keyword">
        <querytext>
                select content_keyword__delete (:keyword_id)
        </querytext>
    </fullquery>

    <fullquery name="cr::keyword::set_heading.set_heading">
        <querytext>
            select content_keyword__set_heading(:keyword_id, :heading)
        </querytext>
    </fullquery>

    <fullquery name="cr::keyword::item_assign.keyword_assign">
        <querytext>
            select content_keyword__item_assign(
                :item_id,
                :keyword,
                null,
                null,
                null
            )
        </querytext>
    </fullquery>

</queryset>
