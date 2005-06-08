<?xml version="1.0"?>

<queryset>
    <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="membership_rel::change_state.approve">
        <querytext>
            begin membership_rel.approve(rel_id => :rel_id); end;
        </querytext>
    </fullquery>

    <fullquery name="membership_rel::change_state.ban">
        <querytext>
            begin membership_rel.ban(rel_id => :rel_id); end;
        </querytext>
    </fullquery>

    <fullquery name="membership_rel::change_state.delete">
        <querytext>
            begin membership_rel.deleted(rel_id => :rel_id); end;
        </querytext>
    </fullquery>

    <fullquery name="membership_rel::change_state.reject">
        <querytext>
            begin membership_rel.reject(rel_id => :rel_id); end;
        </querytext>
    </fullquery>

    <fullquery name="membership_rel::change_state.unapprove">
        <querytext>
            begin membership_rel.unapprove(rel_id => :rel_id); end;
        </querytext>
    </fullquery>

    <fullquery name="membership_rel::change_state.merge">
        <querytext>
            begin membership_rel.merge(rel_id => :rel_id); end;
        </querytext>
    </fullquery>

</queryset>
