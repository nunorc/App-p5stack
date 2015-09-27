package App::p5stack;
# ABSTRACT: manage your dependencies and perl requirements locally

use strict;
use warnings;

use Cwd;
use File::Which;
use File::Basename;
use File::Spec::Functions;
use File::Path qw/make_path/;
use Path::Tiny;
use Archive::Tar;
use Data::Dumper;
use YAML;

sub new {
  my ($class, @argv) = @_;
  my $self = bless {}, $class;

  $self->{orig_argv} = [@argv];
  $self->{command} = @argv ? lc shift @argv : '';
  $self->{argv} = [@argv];

  # handle config
  $self->_do_config;

  return $self;
}

sub run {
  my ($self) = @_;

  if ($self->{command} eq 'setup') { $self->_do_setup; }
  elsif ($self->{command} eq 'perl') { $self->_do_perl; }
  elsif ($self->{command} eq 'cpanm') { $self->_do_cpanm; }
  elsif ($self->{command} eq 'bin') { $self->_do_bin; }
  else { $self->_do_help; }
}

sub _do_config {
  my ($self) = @_;

  # set some defaults
  $self->{perl} = 'system';
  $self->{deps} = 'dzil';
  $self->{skip_install} = 1;
  $self->{perls_root} = catfile($ENV{HOME},'.p5stack','perls');
  $self->{perl_version} = '5.20.3';

  # guess stuff from context
  $self->{deps} = 'cpanfile' if -e 'cpanfile';

  # read config from file if available
  my $file;
  -e 'p5stack.yml' and $file = 'p5stack.yml';
  -e "$ENV{HOME}.p5stack/p5stack.yml" and $file = "$ENV{HOME}.p5stack/p5stack.yml";  # FIXME
  $ENV{P5STACKCFG} and $file = $ENV{P5STACKCFG};

  my $config;
  if ($file) {
    my $yaml = path($file)->slurp_utf8;
    $config = Load $yaml;
  }

  # FIXME re-factor after logic is more stable
  if ( file_name_is_absolute($config->{perl}) ) {
    $self->{perl_version} = _get_perl_version($config->{perl});
    $self->{perl} = $config->{perl};
  }
  if ( $self->{perl} eq 'system' ) {
    $self->{perl} = which 'perl';
    $self->{perl_version} = _get_perl_version($self->{perl});
  }
  if ( exists($config->{perl}) and $config->{perl} =~ m/^[\d\.]+$/ ) {
    $self->{perl_version} = $config->{perl};
    my $perl = catfile($self->{perls_root},$config->{perl},'bin','perl');
    $self->{perl} = $perl;

    $self->{skip_install} = 0 unless -e $perl;
  }
  for (qw/deps/) {
    $self->{$_} = $config->{$_} if exists $config->{$_};
  }

  # set more stuff
  $self->{home} = getcwd;
  $self->{local_lib} = catfile($self->{home},'.local',$self->{perl_version});
  $self->{local_bin} = catfile($self->{home},'.local',$self->{perl_version},'bin');
  $self->{Ilib} = catfile($self->{home},'.local',$self->{perl_version},'lib','perl5');
}

sub _do_setup {
  my ($self) = @_;

  _log('Hammering setup ...');

  $self->_do_install_perl_release;

  system "curl -s -L https://cpanmin.us | $self->{perl} - -l $self->{local_lib} --reinstall --no-sudo App::cpanminus local::lib";

  _log('Installing dependencies ...');
  my $cpanm = $self->_get_cpanm;

  if ($self->{deps} eq 'dzil') {
    my $dzil = which 'dzil';
    $self->_do_cpanm("Dist::Zilla") unless $dzil;

    unless (-e 'dist.ini') {
      _log('Configuration is set to use "dzil" to gather dependencies information, but no "dist.ini" file was found in current directory.. exiting.');
      exit;
    }
    system "$dzil listdeps | $cpanm --no-sudo -l $self->{local_lib}";
  }
  if ($self->{deps} eq 'cpanfile') {
    unless (-e 'cpanfile') {
      _log('Configuration is set to use "cpanfile" to gather dependencies information, but no "cpanfile" file was found in current directory.. exiting.');
      exit;
    }
    $self->_do_cpanm("--installdeps .");
  }

  print "[p5stack] Setup done, use 'p5stack perl' to run your application.\n";
}

sub _get_cpanm {
  my ($self) = @_;

  my $cpanm = catfile($self->{local_lib}, 'bin', 'cpanm');
  $cpanm = which 'cpanm' unless $cpanm;  # FIXME default to system?

  return $cpanm;
}

sub _do_install_perl_release {
  my ($self) = @_;

  if (-e $self->{perl}) {
    _log("Found $self->{perl_version} release using it.");
    return;
  }

  my $curl = which 'curl';  # TODO failsafe to wget ?
  my $file = join '', 'perl-', $self->{perl_version}, '.tar.gz';
  my $dest = catfile($self->{perls_root}, $file);
  my $url = join '', 'http://www.cpan.org/src/5.0/', $file;

  _log("Downloading $self->{perl_version} release ...");
  make_path(dirname($dest)) unless -e dirname($dest);;
  system "$curl -s -o $dest $url" unless -e $dest;

  my $curr = getcwd;
  chdir $self->{perls_root};

  _log("Extracting $self->{perl_version} release ...");
  #Archive::Tar->extract_archive($file);

  chdir catfile($self->{perls_root}, "perl-$self->{perl_version}");
  
  _log("Configuring $self->{perl_version} release ...");
  my $prefix = catfile($self->{perls_root}, $self->{perl_version});
  system "sh Configure -de -Dprefix=$prefix > /tmp/p5stack-setup.log 2>&1";

  _log("Building $self->{perl_version} release ...");
  system "make >> /tmp/p5stack-setup.log 2>&1";

  _log("Testing $self->{perl_version} release ...");
  system "make test >> /tmp/p5stack-setup.log 2>&1";

  _log("Installing $self->{perl_version} release ...");
  system "make install >> /tmp/p5stack-setup.log 2>&1";

}

sub _do_perl {
  my ($self) = @_;

  my $run = join(' ',$self->{perl}, "-I $self->{Ilib}",
              "-Mlocal::lib", @{$self->{argv}});
  print $run, "\n";
  #system $run;
}

sub _do_cpanm {
  my ($self) = @_;

  my $cpanm = $self->_get_cpanm;
  my $run = join(' ',$cpanm, "--no-sudo -l $self->{local_lib}", @{$self->{argv}});
  system $run;
}

sub _do_bin {
  my ($self) = @_;

  my @argv = @{ $self->{argv} };
  my $bin = catfile($self->{local_bin}, shift @argv);
  my @env = ("PERL5LIB=$self->{Ilib}", "PATH=$self->{local_bin}:\$PATH");
  my $run = join ' ', @env, $bin, @argv;

  system $run;
}

sub _get_perl_version {
  my ($perl) = @_;

  my $version = `$perl -e 'print \$^V'`;
  $version =~ s/^v//;

  return $version;
}

sub _log {
  my ($msg) = @_;

  # FIXME smaller timestamp
  my $now = localtime;
  $now =~ s/\s\d+$//;
  $now =~ s/^\w+/-/;

  print "[p5stack $now] $msg\n";
}

sub _do_help {
  print "Usage:\n",
    "  \$ p5stack setup                  # setup env in current directory\n",
    "  \$ p5stack perl <program> [args]  # run a program\n",
    "  \$ p5stack bin <file> [args]      # execute a installed bin file\n",
    "  \$ p5stack cpanm [args]           # execute local env cpanm\n";
}

1;

__END__

=encoding UTF-8

=head1 SYNOPSIS

B<Warning>: this tool is still under development and badly tested, use
with care!

Manage your dependencies and perl requirements locally, by projects (directory).

    # set up configuration in your application directory
    $ cat > p5stack.yml
    ---
    perl: 5.20.3
    deps: dzil

    # setup the environment
    $ p5stack setup

    # run your application
    $ p5stack perl <application>

    # execute an installed program for this environment
    $ p5stack bin <program>

=head1 DESCRIPTION

p5stack is a tool that given a small set of configuration allows to quickly
(in a single command) setup the required modules inside a local directory
specific to this project. Including a specific perl version if required.
This allows to constrain all the required elements to run your application
to live inside the application directory. And thus not clashing to system
wide perl installations.

Configuration files are written in YAML, an example configuration looks
like:

    ---
    perl: 5.20.3
    deps: dzil

This tells p5stack that you want to use perl version 5.20.3, and to use
dzil to find the required modules for the application. By default all
perl versions are installed inside $HOME/.p5stack, and all the required
modules are install in a .local directory. This way you can share perl
releases installations, but have a local directory with the required
modules for each project.

=head1 EXAMPLE OF USE

Creating a new project using Dancer:

    $ dancer2 -a webapp
    + webapp
    (...)

Setup the application environment, since the Dancer new application
utility creates a cpanfile, we can use that to set up the application
environment (remember to update cpanfile:

    $ cd webapp
    webapp$ cat > p5stack.yml
    ---
    perl: 5.22.0
    deps: cpanfile
    webapp$ p5stack setup

After the setup is done, a perl 5.22.0 has been install in $HOME/.p5stack
and all the require modules have been install in .local inside your
project. We can run the application using:

    webapp$ p5stack bin plackup bin/app.psgi 
    HTTP::Server::PSGI: Accepting connections at http://0:5000/

=head1 CONFIGURATION

The currently available configuration attributes are:

=over 4

=item

C<perl> defines the required perl version to run the application (eg. 5.20.3,
5.22.0); you can also use an absolute path, or the special keyword I<system>
which will use the corresponding perl.

=item

C<deps> is used to set define how to gather dependencies information, current
available options are:

=over 4

=item

C<dzil>

=item

C<cpanfile>

=back

=item

C<localperl> if set, the required perl is installed in .local inside your
directory project (not implemented yet).

=back

You can write the configuration in a C<pstack.yml> file in your project
directory, have a C<$HOME/.p5stack/p5stack.yml> configuration file,
or use the environment variable I<P5STACKCFG> to define where the configuration
file is.

=head1 FUTURE WORK

=over 4

=item

Allow other options to set up local lib (eg. carton).

=item

More tests.

=back

=head1 CONTRIBUTORS

=over 4

=item

Alberto Simões

=back

