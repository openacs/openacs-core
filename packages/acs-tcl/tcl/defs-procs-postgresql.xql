<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="ad_record_query_string.query_string_record">      
        <querytext>
            insert
            into query_strings 
            (query_date, query_string, subsection, n_results, user_id)
            values
            (now(), :query_string, :subsection, :n_results, :user_id)
        </querytext>
    </fullquery>

</queryset>
