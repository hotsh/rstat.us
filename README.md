<pre>
               .            .
 .___    ____ _/_     ___  _/_     ,   .   ____
 /   \  (      |     /   `  |      |   |  (
 |   '  `--.   |    |    |  |      |   |  `--.
 /     \___.'  \__/ `.__/|  \__/ / `._/| \___.'

</pre>

rstat.us is a microblogging site built on top of the [ostatus
protocol](http://status.net/wiki/OStatus).

The differences between rstat.us and other microblogging networks are
*simplicity* and *openness*.

*Simplicity* is a core 'feature' of rstat.us. We pride ourselves on saying
'no' to lots of features. Our interface is clean, and easy to understand. We
give you just enough features to be interesting, but not enough to be
complicated and confusing.

*Openness* means the programming code that makes up rstat.us is available for
anyone to download, free of charge. Programmers can use that code to run their
own websites just like rstat.us, and you can subscribe to your friends on any
site that supports the OStatus protocol, like identi.ca. This also means that
you can own your data; we'll never stop you from having full access to
everything you've put into rstat.us.

[![Build Status](https://secure.travis-ci.org/hotsh/rstat.us.png?branch=master)](http://travis-ci.org/hotsh/rstat.us)

Quick facts and links
---------------------

- The stack: ruby/rails 3.2/mongodb
- [The code][code]
- [The documentation][docs] (We could use lots of improvement here!)
- [The Issues list][issues]
- Tests are written using [minitest][minitest] and [capybara][capy]
- Documentation is generated using [docco][docco] (rocco)

[code]: http://github.com/hotsh/rstat.us
[docs]: http://hotsh.github.com/rstat.us/
[issues]: http://github.com/hotsh/rstat.us/issues
[flow]: http://scottchacon.com/2011/08/31/github-flow.html
[minitest]: https://github.com/seattlerb/minitest
[capy]: https://github.com/jnicklas/capybara
[docco]: https://github.com/jashkenas/docco

How to get help
---------------

- If you think you've found a bug, please [file a new issue](http://github.com/hotsh/rstat.us/issues) and include:
  - What happened
  - What you expected to happen
  - Steps to reproduce what happened
- You can send questions, problems, or suggestions to [the mailing list](http://librelist.com/browser/rstatus/)
- Chat with us on IRC in #rstatus on freenode

Helping out with rstat.us
-------------------------

If you'd like to contribute, we'd love to have you! Your first order of
business is setting up a development environment and making sure all the tests
pass on your system. Rstat.us is a Ruby on Rails 3.2 application, so it's
assumed you already have [Ruby](http://www.ruby-lang.org/en/downloads) (1.9.2
or 1.9.3 preferred, 1.8.7 compatibility is not guaranteed), rubygems (comes
with Ruby as of 1.9.2), and [bundler](http://gembundler.com/) on your machine.
If not, each of those links has instructions, and we're willing to help via
one of the contact methods above if you have issues.

### Automated Setup

There is an automated script to get your dev environment set up on Mac OS X.
From the app root directory, run ./script/setup_mac and enjoy the ride.
If everything installs correctly and no errors are reported that you need to
fix, you'll see the site loaded in your favorite browser.

- mongodb
  - Homebrew preferred for installing mongodb
  - MacPorts should also work
  - Take a look at the [mongodb-prefpane](https://github.com/ivanvc/mongodb-prefpane)


If there are any errors reported, fix what you can and let us know what you can't.

### Manual Setup

If you have any problems with the following rstat.us specific steps, _it is a
bug_. For example, [this is an issue with running a development environment on
windows](https://github.com/hotsh/rstat.us/issues/547) that we need to fix.
Please report any issues you have.

If you use RVM, you'll want to copy `.rvmrc.example` to `.rvmrc`.

### Getting a local version running

First off: you will need MongoDB (www.mongodb.org).  They have a [quickstart
guide][mongo-quickstart] for getting it installed and running.

Fork the project in github so that you have your own version.

Then do:

    $ git clone https://github.com/$MY_GITHUB_USERNAME/rstat.us.git
    $ cd rstat.us

Then update your gemset:

    $ gem install bundler && bundle install

The config.yml file will be automatically copied/generated for you when you
start the server and it does not exist. In dev mode the SECRET_TOKEN will be
generated for you and your config.yml file updated. When you run tests a new
random SECRET_TOKEN will be generated each time. You can always copy
config/config.yml.sample to config/config.yml and edit it on your own beforehand.

- encoding is UTF-8 by default for ruby 1.9.3
- Notes about config settings are in the example file (config/config.yml.example)

And start the server:

    $ rails server

Bam! Visit <http://localhost:3000/> in your browser, and you'll be good.

### Local Twitter configuration

Rstat.us allows you to sign in using a Twitter account or link a Twitter
account to your Rstat.us account. If you'd like to enable that functionality
in your dev environment, you'll need to obtain a consumer key and consumer
secret from Twitter. Here are the steps to do that:

- Go to https://dev.twitter.com
- Sign in using a valid Twitter account
- Hover over your username in the top right and select "My applications"
- Select "Create a new application"
- Fill in all the required fields (you can use made up information if
  you'd like) and be sure to add a "Callback URL" - e.g. http://rstat.us
- Go to the settings tab and select "Read and Write" for the application's
  access type
- If you haven't already, create a personal `config/config.yml` by copying
  `config/config.yml.sample`
- Copy the consumer key and consumer secret (found on the details tab)
  and put them in `config/config.yml` in the development section
- Restart your rails server

Now you should be able to sign in to your development version with Twitter!

### Running the tests

To run the tests you may want to make use of `bundle exec` so you don't get
mixed up with different versions of gems that might or might not work with
the current rstat.us branch.

Run all the tests except for the optional enhancements. This is fine for
smaller features that are not likely to affect enhancements:

    $ bundle exec rake test

Run all the tests including those for all the optional enhancements. This
requires that you have all the enhancements configured locally (see the
section on **Configuring optional enhancements** below). This is
recommended if you're working on a larger feature that touches many parts of
the application and is required if you're working on an enhancement. This is
the command that [Travis.ci](http://travis-ci.org/#!/hotsh/rstat.us) runs.

    $ bundle exec rake test:all

You can run convenient subsets of the tests during development; run `bundle
exec rake -T` to see all the options. You can also run one test file (for
example, `test/models/author_test.rb`) by specifying the filepath in the TEST
environment variable:

    $ bundle exec rake test TEST=test/models/author_test.rb

[mongo-quickstart]: http://www.mongodb.org/display/DOCS/Quickstart

### Picking something to work on

Once you've got a development environment set up with the current tests all
passing, you're ready to start working on the code!

Please see the [Issues](http://github.com/hotsh/rstat.us/issues); anything
without an assignee is up for grabs! Fairly well-defined and small issues are
tagged with [Pick
me!!!!!!](https://github.com/hotsh/rstat.us/issues?labels=Pick+me!!!!!!&milestone=&page=1&sort=updated&state=open);
these would be ideal if you want to help out but aren't sure where to start.
Don't hesitate to ask for help or clarification either on an issue itself or
through one of the contact methods listed above.

### Development Roadmap

In the second half of 2012, we plan to focus on:

- [Implementing an API (or two)](https://github.com/hotsh/rstat.us/issues?milestone=8&page=1&sort=updated&state=open)

We'd love to get rstat.us working with desktop and mobile clients, either
through a [twitter-compatible API in a client that allows you to change the
endpoint URL](https://github.com/hotsh/rstat.us/issues/562) or working with an
app developer to make an rstat.us-specific app. If you work on or would like
to work on a client, please let us know! We'd love to get feedback from you.

### Contribution steps

We follow [GitHub flow][flow], as a workflow. Basically:

- Create a feature branch in your fork
- Make your change, including tests and documentation as appropriate
- Please run all the tests before submitting a pull request!
- Submit a pull request from your branch
- Someone with commit access will let you know they are looking at it as soon
  as they are able. They will review the code and let Travis.ci run the tests
  before merging. This applies even if you also have commit access.

### Becoming a committer

Following [rubinius'
lead](http://www.programblings.com/2008/04/15/rubinius-for-the-layman-part-2-how-rubinius-is-friendly/),
once you have one pull request accepted into rstat.us, we will add you to a
team that has push+pull access. Basically you will get a big green merge
button on other people's pull requests, and you will be able to commit those
pull requests to the hotsh/rstat.us master branch.

This _also_ means that you _could_ push your commits directly to
hotsh/rstat.us without going through a pull request. We ask that you not do
this, however, so that any code on master has been seen by 2 sets of eyes
(tests don't always catch everything!) This does not apply to branches other
than master; if there is long-term collaboration happening, create a feature
branch and feel free to push directly to that (but have commits reviewed
before merging that branch into master).

We reserve the right to take away this permission, but in general we trust you
to give it to you. :heart: :heart:

Source code documentation
-------------------------

We have documentation that explains our source code using rocco.
You can view it [here](http://hotsh.github.com/rstat.us/).


Running your own node
---------------------

We're working on making this super easy, but right now, we're not quite there.

If you do run your own node, please keep current with upstream.


### Configuring optional enhancements

When running your own node, you will be able to make choices about what
features your node should offer. These will typically require additional
configuration or setup. The currently available enhancements are:

* [ElasticSearch](http://www.elasticsearch.org/)

#### ElasticSearch

The Rstat.us code is able to use
[ElasticSearch](http://www.elasticsearch.org/) to improve the quality of the
search of statuses. This is optional for development, test, and production.
The code will fall back to a simpler regular expression search should you
choose not to enable the ElasticSearch support.

Local development and test:

If you are using OSX and homebrew, you can install ElasticSearch using:

    $ brew install elasticsearch

Otherwise, you can download and install the latest release from [the
ElasticSearch website](http://www.elasticsearch.org/download/).

If you are running ElasticSearch on the default port of 9200, specify this as
the ELASTICSEARCH_INDEX_URL in your `config/config.yml` file in either or both
the development and test environments:

   ELASTICSEARCH_INDEX_URL: http://localhost:9200/

Production on heroku:

The code is set up to work with the [Bonsai Heroku
addon](https://devcenter.heroku.com//articles/bonsai). Check that article for
the most up-to-date instructions. As of this writing you should simply be able
to do:

    $ heroku addons:add bonsai:test

This will add a heroku config value for BONSAI_INDEX_URL that will
automatically be picked up by the code for all new statuses entered.

To index existing updates, run:

    $ heroku run rake environment tire:import CLASS='Update'

Production on other hosts:

If you are hosting your node somewhere other than heroku and have installed
ElasticSearch on your own, set the environment variable
ELASTICSEARCH_INDEX_URL to the domain where your ElasticSearch service is.
