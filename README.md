<pre>
               .            .
 .___    ____ _/_     ___  _/_     ,   .   ____
 /   \  (      |     /   `  |      |   |  (
 |   '  `--.   |    |    |  |      |   |  `--.
 /     \___.'  \__/ `.__/|  \__/ / `._/| \___.'

</pre>

rstat.us is a microblogging site built on top of the [ostatus
protocol](http://status.net/wiki/OStatus).

[![Build Status](https://secure.travis-ci.org/hotsh/rstat.us.png)](http://travis-ci.org/hotsh/rstat.us)

Helping out with rstat.us
-------------------------

If you'd like to contribute, here are some details:

- The stack: ruby/rails 3.1/mongodb
- [The code][code]
- [The documentation][docs] (need lots of improvement here!)
- [The Issues list][issues]
- We follow [GitHub flow][flow], as a workflow. Basically:
  - Please fork the project and make a pull request
    - Pull requests will not be merged without tests/documentation
      - We use [minitest][minitest]/[capybara][capy] for tests
      - We use [docco][docco] (rocco) for documentation
      - If you think it doesn't need a test, make your case, I'm just saying.

[code]: http://github.com/hotsh/rstat.us
[docs]: http://hotsh.github.com/rstat.us/
[issues]: http://github.com/hotsh/rstat.us/issues
[minitest]: https://github.com/seattlerb/minitest
[capy]: https://github.com/jnicklas/capybara
[docco]: https://github.com/jashkenas/docco
[flow]: http://scottchacon.com/2011/08/31/github-flow.html

Source code documentation
-------------------------

We have documentation that explains all of our source code, using rocco.
You can view it [here](http://hotsh.github.com/rstat.us/rstatus.html).


Setting up a dev environment
----------------------------

First off: you will need MongoDB (www.mongodb.org).  They have a [quickstart
guide][mongo-quickstart] for getting it installed and running.

Then do:

    $ git clone https://github.com/$MY_GITHUB_USERNAME/rstat.us.git
    $ cd rstat.us

Then update your gemset:

    $ gem install bundler && bundle install

And start the server:

    $ rails server

Bam! Visit <http://localhost:9292/> in your browser, and you'll be good.

To run the tests you may want to make use of `bundle exec` so you don't get
mixed up with different versions of gems that might or might not work with
the current rstat.us branch.

Run the tests:

    $ bundle exec rake test:all

[mongo-quickstart]: http://www.mongodb.org/display/DOCS/Quickstart

Running your own node
---------------------

If you need help with this, then you're not ready to run one. We're working
on making this super easy, but right now, we're not quite there.

If you do run your own node, please keep current with upstream.
