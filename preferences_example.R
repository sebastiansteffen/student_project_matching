# Fake Student Preferences.

emails <- c(
  'foo@gmail.com',
  'bar@yahoo.com',
  'foobar@mit.edu'
)

first_names <- c(
  'Foo',
  'Bar',
  'Foobar'
)

pref_order <- list()
pref_order[['Foo Foo']]	<- c('Bar Bar',	'Foobar Foobar')
pref_order[['Bar Bar']]	<- c('Foobar Foobar',	'Foo Foo')
pref_order[['Foobar Foobar']]	<- c('Baar Bar',	'Foo Foo')

