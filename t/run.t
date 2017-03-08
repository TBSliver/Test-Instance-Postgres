use strict;
use warnings;

use Test::More;
use Test::Instance::Postgres;

use DBI;

my $instance = Test::Instance::Postgres->new;

$instance->run;

my $dbh = DBI->connect( $instance->dsn, $instance->username );

ok $dbh, 'Got a dbh';

done_testing;
