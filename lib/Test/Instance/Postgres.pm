package Test::Instance::Postgres;

use Moo;
use File::Temp;
use File::Spec;
use IPC::System::Simple qw/ capture /;
use Net::EmptyPort qw/ empty_port /;

use namespace::clean;

our $VERSION = '0.001';

has _temp_dir => (
  is => 'lazy',
  builder => sub {
    return File::Temp->newdir;
  },
);

has server_root => (
  is => 'lazy',
  builder => sub {
    my $self = shift;
    return $self->_temp_dir->dirname;
  },
);

has db_dir => (
  is => 'lazy',
  builder => sub {
    my $self = shift;
    return File::Spec->catfile( $self->server_root, 'db' );
  },
);

has log_file => (
  is => 'lazy',
  builder => sub {
    my $self = shift;
    return File::Spec->catfile( $self->server_root, 'pg.log' );
  },
);

has listen_port => (
  is => 'lazy',
  builder => sub {
    return empty_port;
  },
);

has username => (
  is => 'lazy',
  builder => sub { 'postgres' },
);

has pg_ctl => (
  is => 'lazy',
  builder => sub { '/usr/lib/postgresql/9.5/bin/pg_ctl' },
);

has dsn => (
  is => 'lazy',
  builder => sub {
    my $self = shift;
    return sprintf( 'dbi:Pg:dbname=%s;host=%s;port=%s', 'postgres', 'localhost', $self->listen_port );
  },
);

sub _init_db_cmd {
  my $self = shift;

  return join( ' ', $self->pg_ctl,
    'initdb',
    "-o '--auth=trust",
    '--username=' . $self->username,
    "' --pgdata=" . $self->db_dir,
  );
};

sub _base_cmd {
  my $self = shift;

  return sprintf( "%s --pgdata=%s --log=%s -o '--port=%s -k %s'",
    $self->pg_ctl,
    $self->db_dir,
    $self->log_file,
    $self->listen_port,
    $self->server_root,
  );
}

sub run_cmd {
  my $self = shift;
  my $cmd = shift;
  my $wait = shift;

  $cmd = join ( ' ', '-w', $cmd ) if defined $wait;

  my $full_cmd = join ( ' ', $self->_base_cmd, $cmd );
  capture( $full_cmd );
}

sub run {
  my $self = shift;

  capture( $self->_init_db_cmd );
  $self->run_cmd( 'start', 'wait' );
}

sub DEMOLISH {
  my $self = shift;

  #TODO Double check its dead, kill it if needed
  $self->run_cmd( 'stop', 'wait' );
}

1;
