<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="membership_rel::change_state.approve">
        <querytext>
            begin membership_rel__approve(rel_id => :rel_id); end;
        </querytext>
    </fullquery>

    <fullquery name="membership_rel::change_state.ban">
        <querytext>
            begin membership_rel__ban(rel_id => :rel_id); end;
        </querytext>
    </fullquery>

    <fullquery name="membership_rel::change_state.delete">
        <querytext>
            begin membership_rel__delete(rel_id => :rel_id); end;
        </querytext>
    </fullquery>

    <fullquery name="membership_rel::change_state.reject">
        <querytext>
            begin membership_rel__reject(rel_id => :rel_id); end;
        </querytext>
    </fullquery>

    <fullquery name="membership_rel::change_state.unapprove">
        <querytext>
            begin membership_rel__unapprove(rel_id => :rel_id); end;
        </querytext>
    </fullquery>

</queryset>
