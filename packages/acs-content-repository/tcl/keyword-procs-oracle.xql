<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="cr::keyword::new.content_keyword_new">
        <querytext>
            begin
              :1 := content_keyword.new (
                :heading,    
                :description,
                :parent_id,  
                :keyword_id, 
                sysdate(),
                :user_id,      
                :creation_ip,  
                :object_type,
                :package_id
              );
            end;
        </querytext>
    </fullquery>

    <fullquery name="cr::keyword::delete.delete_keyword">
        <querytext>
            begin
                content_keyword.del(:keyword_id);
            end;
        </querytext>
    </fullquery>

    <fullquery name="cr::keyword::set_heading.set_heading">
        <querytext>
            begin
                content_keyword.set_heading(:keyword_id, :heading);
            end;
        </querytext>
    </fullquery>

    <fullquery name="cr::keyword::item_assign.keyword_assign">
        <querytext>
            begin
              content_keyword.item_assign(
                :item_id,
                :keyword,
                null,
                null,
                null
              );
            end;
        </querytext>
    </fullquery>

</queryset>
