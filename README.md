rstat.us
========

rstat.us is a microblogging site built on top of the [ostatus
protocol](http://status.net/wiki/OStatus).

## Helping out with rstat.us

If you'd like to contribute, here are some details:

- The stack: ruby/sinatra/mongodb
- [The code][code]
- [The documentation][docs] (need lots of improvement here!)
- [The Issues list][issues], currently being moved to lighthouse from
  github.
- Please fork the project and make a pull request
  - Pull requests will not be merged without tests/documentation
    - We use [minitest][minitest]/[capybara][capy] for tests
    - We use [docco][docco] (rocc) for documentation
    - If you think it doesn't need a test, make your case, I'm just saying.

[code]: http://github.com/hotsh/rstat.us
[docs]: http://hotsh.github.com/rstat.us/
[issues]: http://rstatus.lighthouseapp.com/
[minitest]: https://github.com/seattlerb/minitest
[capy]: https://github.com/jnicklas/capybara
[docco]: https://github.com/jashkenas/docco


Setting up a dev environment
----------------------------

First off: you will need MongoDB (www.mongodb.org).  They have a [quickstart
guide][mongo-quickstart] for getting it installed and running.

Then do:

    $ git clone https://github.com/$MY_GITHUB_USERNAME/rstat.us.git
    $ cd rstat.us

Copy the config file; if you have actual Twitter API keys, you can add yours,
but this file just needs to exist for the server to work.

    $ cp config.yml.sample config.yml

Then update your gemset:

    $ gem install bundler && bundle install

And start the server:

    $ rackup

Bam! Visit http://localhost:9292/ in your browser, and you'll be good.
   
[mongo-quickstart]: http://www.mongodb.org/display/DOCS/Quickstart

Compiling CSS and Javascript
----------------------------

We use Coffeescript (.coffee) or Sassy CSS (.scss) for javascript and CSS development 
respectively. When running the site locally, these files will automatically be
compiled by the application when requested.

When preparing for deployment, we compress our stylesheets and javascripts, as 
well as embedding what images we can. To compile Coffeescript and SCSS,
use the following rake task:

    $ rake assets:compile

Note: This relies on some sort of coffee compiler being installed globally.  If
you get "undefined method 'compile' for nil:NilClass", that might be your
problem.  On Ubuntu, installing the nodejs package fixes this; for other
systems, check out [nodejs.org][node].

For coffee-script installation, [check the docs][coffee-install].

You may also need the java runtime for asset compression, which is handled by
jammit using yui compressor and closure compiler. Installing a JDK, such as
[OpenJDK][openjdk] should do the trick.

[node]: http://nodejs.org
[coffee-install]: http://jashkenas.github.com/coffee-script/#installation
[openjdk]: http://openjdk.java.net/

Running your own node
---------------------

If you need help with this, then you're not ready to run one.
Eventually, we plan on making this _super easy_, but until we feel that
it's ready, we're keeping the instructions 'secret.' Sorry!
