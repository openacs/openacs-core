<?xml version="1.0"?>

<queryset>
<rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="acs_sc::impl::new.impl_new">
        <querytext>
            begin
                :1 := acs_sc_impl.new(
                       :contract_name, 
                       :name,
                       :pretty_name,
                       :owner
                   );
            end;
        </querytext>
    </fullquery>

    <fullquery name="acs_sc::impl::alias::new.alias_new">
        <querytext>
            begin
                :1 := acs_sc_impl_alias.new(
                       :contract_name, 
                       :impl_name,
                       :operation,
                       :alias,
                       :language
                   );
            end;
        </querytext>
    </fullquery>

    <fullquery name="acs_sc::impl::binding::new.binding_new">
        <querytext>
            begin
                acs_sc_binding.new(
                       contract_name => :contract_name, 
                       impl_name => :impl_name
                   );
            end;
        </querytext>
    </fullquery>

    <fullquery name="acs_sc::impl::delete.delete_impl">
        <querytext>
            begin
                acs_sc_impl.del(
                       impl_contract_name => :contract_name, 
                       impl_name => :impl_name
                   );
            end;
        </querytext>
    </fullquery>

</queryset>
