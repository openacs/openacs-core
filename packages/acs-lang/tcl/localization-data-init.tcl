#/packages/lang/tcl/localization-data-init.tcl
ad_library {

    Database required for localization routines
    Currently only supports five locales (US, UK, France, Spain and Germany).
    Add new entries to support additional locales.

    @creation-date 10 September 2000
    @author Jeff Davis (davis@arsdigita.com)
    @cvs-id $Id$
}


# UK
nsv_set locale en_GB,abday {{Sun} {Mon} {Tue} {Wed} {Thu} {Fri} {Sat}}
nsv_set locale en_GB,abmon {{Jan} {Feb} {Mar} {Apr} {May} {Jun} {Jul} {Aug} {Sep} {Oct} {Nov} {Dec}}
nsv_set locale en_GB,am_str ""
nsv_set locale en_GB,currency_symbol "£"
nsv_set locale en_GB,day {{Sunday} {Monday} {Tuesday} {Wednesday} {Thursday} {Friday} {Saturday}}
nsv_set locale en_GB,decimal_point "."
nsv_set locale en_GB,d_fmt "%d/%m/%y"
nsv_set locale en_GB,d_t_fmt "%a %d %B %Y %H:%M %Z"
nsv_set locale en_GB,frac_digits 2
nsv_set locale en_GB,grouping {3 3 }
nsv_set locale en_GB,int_curr_symbol "GBP "
nsv_set locale en_GB,int_frac_digits 2
nsv_set locale en_GB,mon_decimal_point "."
nsv_set locale en_GB,mon_grouping {3 3 }
nsv_set locale en_GB,mon {{January} {February} {March} {April} {May} {June} {July} {August} {September} {October} {November} {December}}
nsv_set locale en_GB,mon_thousands_sep ","
nsv_set locale en_GB,n_cs_precedes 1
nsv_set locale en_GB,negative_sign "-"
nsv_set locale en_GB,n_sep_by_space 0
nsv_set locale en_GB,n_sign_posn             1
nsv_set locale en_GB,p_cs_precedes 1
nsv_set locale en_GB,pm_str ""
nsv_set locale en_GB,positive_sign ""
nsv_set locale en_GB,p_sep_by_space 0
nsv_set locale en_GB,p_sign_posn 1
nsv_set locale en_GB,t_fmt_ampm ""
nsv_set locale en_GB,t_fmt "%H:%M"
nsv_set locale en_GB,thousands_sep ","

# US
nsv_set locale en_US,abday {{Sun} {Mon} {Tue} {Wed} {Thu} {Fri} {Sat}}
nsv_set locale en_US,abmon {{Jan} {Feb} {Mar} {Apr} {May} {Jun} {Jul} {Aug} {Sep} {Oct} {Nov} {Dec}}
nsv_set locale en_US,am_str "AM"
nsv_set locale en_US,currency_symbol "$"
nsv_set locale en_US,day {{Sunday} {Monday} {Tuesday} {Wednesday} {Thursday} {Friday} {Saturday}}
nsv_set locale en_US,decimal_point "."
nsv_set locale en_US,d_fmt "%m/%d/%y"
nsv_set locale en_US,d_t_fmt "%a %B %d, %Y %r %Z"
nsv_set locale en_US,frac_digits 2
nsv_set locale en_US,grouping {3 3 }
nsv_set locale en_US,int_curr_symbol "USD "
nsv_set locale en_US,int_frac_digits 2
nsv_set locale en_US,mon_decimal_point "."
nsv_set locale en_US,mon_grouping {3 3 }
nsv_set locale en_US,mon {{January} {February} {March} {April} {May} {June} {July} {August} {September} {October} {November} {December}}
nsv_set locale en_US,mon_thousands_sep ","
nsv_set locale en_US,n_cs_precedes 1
nsv_set locale en_US,negative_sign "-"
nsv_set locale en_US,n_sep_by_space 0
nsv_set locale en_US,n_sign_posn             1
nsv_set locale en_US,p_cs_precedes 1
nsv_set locale en_US,pm_str "PM"
nsv_set locale en_US,positive_sign ""
nsv_set locale en_US,p_sep_by_space 0
nsv_set locale en_US,p_sign_posn 1
nsv_set locale en_US,t_fmt_ampm "%I:%M:%S %p"
nsv_set locale en_US,t_fmt "%r"
nsv_set locale en_US,thousands_sep ","

# France
nsv_set locale fr_FR,abday {{dim} {lun} {mar} {mer} {jeu} {ven} {sam}}
nsv_set locale fr_FR,abmon {{jan} {fév} {mar} {avr} {mai} {jun} {jui} {aoû} {sep} {oct} {nov} {déc}}
nsv_set locale fr_FR,am_str ""
nsv_set locale fr_FR,currency_symbol "F"
nsv_set locale fr_FR,day {{dimanche} {lundi} {mardi} {mercredi} {jeudi} {vendredi} {samedi}}
nsv_set locale fr_FR,decimal_point ","
nsv_set locale fr_FR,d_fmt "%d.%m.%Y"
nsv_set locale fr_FR,d_t_fmt "%a %d %B %Y %H:%M %Z"
nsv_set locale fr_FR,frac_digits 2
nsv_set locale fr_FR,grouping {-1 -1 }
nsv_set locale fr_FR,int_curr_symbol "FRF "
nsv_set locale fr_FR,int_frac_digits 2
nsv_set locale fr_FR,mon_decimal_point ","
nsv_set locale fr_FR,mon_grouping {3 3 }
nsv_set locale fr_FR,mon {{janvier} {février} {mars} {avril} {mai} {juin} {juillet} {août} {septembre} {octobre} {novembre} {décembre}}
nsv_set locale fr_FR,mon_thousands_sep " "
nsv_set locale fr_FR,n_cs_precedes 0
nsv_set locale fr_FR,negative_sign "-"
nsv_set locale fr_FR,n_sep_by_space 1
nsv_set locale fr_FR,n_sign_posn               1
nsv_set locale fr_FR,p_cs_precedes 0
nsv_set locale fr_FR,pm_str ""
nsv_set locale fr_FR,positive_sign ""
nsv_set locale fr_FR,p_sep_by_space 1
nsv_set locale fr_FR,p_sign_posn 1
nsv_set locale fr_FR,t_fmt_ampm ""
nsv_set locale fr_FR,t_fmt "%H:%M"
nsv_set locale fr_FR,thousands_sep "."

# Germany
nsv_set locale de_DE,abday {{Son} {Mon} {Die} {Mit} {Don} {Fre} {Sam}}
nsv_set locale de_DE,abmon {{Jan} {Feb} {Mär} {Apr} {Mai} {Jun} {Jul} {Aug} {Sep} {Okt} {Nov} {Dez}}
nsv_set locale de_DE,am_str ""
nsv_set locale de_DE,currency_symbol "DM"
nsv_set locale de_DE,day {{Sonntag} {Montag} {Dienstag} {Mittwoch} {Donnerstag} {Freitag} {Samstag}}
nsv_set locale de_DE,decimal_point ","
nsv_set locale de_DE,d_fmt "%d.%m.%Y"
nsv_set locale de_DE,d_t_fmt "%a %d %B %Y %H:%M %Z"
nsv_set locale de_DE,frac_digits 2
nsv_set locale de_DE,grouping {3 3 }
nsv_set locale de_DE,int_curr_symbol "DEM "
nsv_set locale de_DE,int_frac_digits 2
nsv_set locale de_DE,mon_decimal_point ","
nsv_set locale de_DE,mon_grouping {3 3 }
nsv_set locale de_DE,mon {{Januar} {Februar} {März} {April} {Mai} {Juni} {Juli} {August} {September} {Oktober} {November} {Dezember}}
nsv_set locale de_DE,mon_thousands_sep "."
nsv_set locale de_DE,n_cs_precedes 1
nsv_set locale de_DE,negative_sign "-"
nsv_set locale de_DE,n_sep_by_space 0
nsv_set locale de_DE,n_sign_posn               1
nsv_set locale de_DE,p_cs_precedes 1
nsv_set locale de_DE,pm_str ""
nsv_set locale de_DE,positive_sign ""
nsv_set locale de_DE,p_sep_by_space 0
nsv_set locale de_DE,p_sign_posn 1
nsv_set locale de_DE,t_fmt_ampm ""
nsv_set locale de_DE,t_fmt "%H:%M"
nsv_set locale de_DE,thousands_sep "."

# Spain
nsv_set locale es_ES,abday {{dom} {lun} {mar} {mié} {jue} {vie} {sáb}}
nsv_set locale es_ES,abmon {{ene} {feb} {mar} {abr} {may} {jun} {jul} {ago} {sep} {oct} {nov} {dic}}
nsv_set locale es_ES,am_str ""
nsv_set locale es_ES,currency_symbol "Pts"
nsv_set locale es_ES,day {{domingo} {lunes} {martes} {miércoles} {jueves} {viernes} {sábado}}
nsv_set locale es_ES,decimal_point ","
nsv_set locale es_ES,d_fmt "%d/%m/%y"
nsv_set locale es_ES,d_t_fmt "%a %d %B %Y %H:%M %Z"
nsv_set locale es_ES,frac_digits 0
nsv_set locale es_ES,grouping {-1 -1 }
nsv_set locale es_ES,int_curr_symbol "ESP "
nsv_set locale es_ES,int_frac_digits 0
nsv_set locale es_ES,mon_decimal_point ","
nsv_set locale es_ES,mon {{enero} {febrero} {marzo} {abril} {mayo} {junio} {julio} {agosto} {septiembre} {octubre} {noviembre} {diciembre}}
nsv_set locale es_ES,mon_grouping {3 3 }
nsv_set locale es_ES,mon_thousands_sep "."
nsv_set locale es_ES,n_cs_precedes 1
nsv_set locale es_ES,negative_sign "-"
nsv_set locale es_ES,n_sep_by_space 1
nsv_set locale es_ES,n_sign_posn          1
nsv_set locale es_ES,p_cs_precedes 1
nsv_set locale es_ES,pm_str ""
nsv_set locale es_ES,positive_sign ""
nsv_set locale es_ES,p_sep_by_space 1
nsv_set locale es_ES,p_sign_posn 1
nsv_set locale es_ES,t_fmt_ampm ""
nsv_set locale es_ES,t_fmt "%H:%M"
nsv_set locale es_ES,thousands_sep ""

# Monetary amounts
nsv_set locale money:000  {($num$sym)}
nsv_set locale money:001  {($num $sym)}
nsv_set locale money:002  {($num$sym)} 
nsv_set locale money:010  {$sign$num$sym}
nsv_set locale money:011  {$sign$num $sym}
nsv_set locale money:012  {$sign$num $sym} 
nsv_set locale money:020  {$num$sym$sign}
nsv_set locale money:021  {$num $sym$sign}
nsv_set locale money:022  {$num$sym $sign}
nsv_set locale money:030  {$num$sign$sym}
nsv_set locale money:031  {$num $sign$sym}
nsv_set locale money:032  {$num$sign $sym}
nsv_set locale money:040  {$num$sym$sign}
nsv_set locale money:041  {$num $sym$sign}
nsv_set locale money:042  {$num$sym $sign}
nsv_set locale money:100  {($sym$num)}
nsv_set locale money:101  {($sym$num)}
nsv_set locale money:102  {($sym$num)}
nsv_set locale money:110  {$sign$sym$num}
nsv_set locale money:111  {$sign$sym$num}
nsv_set locale money:112  {$sign$sym$num} 
nsv_set locale money:120  {$sym$num$sign}
nsv_set locale money:121  {$sym$num$sign}
nsv_set locale money:122  {$sym$num$sign} 
nsv_set locale money:130  {$sign$sym$num}
nsv_set locale money:131  {$sign$sym$num}
nsv_set locale money:132  {$sign$sym$num} 
nsv_set locale money:140  {$sym$sign$num}
nsv_set locale money:141  {$sym$sign$num}
nsv_set locale money:142  {$sym$sign$num} 
