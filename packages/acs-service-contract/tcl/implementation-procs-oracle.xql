<?xml version="1.0"?>

<queryset>
<rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="acs_sc::impl::new.impl_new">
        <querytext>
            select acs_sc_impl.new(
                       :contract_name, 
                       :name,
                       :owner
                   ) from dual
        </querytext>
    </fullquery>

    <fullquery name="acs_sc::impl::alias::new.alias_new">
        <querytext>
            select acs_sc_impl_alias.new(
                       :contract_name, 
                       :impl_name,
                       :operation,
                       :alias,
                       :language
                   ) from dual
        </querytext>
    </fullquery>

    <fullquery name="acs_sc::impl::binding::new.binding_new">
        <querytext>
            select acs_sc_binding.alias_new(
                       :contract_name, 
                       :impl_name
                   ) from dual
        </querytext>
    </fullquery>

    <fullquery name="acs_sc::impl::delete.delete_impl">
        <querytext>
            select acs_sc_impl.delete(
                       :contract_name, 
                       :impl_name
                   ) from dual 	
        </querytext>
    </fullquery>

</queryset>
