--
-- Attribute datatype discrepancy fix for object_types in OpenACS
--

begin;

update acs_attributes set datatype='integer' where object_type='apm_parameter' and attribute_name='max_n_values';

end;
