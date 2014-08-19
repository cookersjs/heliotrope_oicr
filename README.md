Heliotrope
==========

Heliotrope is an integrated clinical genomics application, developed as the next generation of our
system for managing clinical genomics trials, as described in
[Clinical genomics information management software linking cancer genome sequence and clinical decisions](http://www.ncbi.nlm.nih.gov/pubmed/23603536).

This second-generation implementation provides the following features:

*  A configurable tracking system, able to log actions to participants, samples, and observed variants
*  A flexible knowledge base, with information on genes and most frequent mutations
*  High-quality variant reports generated automatically
*  Knowledge base annotation, allowing clinical publication information to be attached to known variants
*  Direct import of sample results from VCF files

Heliotrope depends on these technologies:

*  node.js -- web server, providing core server systems (tested with node 0.10.7)
*  MongoDB -- data storage for the knowledge base and tracking system (tested with MongoDB 2.4.3)
*  Perl -- used to build the initial primary knowledge base from exterbal sources (tested with Perl 5.16.1)
*  Java runtime -- used by the reporting system to generate PDF files (tested with Oracle Java 1.7.0_11)


Installation
------------

Before you install, you'll need fairly recent versions of [node.js](https//nodejs.org/) and
[Vagrant](http://www.vagrantup.com/‎).

*  Java
*  [node.js](https//nodejs.org/)

```shell
$ git clone git@github.com:oicr-ibc/heliotrope.git
$ cd heliotrope
$ npm install
$ bower install
$ node_modules/gulp/bin/gulp serve
```

For an easy start, use [VirtualBox](https://www.virtualbox.org/‎)
to set up a quick virtual machine. You can also use [Ansible](http://www.ansible.com) to deploy to
a virtual machine hosted elsewhere, either on your own local network, or using some cloud provider.

*  [Vagrant](http://www.vagrantup.com/‎)
*  [VirtualBox](https://www.virtualbox.org/‎)

```shell
$ git clone git@github.com:oicr-ibc/heliotrope.git
$ cd heliotrope
$ npm install
$ bower install
$ node_modules/gulp/bin/gulp build-all
$ node_modules/gulp/bin/gulp dist
$ vagrant up
```

This will automatically install all dependencies, and will assemble a local virtual machine with a complete
knowledge base data package. You can then connect to this in your local browser at: https://localhost:8443/.
An initial user is created with the username `admin` and password `admin` -- you can use this to create more
users and configure studies as you choose, as well as to annotate the knowledge base.

It's also fairly simply to build a Debian package. Again, this uses [Ansible](http://www.ansible.com). There is
a second playbook that provisions a minimal setup and prepares a Debian package, then copies that package
back to the current directory. The commands needed to build a Debian package are:

```shell
$ git clone git@github.com:oicr-ibc/heliotrope.git
$ cd heliotrope
$ npm install
$ bower install
$ node_modules/gulp/bin/gulp build-all
$ node_modules/gulp/bin/gulp dist
$ vagrant up --no-provision
$ ansible-playbook -v -i .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory --private-key=~/.vagrant.d/insecure_private_key -u vagrant packaging.yml
```

Note that the Debian package does not include or even depend on MongoDB, although Heliotrope does. So
to install this Debian package you'll need to install MongoDB separately, and first. When you have copied
over the Debian package, you can use a script like this.

```shell
$ sudo apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10
$ echo 'deb http://downloads-distro.mongodb.org/repo/debian-sysvinit dist 10gen' | sudo tee /etc/apt/sources.list.d/mongodb.list
$ sudo apt-get update
$ sudo apt-get install -y mongodb-org
$ sudo apt-get install -y adduser daemon psmisc nginx-light libc6 ssl-cert
$ sudo dpkg -i -n heliotrope_0.1.0_amd64.deb
```

Initializing the knowledge base
-------------------------------

Before Heliotrope can work effectively, it is a good idea to initialize the knowledge base. This takes a good
few hours, and requires a number of other dependencies. In particular, it requires the Ensembl variant
effect predictor (VEP), which itself requires a copy of the human reference genome hg19 and databases for
SIFT and PolyPhen annotation of variants.

For basic use, we recommend you download one of our [pre-built knowledge base packs](https://github.com/oicr-ibc/heliotrope/wiki/Knowledge-base).
You can built your own using the scripts in `etc/scripts`, but it is a fairly slow process, likely to take at least
8-10 hours from start to finish.

The knowledge base initialization system is primarily written in Perl. Most recent Perl versions should be
able to do this, with the right modules installed, but it is usually a good idea to build a clean one using
`perlbrew`, mostly to avoid OS Perl contamination.

Heliotrope currently includes adapters to read and draw on the following information sources when constructing
its knowledge base:

*  Boot -- always used first
*  Ensembl -- always used next, primary gene information source
*  COSMIC -- used to calculate variant frequencies
*  Entrez -- used as a source for gene descriptions
*  Sanger Cancer Gene Census -- cancer-specific gene-level annotation

Note that COSMIC and the Sanger Cancer Gene Census now requires authentication to access the data, and the
previous automated download processes no longer work. Instead, COSMIC and Sanger Cancer Gene Census files
need to be downloaded manually. This part of the knowledge base construction is a work in progress.


Security
--------

Heliotrope uses separate databases for the tracking system (which may contain confidential patient-level information) and for the knowledge base (which
is derived entirely from public sources and curation).

Authentication is based on LDAP.


