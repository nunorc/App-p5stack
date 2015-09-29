# NAME

App::p5stack - manage your dependencies and perl requirements locally

# VERSION

version 0.002

# SYNOPSIS

**Warning**: this tool is still under development and badly tested, use
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

# DESCRIPTION

p5stack is a tool that given a small set of configuration directives allows to
quickly (in a single command) setup the required modules inside a local directory
specific to this project. Including a specific perl version if required. This
allows to constrain all the required elements to run your application to live
inside the application directory. And thus not clashing to system wide perl
installations.

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

After setting up the environment with the required perl and modules
using the _setup_ command:

    $ p5stack setup

You can run a command using the environment using:

    $ p5stack perl <program>

Or execute a program installed by a module using:

    $ p5stack bin <program>

You system perl and other possible installations remain unchanged.

The local installation of modules is done using 
[App-cpanminus](http://search.cpan.org/dist/App-cpanminus/)
and [local-lib](http://search.cpan.org/dist/local-lib/).

# EXAMPLES OF USE

## Simple Example

Imagine a very simple project:

    $ ls -A
    dist.ini  ex1

which contains a script:

    $ cat ex1
    #!/usr/bin/perl
    
    use Acme::123;

    Acme::123->new->printnumbers;

that requires the Acme::123 module, as described in this simple dzil file:

    $ cat dist.ini 
    name = ex1

    [Prereqs]
    Acme::123 = 0

To setup the environment to run this using p5stack just run the tool with
the setup command:

    $ p5stack setup
    [p5stack - Sep 28 23:58:19] Hammering setup ...
    (...)

Since there is no configuration file for p5stack, by default the sytem perl
is used. And a directory _.local_ is created to install all the required
modules. The list of required dependencies is gathered using dzil by default
(or a cpanfile if available).

    $ ls -A
    .local  dist.ini  ex1

To run the simple application, just use the _p5stack perl_ command:

    $ p5stack perl ex1 
    one 
    two 
    three 
    (...)

## Dancer Example

[Dancer](http://perldancer.org) is a popular framework for building
site. Creating a new project using Dancer can be done as:

    $ dancer2 -a webapp
    + webapp
    (...)

This will create a directory called _webapp_ with a bunch of files
inside. One of these files is a _cpanfile_ that stores the required
modules to run the bootstrap application. To setup this new environment
to run the application just _cd_ into the new directory and run:

    $ cd webapp
    webapp$ p5stack setup

By default p5stack will use your system perl, and will use the cpanfile
to install in a _.local_ directory inside your application the required
dependencies to run the application.

You may require other perl version to use an application. You can write a
configuration file, and define what version you require. For example:

    $ cat > p5stack.yml
    ---
    perl = 5.22.0

You need to run the setup again to install the new perl version and
dependencies.
After the setup is done, a perl 5.22.0 has been install in _$HOME/.p5stack_
and all the require modules have been installed in _.local_ inside your
project.

We can run the application using:

    webapp$ p5stack bin plackup bin/app.psgi 
    HTTP::Server::PSGI: Accepting connections at http://0:5000/

# COMMANDS

p5stack tool is executed using commands like:

    $ p5stack <command> [args]

Available commands for p5stack are:

- `setup`: build and setup the environment.
- `perl`: run a perl interpreter.
- `bin`: run a program installed by the setup in the environment.
- `cpanm`: run _cpanm_ in the context of your application environment.
- `help`: show small help info.

# CONFIGURATION

The currently available configuration attributes are:

- `perl` defines the required perl version to run the application (eg. 5.20.3,
5.22.0); you can also use an absolute path, or the special keyword _system_
which will use the system wide perl found (using _which_).
- `deps` is used to define how to gather dependencies information, current
available options are:
    - `dzil`: uses _dzil listdeps_ to find out the list of requirements.
    - `cpanfile`: _cpanm_ reads this file directly.
- `localperl` if set, the required perl is installed in .local inside your
directory project (not implemented yet).

You can write the configuration in a `pstack.yml` file in your project
directory, have a `$HOME/.p5stack/p5stack.yml` configuration file,
or use the environment variable _P5STACKCFG_ to define where the configuration
file is.

# FUTURE WORK

- Allow other options to set up local lib (eg. carton, DX).
- More tests.

# ACKNOWLEDGMENTS

Thank you to the authors and contributors of
[App-cpanminus](http://search.cpan.org/dist/App-cpanminus/)
and [local-lib](http://search.cpan.org/dist/local-lib/).

Inspired by [The Haskell Tool Stack](https://github.com/commercialhaskell/stack).

# CONTRIBUTORS

Alberto Simões <ambs@cpan.org>

# AUTHOR

Nuno Carvalho <smash@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Nuno Carvalho.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
