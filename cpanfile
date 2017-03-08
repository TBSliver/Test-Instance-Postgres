requires 'Net::EmptyPort';
requires 'Moo';

on test => sub {
  requires 'Test::More', '0.96';
  requires 'Test::Exception';
  requires 'DBI';
  requires 'DBD::Pg';
};
