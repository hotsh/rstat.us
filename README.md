rstat.us
========

rstat.us is a microblogging site built on top of the [ostatus
protocol](http://status.net/wiki/OStatus).

## Helping out with rstat.us

If you'd like to contribute, here's some details:

- Here's the stack: ruby/sinatra/mongodb
- Here's [the code](http://github.com/hotsh/rstat.us)
- Here's [the documentation](http://hotsh.github.com/rstat.us/) (need
  lots of improvment here!)
- Here's [the Issues list](http://github.com/hotsh/rstat.us/issues)
- Please fork the project and make a pull request
-- Pull requests will not be merged without tests/documentation
--- We use [minitest](https://github.com/seattlerb/minitest)/[capybara](https://github.com/jnicklas/capybara) for tests
--- We use [docco](https://github.com/jashkenas/docco) (rocc) for
documentation
--- If you think it doesn't need a test, make your case, I'm just
saying.

Setting up a dev environment
----------------------------

First off: you will need MongoDB (www.mongodb.org).  They have a [quickstart guide](http://www.mongodb.org/display/DOCS/Quickstart) for getting it installed and running.

Then do the same as above:

    $ git clone https://github.com/$MY_GITHUB_USERNAME/rstat.us.git
    $ cd rstat.us

Copy the config file; if you have actual Twitter API keys, you can add yours, but this file just needs to exist for the server to work.

    $ cp config.yml.sample config.yml

Then update your gemset:

    $ gem install bundler && bundle install

Start the server with rackup:

    $ rackup

Bam! Visit http://localhost:9292/ in your browser, and you'll be good.
    
Compiling CSS and Javascript
----------------------------

For performance reasons, we're currently compressing our stylesheets and javascripts, as well as embedding what images we can. To compile Coffeescript (.coffee) or Sassy CSS (.scss) files for the site to use, use the following rake task:

    $ rake assets:compile

Running your own node
---------------------

If you need help with this, then you're not ready to run one.
Eventually, we plan on making this _super easy_, but until we feel that
it's ready, we're keeping the instructions 'secret.' Sorry!
