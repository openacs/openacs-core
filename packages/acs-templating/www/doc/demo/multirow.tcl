ad_page_contract {
  @cvs-id $Id$
  @datasource body multirow
  The sun and planets of our solar system
  @column name "Sun" or name of the planet.
  @column diameter body diameter.
  @column mass mass of the celestial body.
  @column r_orbit orbit radius
} -properties {
  users:multirow
}

template::multirow create body name     diameter mass        r_orbit

template::multirow append body "Sun"     1391900 1.989e30      "N/A"
template::multirow append body "Mercury"    4866 3.30e23    57950000
template::multirow append body "Venus"     12106 4.869e24  108110000
template::multirow append body "Earth"     12742 5.9736e24 149570000
template::multirow append body "Mars"       6760 6.4219e23 227840000
