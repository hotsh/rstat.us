<pre>
               .            .
 .___    ____ _/_     ___  _/_     ,   .   ____
 /   \  (      |     /   `  |      |   |  (
 |   '  `--.   |    |    |  |      |   |  `--.
 /     \___.'  \__/ `.__/|  \__/ / `._/| \___.'

</pre>

rstat.us is a microblogging site built on top of the [ostatus
protocol](http://status.net/wiki/OStatus).

The differences between rstat.us and other microblogging networks are *simplicity* and *openness*.

*Simplicity* is a core 'feature' of rstat.us. We pride ourselves on saying 'no' to lots of features. Our interface is clean, and easy to understand. We give you just enough features to be interesting, but not enough to be complicated and confusing.

*Openness* means the programming code that makes up rstat.us is available for anyone to download, free of charge. Programmers can use that code to run their own websites just like rstat.us, and you can subscribe to your friends on any site that supports the OStatus protocol, like identi.ca. This also means that you can own your data; we'll never stop you from having full access to everything you've put into rstat.us.

[![Build Status](https://secure.travis-ci.org/hotsh/rstat.us.png)](http://travis-ci.org/hotsh/rstat.us)

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

If you'd like to contribute, we'd love to have you! Here are some details:

- The stack: ruby/rails 3.1/mongodb
- [The code][code]
- [The documentation][docs] (We could use lots of improvement here!)
- [The Issues list][issues]
- Tests are written using [minitest][minitest] and [capybara][capy]
- Documentation is generated using [docco][docco] (rocco)
- We follow [GitHub flow][flow], as a workflow. Basically:
  - Please fork the project
  - Create a feature branch
  - Make your change, including tests and documentation as appropriate
  - Submit a pull request from your branch
  - A member of the core team will let you know they are looking at it as soon as they are able. We will review the code and run the tests before merging.

[code]: http://github.com/hotsh/rstat.us
[docs]: http://hotsh.github.com/rstat.us/
[issues]: http://github.com/hotsh/rstat.us/issues
[flow]: http://scottchacon.com/2011/08/31/github-flow.html
[minitest]: https://github.com/seattlerb/minitest
[capy]: https://github.com/jnicklas/capybara
[docco]: https://github.com/jashkenas/docco

## Development Roadmap

In the first half of 2012, we plan to work on:

- [Fixing user-facing bugs or cutting buggy parts of the app](https://github.com/hotsh/rstat.us/issues?state=open&milestone=11)
- [Fixing OStatus support](https://github.com/hotsh/rstat.us/issues?state=open&milestone=6)
- [Implementing a RESTful API](https://github.com/hotsh/rstat.us/issues?milestone=8&state=open)
- [Supporting and documenting running your own node](https://github.com/hotsh/rstat.us/issues?milestone=7&state=open)

Please see the [Issues](http://github.com/hotsh/rstat.us/issues), anything without an assignee is up for grabs! Don't hesitate to ask for help or clarification either on an issue itself or through one of the contact methods listed above.

Source code documentation
-------------------------

We have documentation that explains our source code using rocco.
You can view it [here](http://hotsh.github.com/rstat.us/).


Setting up a development environment
------------------------------------

### Getting a local version running

First off: you will need MongoDB (www.mongodb.org).  They have a [quickstart
guide][mongo-quickstart] for getting it installed and running.

Then do:

    $ git clone https://github.com/$MY_GITHUB_USERNAME/rstat.us.git
    $ cd rstat.us

Then update your gemset:

    $ gem install bundler && bundle install

And start the server:

    $ rails server

Bam! Visit <http://localhost:3000/> in your browser, and you'll be good.

### Local Twitter configuration

Rstat.us allows you to sign in using a Twitter account or link a Twitter
account to your Rstat.us account.  If you'd like to enable that
functionality in your dev environment, you'll need to obtain a consumer key and consumer
secret from Twitter.  Here are the steps to do that:

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

Run all the tests:

    $ bundle exec rake test

You can run convenient subsets of the tests during development; run `bundle exec rake -T` to see all the options. You can also run one test file (for example, `test/models/author_test.rb`) by specifying the filepath in the TEST environment variable:

    $ bundle exec rake test TEST=test/models/author_test.rb

Please run all the tests before submitting a pull request!

[mongo-quickstart]: http://www.mongodb.org/display/DOCS/Quickstart

Running your own node
---------------------

We're working on making this super easy, but right now, we're not quite there.

If you do run your own node, please keep current with upstream.
