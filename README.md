ZeroVM Validator
================

[![Build Status](http://ci.oslab.cc/job/zvm-validator/badge/icon)](http://ci.oslab.cc/job/zvm-validator/)

The ZeroVM Validator for the linux x86-64 platform is derived from the
Native Client (NaCl) project.

The `rdtsc` instruction has been moved to the "blacklist". Unlike other
blacklisted instructions, `rdtsc` is replaced with nops (not halts).

To make validator (release version) run:

    $ make validator

To clean validator run:

    $ make clean

To put validator shared library, standalone validator and stubout
utility to toolchain folder run:

    $ make install

Altogether can be done with:

    $ make clean validator install


Packaging
---------

Validator includes artifacts for creating debian packages. Packages can be
generated using the following steps.

1. To create a package from source, you'll first need to install a couple of
   developer utility packages:

        $ sudo apt-get install devscripts debhelper

2. Clone source from git. Example:

        $ git clone https://github.com/zerovm/validator.git $HOME/validator

3. From the working copy, take a snapshot of the HEAD version of repo and save
   it to the parent directory (in this example, $HOME), then gzip it:

         $ cd $HOME/validator
         $ tar czf ../zvm-validator_0.9-<some-release>.orig.tar.gz

4. Compile and build the package:

         $ debuild # specify -S to build a source package

   This will output the package artifacts into the parent directory.
