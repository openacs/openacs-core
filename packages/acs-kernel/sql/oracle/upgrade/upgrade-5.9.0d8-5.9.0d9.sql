-- cleanup of parameter deleted from .info files ages ago

select apm.unregister_parameter(parameter_id) from apm_parameters
  where package_key = 'acs-subsite'
  and parameter_name in (
      'background', 'bgcolor', 'textcolor',
      'EmailRandomPasswordWhenForgottenP', 'UseCustomQuestionForPasswordReset',
      'RequireQuestionForPasswordResetP'
  );
