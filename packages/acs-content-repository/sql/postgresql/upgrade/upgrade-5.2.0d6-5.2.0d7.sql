-- exception was miss spelled
drop function cr_dummy_ins_del_tr() cascade;

create function cr_dummy_ins_del_tr () returns opaque as '
begin
        raise exception ''Only updates are allowed on cr_dummy'';
        return null;
end;' language 'plpgsql';

create trigger cr_dummy_ins_del_tr before insert or delete on 
cr_dummy for each row execute procedure cr_dummy_ins_del_tr ();
