rstat.us
========

rstat.us is a microblogging site built on top of the [ostatus
protocol](http://status.net/wiki/OStatus).

Running your own (on Heroku)
----------------------------

You will need a validated heroku account.

Just do this:

    $ git clone https://github.com/hotsh/rstat.us.git
    $ cd rstat.us
    $ heroku create --stack bamboo-mri-1.9.2
    $ heroku addons:add mongohq:free
    $ heroku addons:add sendgrid:free
    $ git push heroku master

Bam!

# BUT DON"T YET!!!!1111

This is nowhere near done. Jump on Freenode and ping 'steveklabnik' if
you want to contribute in some way.

Running a local copy
--------------------

First off: you will need MongoDB (www.mongodb.org).  They have a [quickstart guide](http://www.mongodb.org/display/DOCS/Quickstart) for getting it installed and running.

Then do the same as above:

    $ git clone https://github.com/hotsh/rstat.us.git (or your own fork, if applicable)
    $ cd rstat.us

Copy the config file; if you have actual Twitter API keys, you can add yours, but this file just needs to exist for the server to work.

    $ cp config.yml.sample config.yml

Then update your gemset:

    $ gem install bundler && bundle install

And instead of using heroku, start the server with sinatra:

    $ rackup
