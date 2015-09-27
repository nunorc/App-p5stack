# NAME

App::p5stack - manage your dependencies and perl requirements locally

# VERSION

version 0.001

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

# EXAMPLE OF USE

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

# CONFIGURATION

The currently available configuration attributes are:

- `perl` defines the required perl version to run the application (eg. 5.20.3,
5.22.0); you can also use an absolute path, or the special keyword _system_
which will use the corresponding perl.
- `deps` is used to set define how to gather dependencies information, current
available options are:
    - `dzil`
    - `cpanfile`
- **localperl** if set, the required perl is installed in .local inside
your directory project (not implemented yet).

You can write the configuration in a `pstack.yml` file in your project
directory, have a `$HOME/.p5stack/p5stack.yml` configuration file,
or use the environment variable _P5STACKCFG_ to define where the configuration
file is.

# FUTURE WORK

- Allow other options to set up local lib (eg. carton).
- More tests.

# CONTRIBUTORS

- Alberto Simões

# AUTHOR

Nuno Carvalho <smash@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Nuno Carvalho.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

# POD ERRORS

Hey! **The above document had some coding errors, which are explained below:**

- Around line 113:

    Expected '=item \*'
