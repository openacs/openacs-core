<?xml version="1.0"?>

<queryset>
  <rdbms><type>postgresql</type><version>7.2</version></rdbms>

    <fullquery name="acs_sc::impl::new.impl_new">
        <querytext>
            select acs_sc_impl__new(
                       :contract_name, 
                       :name,
                       :pretty_name,
                       :owner
                   ); 	
        </querytext>
    </fullquery>

    <fullquery name="acs_sc::impl::alias::new.alias_new">
        <querytext>
            select acs_sc_impl_alias__new(
                       :contract_name, 
                       :impl_name,
                       :operation,
                       :alias,
                       :language
                   ); 	
        </querytext>
    </fullquery>

    <fullquery name="acs_sc::impl::binding::new.binding_new">
        <querytext>
            select acs_sc_binding__new(
                       :contract_name, 
                       :impl_name
                   ); 	
        </querytext>
    </fullquery>

    <fullquery name="acs_sc::impl::delete.delete_impl">
        <querytext>
            select acs_sc_impl__delete(
                       :contract_name, 
                       :impl_name
                   ); 	
        </querytext>
    </fullquery>

</queryset>
