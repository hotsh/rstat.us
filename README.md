rstat.us
========

rstat.us is a microblogging site built on top of the [ostatus
protocol](http://status.net/wiki/OStatus).

Running your own (on Heroku)
----------------------------

Just do this:

    $ git clone https://github.com/hotsh/rstat.us.git
    $ cd rstat.us
    $ heroku create
    $ git push heroku master

Bam!

# BUT DON"T YET!!!!1111

This is nowhere near done. Jump on Freenode and ping 'steveklabnik' if
you want to contribute in some way.

Running a local copy
--------------------

You need MongoDB (www.mongodb.org).  On Mac OSX, I had to unzip the tarball and do the following:

    $ cd mongodb-osx-x86_64-1.8.0
    $ sudo mkdir /data && sudo mkdir /data/db
    $ sudo bin/mongod &

Then do the same as above:

    $ git clone https://github.com/hotsh/rstat.us.git (or your own fork, if applicable)
    $ cd rstat.us

But instead of using heroku, run it with sinatra:

    $ gem install bundler && bundle install
    $ rackup
