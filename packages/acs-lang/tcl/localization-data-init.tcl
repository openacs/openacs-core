#/packages/lang/tcl/localization-data-init.tcl
ad_library {

    Database required for localization routines
    Currently only supports five locales (US, UK, France, Spain and Germany).
    Add new entries to support additional locales.

    @creation-date 10 September 2000
    @author Jeff Davis (davis@xarg.net)
    @cvs-id $Id$
}
# Belgium, Greece, Germany, Spain, France, Ireland, Italy, Luxembourg, The Netherlands, Austria, Portugal and Finland are using Euro's since 1-1-2001


# UK
nsv_set locale en_GB,abday {{Sun} {Mon} {Tue} {Wed} {Thu} {Fri} {Sat}}
nsv_set locale en_GB,abmon {{Jan} {Feb} {Mar} {Apr} {May} {Jun} {Jul} {Aug} {Sep} {Oct} {Nov} {Dec}}
nsv_set locale en_GB,am_str ""
nsv_set locale en_GB,currency_symbol "£"
nsv_set locale en_GB,day {{Sunday} {Monday} {Tuesday} {Wednesday} {Thursday} {Friday} {Saturday}}
nsv_set locale en_GB,firstdayofweek 0
nsv_set locale en_GB,decimal_point "."
nsv_set locale en_GB,d_fmt "%d/%m/%y"
nsv_set locale en_GB,d_t_fmt "%a %d %B %Y %H:%M %Z"
nsv_set locale en_GB,dlong_fmt "%d %B %Y"
nsv_set locale en_GB,dlongweekday_fmt "%A %d %B %Y"
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
nsv_set locale en_GB,formbuilder_time_format "HH12:MI AM"

# US
nsv_set locale en_US,abday {{Sun} {Mon} {Tue} {Wed} {Thu} {Fri} {Sat}}
nsv_set locale en_US,abmon {{Jan} {Feb} {Mar} {Apr} {May} {Jun} {Jul} {Aug} {Sep} {Oct} {Nov} {Dec}}
nsv_set locale en_US,am_str "AM"
nsv_set locale en_US,currency_symbol "$"
nsv_set locale en_US,day {{Sunday} {Monday} {Tuesday} {Wednesday} {Thursday} {Friday} {Saturday}}
nsv_set locale en_US,firstdayofweek 0
nsv_set locale en_US,decimal_point "."
nsv_set locale en_US,d_fmt "%m/%d/%y"
nsv_set locale en_US,d_t_fmt "%a %B %d, %Y %r %Z"
nsv_set locale en_US,dlong_fmt "%B %d, %Y"
nsv_set locale en_US,dlongweekday_fmt "%A %B %d, %Y"
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
nsv_set locale en_US,formbuilder_time_format "HH12:MI AM"

# France
nsv_set locale fr_FR,abday {{dim} {lun} {mar} {mer} {jeu} {ven} {sam}}
nsv_set locale fr_FR,abmon {{jan} {fév} {mar} {avr} {mai} {jun} {jui} {aoû} {sep} {oct} {nov} {déc}}
nsv_set locale fr_FR,am_str ""
nsv_set locale fr_FR,currency_symbol "€"
nsv_set locale fr_FR,day {{dimanche} {lundi} {mardi} {mercredi} {jeudi} {vendredi} {samedi}}
nsv_set locale fr_FR,firstdayofweek 1
nsv_set locale fr_FR,decimal_point ","
nsv_set locale fr_FR,d_fmt "%d.%m.%Y"
nsv_set locale fr_FR,d_t_fmt "%a %d %B %Y %H:%M %Z"
nsv_set locale fr_FR,dlong_fmt "%d %B %Y"
nsv_set locale fr_FR,dlongweekday_fmt "%A %d %B %Y"
nsv_set locale fr_FR,frac_digits 2
nsv_set locale fr_FR,grouping {-1 -1 }
nsv_set locale fr_FR,int_curr_symbol "EUR "
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
nsv_set locale fr_FR,formbuilder_time_format "HH24:MI"

# Germany
nsv_set locale de_DE,abday {{Son} {Mon} {Die} {Mit} {Don} {Fre} {Sam}}
nsv_set locale de_DE,abmon {{Jan} {Feb} {Mär} {Apr} {Mai} {Jun} {Jul} {Aug} {Sep} {Okt} {Nov} {Dez}}
nsv_set locale de_DE,am_str ""
nsv_set locale de_DE,currency_symbol "€"
nsv_set locale de_DE,day {{Sonntag} {Montag} {Dienstag} {Mittwoch} {Donnerstag} {Freitag} {Samstag}}
nsv_set locale de_DE,firstdayofweek 1
nsv_set locale de_DE,decimal_point ","
nsv_set locale de_DE,d_fmt "%d.%m.%Y"
nsv_set locale de_DE,d_t_fmt "%a %d %B %Y %H:%M %Z"
nsv_set locale de_DE,dlong_fmt "%d %B %Y"
nsv_set locale de_DE,dlongweekday_fmt "%A %d %B %Y"
nsv_set locale de_DE,frac_digits 2
nsv_set locale de_DE,grouping {3 3 }
nsv_set locale de_DE,int_curr_symbol "EUR "
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
nsv_set locale de_DE,formbuilder_time_format "HH24:MI"

# Spain
nsv_set locale es_ES,abday {{dom} {lun} {mar} {mié} {jue} {vie} {sáb}}
nsv_set locale es_ES,abmon {{ene} {feb} {mar} {abr} {may} {jun} {jul} {ago} {sep} {oct} {nov} {dic}}
nsv_set locale es_ES,am_str ""
nsv_set locale es_ES,currency_symbol "€"
nsv_set locale es_ES,day {{domingo} {lunes} {martes} {miércoles} {jueves} {viernes} {sábado}}
nsv_set locale es_ES,firstdayofweek 1
nsv_set locale es_ES,decimal_point ","
nsv_set locale es_ES,d_fmt "%d/%m/%y"
nsv_set locale es_ES,d_t_fmt "%a %d %B %Y %H:%M %Z"
nsv_set locale es_ES,dlong_fmt "%d %B %Y"
nsv_set locale es_ES,dlongweekday_fmt "%A %d %B %Y"
nsv_set locale es_ES,frac_digits 0
nsv_set locale es_ES,grouping {-1 -1 }
nsv_set locale es_ES,int_curr_symbol "EUR "
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
nsv_set locale es_ES,formbuilder_time_format "HH24:MI"

# Danish
nsv_set locale da_DK,abday {{søn} {man} {tir} {ons} {tor} {fre} {lør}}
nsv_set locale da_DK,abmon {{jan} {feb} {mar} {apr} {maj} {jun} {jul} {aug} {sep} {okt} {nov} {dec}}
nsv_set locale da_DK,am_str ""
nsv_set locale da_DK,currency_symbol "kr"
nsv_set locale da_DK,day {{søndag} {mandag} {tirsdag} {onsdag} {torsdag} {fredag} {lørdag}}
nsv_set locale da_DK,firstdayofweek 1
nsv_set locale da_DK,decimal_point ","
nsv_set locale da_DK,d_fmt "%e/%m-%y"
nsv_set locale da_DK,d_t_fmt "%a %e. %B %Y %r %Z"
nsv_set locale da_DK,dlong_fmt "%e. %B %Y"
nsv_set locale da_DK,dlongweekday_fmt "%A den %e. %B %Y"
nsv_set locale da_DK,frac_digits 2
nsv_set locale da_DK,grouping {3 3 }
nsv_set locale da_DK,int_curr_symbol "DKK "
nsv_set locale da_DK,int_frac_digits 2
nsv_set locale da_DK,mon_decimal_point ","
nsv_set locale da_DK,mon_grouping {3 3 }
nsv_set locale da_DK,mon {{januar} {februar} {marts} {april} {maj} {juni} {juli} {august} {september} {oktober} {november} {december}}
nsv_set locale da_DK,mon_thousands_sep "."
nsv_set locale da_DK,n_cs_precedes 1
nsv_set locale da_DK,negative_sign "-"
nsv_set locale da_DK,n_sep_by_space 0
nsv_set locale da_DK,n_sign_posn             1
nsv_set locale da_DK,p_cs_precedes 1
nsv_set locale da_DK,pm_str ""
nsv_set locale da_DK,positive_sign ""
nsv_set locale da_DK,p_sep_by_space 0
nsv_set locale da_DK,p_sign_posn 1
nsv_set locale da_DK,t_fmt_ampm ""
nsv_set locale da_DK,t_fmt "%H:%M"
nsv_set locale da_DK,thousands_sep "."
nsv_set locale da_DK,formbuilder_time_format "HH24:MI"

# FI
nsv_set locale fi_FI,abday {{su} {ma} {ti} {ke} {to} {pe} {la}}
nsv_set locale fi_FI,abmon {{tammi} {helmi} {maalis} {huhti} {touko} {kesä}{heinä} {elo} {syys} {loka} {marras} {joulu}}
nsv_set locale fi_FI,am_str ""
nsv_set locale fi_FI,currency_symbol "€"
nsv_set locale fi_FI,day {{sunnuntai} {maanantai} {tiistai} {keskiviikko} {torstai} {perjantai} {lauantai}}
nsv_set locale fi_FI,firstdayofweek 1
nsv_set locale fi_FI,decimal_point ","
nsv_set locale fi_FI,d_fmt "%d.%m.%Y"
nsv_set locale fi_FI,d_t_fmt "%a, %d. %Bta %Y %H:%M %Z"
nsv_set locale fi_FI,frac_digits 2
nsv_set locale fi_FI,grouping {3 3 }
nsv_set locale fi_FI,int_curr_symbol "EUR "
nsv_set locale fi_FI,int_frac_digits 2
nsv_set locale fi_FI,mon_decimal_point ","
nsv_set locale fi_FI,mon_grouping {3 3 }
nsv_set locale fi_FI,mon {{tammikuu} {helmikuu} {maaliskuu} {huhtikuu} {toukokuu} {kesäkuu} {heinäkuu} {elokuu} {syyskuu} {lokakuu} {marraskuu} {joulukuu}}
nsv_set locale fi_FI,mon_thousands_sep " "
nsv_set locale fi_FI,n_cs_precedes 1
nsv_set locale fi_FI,negative_sign "-"
nsv_set locale fi_FI,n_sep_by_space 0
nsv_set locale fi_FI,n_sign_posn             1
nsv_set locale fi_FI,p_cs_precedes 1
nsv_set locale fi_FI,pm_str ""
nsv_set locale fi_FI,positive_sign ""
nsv_set locale fi_FI,p_sep_by_space 0
nsv_set locale fi_FI,p_sign_posn 1
nsv_set locale fi_FI,t_fmt_ampm ""
nsv_set locale fi_FI,t_fmt "%H:%M"
nsv_set locale fi_FI,thousands_sep " "
nsv_set locale fi_FI,dlong_fmt "%d. %Bta %Y"
nsv_set locale fi_FI,dlongweekday_fmt "%A, %d. %Bta %Y"
nsv_set locale fi_FI,formbuilder_time_format "HH24:MI"

# Poland pl_PL
nsv_set locale pl_PL,abday  {{Nd} {Pn} {Wt} {Åšr} {Czw} {Pt} {So}} 
nsv_set locale pl_PL,abmon  {{Sty} {Lut} {Mar} {Kwi} {Maj} {Cze} {Lip} {Sie} {Wrz} {PaÅº} {Lis} {Gru}}
nsv_set locale pl_PL,am_str ""
nsv_set locale pl_PL,currency_symbol "zÅ‚"
nsv_set locale pl_PL,day {{Niedziela} {PoniedziaÅ‚ek} {Wtorek} {Åšroda} {Czwartek} {PiÄ…tek} {Sobota}}
nsv_set locale pl_PL,decimal_point ","
nsv_set locale pl_PL,d_fmt "%d-%m-%y"  
nsv_set locale pl_PL,d_t_fmt "%d %B %Y %T %Z"
nsv_set locale pl_PL,frac_digits 2
nsv_set locale pl_PL,grouping {3 3 }
nsv_set locale pl_PL,int_curr_symbol "PLN "
nsv_set locale pl_PL,int_frac_digits 2
nsv_set locale pl_PL,mon_decimal_point ","
nsv_set locale pl_PL,mon_grouping {3 3 }
nsv_set locale pl_PL,mon {{StyczeÅ„} {Luty} {Marzec} {KwiecieÅ„} {Maj} {Czerwiec} {Lipiec} {SierpieÅ„} {WrzesieÅ„} {PaÅºdziernik} {Listopad} {GrudzieÅ„}}
nsv_set locale pl_PL,mon_thousands_sep " "
nsv_set locale pl_PL,n_cs_precedes 1
nsv_set locale pl_PL,negative_sign "-"
nsv_set locale pl_PL,n_sep_by_space 1
nsv_set locale pl_PL,n_sign_posn  1
nsv_set locale pl_PL,p_cs_precedes 1
nsv_set locale pl_PL,pm_str " "
nsv_set locale pl_PL,positive_sign ""
nsv_set locale pl_PL,p_sep_by_space 0
nsv_set locale pl_PL,p_sign_posn 1
nsv_set locale pl_PL,t_fmt_ampm "%H:%M:%S "
nsv_set locale pl_PL,t_fmt "%T"
nsv_set locale pl_PL,thousands_sep " "

# Russia
nsv_set locale ru_RU,abday {{âñ} {ïí} {âò} {ñð} {÷ò} {ïò} {ñá}}
nsv_set locale ru_RU,abmon {{ÿíâ} {ôåâ} {ìàð} {àïð} {ìàé} {èþí} {èþë} {àâã} {ñåí} {îêò} {íîÿ} {äåê}}
nsv_set locale ru_RU,am_str ""
nsv_set locale ru_RU,currency_symbol "ð."
nsv_set locale ru_RU,day {{âîñêðåñåíüå} {ïîíåäåëüíèê} {âòîðíèê} {ñðåäà} {÷åòâåðã} {ïÿòíèöà} {ñóááîòà}}
nsv_set locale ru_RU,decimal_point "."
nsv_set locale ru_RU,d_fmt "%d.%m.%y"
nsv_set locale ru_RU,d_t_fmt "%a %d %B %Y ã., %H:%M %Z"
nsv_set locale ru_RU,frac_digits 2
nsv_set locale ru_RU,grouping {3 3 }
nsv_set locale ru_RU,int_curr_symbol "RUB "
nsv_set locale ru_RU,int_frac_digits 2
nsv_set locale ru_RU,mon_decimal_point "."
nsv_set locale ru_RU,mon_grouping {3 3 }
nsv_set locale ru_RU,mon {{ÿíâàðü} {ôåâðàëü} {ìàðò} {àïðåëü} {ìàé} {èþíü} {èþëü} {àâãóñò} {ñåíòÿáðü} {îêòÿáðü} {íîÿáðü} {äåêàáðü}}
nsv_set locale ru_RU,mon_longdate {{ÿíâàðÿ} {ôåâðàëÿ} {ìàðòà} {àïðåëÿ} {ìàÿ} {èþíÿ} {èþëÿ} {àâãóñòà} {ñåíòÿáðÿ} {îêòÿáðÿ} {íîÿáðÿ} {äåêàáðÿ}}
nsv_set locale ru_RU,mon_thousands_sep " "
nsv_set locale ru_RU,n_cs_precedes 0
nsv_set locale ru_RU,negative_sign "-"
nsv_set locale ru_RU,n_sep_by_space 0
nsv_set locale ru_RU,n_sign_posn 1
nsv_set locale ru_RU,p_cs_precedes 0
nsv_set locale ru_RU,pm_str ""
nsv_set locale ru_RU,positive_sign ""
nsv_set locale ru_RU,p_sep_by_space 0
nsv_set locale ru_RU,p_sign_posn 1
nsv_set locale ru_RU,t_fmt_ampm ""
nsv_set locale ru_RU,t_fmt "%H:%M"
nsv_set locale ru_RU,thousands_sep " "

# The Netherlands (dutch)
nsv_set locale nl_NL,abday {{Zon} {Maan} {Dins} {Woens} {Donder} {Vrij} {Zater}}
nsv_set locale nl_NL,abmon {{Jan} {Feb} {Mrt} {Apr} {Mei} {Jun} {Jul} {Aug} {Sep} {Okt} {Nov} {Dec}}
nsv_set locale nl_NL,am_str ""
nsv_set locale nl_NL,currency_symbol "€"
nsv_set locale nl_NL,day {{Zondag} {Maandag} {Dinsdag} {Woensdag} {Donderdag} {Vrijdag} {Zaterdag}}
nsv_set locale nl_NL,firstdayofweek 1
nsv_set locale nl_NL,decimal_point ","
nsv_set locale nl_NL,d_fmt "%d.%m.%Y"
nsv_set locale nl_NL,d_t_fmt "%a %d %B %Y %H:%M %Z"
nsv_set locale nl_NL,dlong_fmt "%d %B %Y"
nsv_set locale nl_NL,dlongweekday_fmt "%A %d %B %Y"
nsv_set locale nl_NL,frac_digits 2
nsv_set locale nl_NL,grouping {3 3 }
nsv_set locale nl_NL,int_curr_symbol "EUR "
nsv_set locale nl_NL,int_frac_digits 2
nsv_set locale nl_NL,mon_decimal_point ","
nsv_set locale nl_NL,mon_grouping {3 3 }
nsv_set locale nl_NL,mon {{Januari} {Februari} {Maart} {April} {Mei} {Juni} {Juli} {Augustus} {September} {Oktober} {November} {December}}
nsv_set locale nl_NL,mon_thousands_sep "."
nsv_set locale nl_NL,n_cs_precedes 1
nsv_set locale nl_NL,negative_sign "-"
nsv_set locale nl_NL,n_sep_by_space 0
nsv_set locale nl_NL,n_sign_posn 1
nsv_set locale nl_NL,p_cs_precedes 1
nsv_set locale nl_NL,pm_str ""
nsv_set locale nl_NL,positive_sign ""
nsv_set locale nl_NL,p_sep_by_space 0
nsv_set locale nl_NL,p_sign_posn 1
nsv_set locale nl_NL,t_fmt_ampm ""
nsv_set locale nl_NL,t_fmt "%H:%M"
nsv_set locale nl_NL,thousands_sep "."
nsv_set locale nl_NL,formbuilder_time_format "HH24:MI"


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
