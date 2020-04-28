# CExpect

The `IO#expect` in the `expect` ruby module is very useful for
automating interaction with interactive shell scripts. However, it has
a few shortcomings:

* Its return value is not as useful as it could be
* Logging can only be achieved by setting a global variable
* Using regexps for matching becomes slow with large amounts of data
* The default expect timeout is a very large number (this doesn't
  actually affect the functionality negatively, it just feels awkward)

To adress this, the CExpect (Christer's Expect) gem offers a different
interface:

* The exposed `expect` method returns or yields the match data when a
  match is found, which makes it possible to e.g. use capturing in a
  meaningful way (see Usage below)
* It also returns the return value of the block, when a block is given
* Logging can be achieved by adding observers
* There is an alternate `fexpect` method (the f can be thought of as
  "fixed" or "fast"), which is useful for capturing large outputs from
  shell commands
* The default timeout is `nil`, which will cause `expect` to wait
  indefinitely (again, this merely makes more sense to someone reading
  the code)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cexpect'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install cexpect

## Usage

```ruby
require 'cexpect'

# Same semantics as PTY.spawn
rd, wr, pid = CExpect.spawn('sh')

rd.fexpect('$ ')
wr.puts('ls -1')
md = rd.expect(/ls -1\r\n(?<files>.*)\$ /m)
files = md[:files].split

# Or, equivalently
rd.expect(/ls -1\r\n(?<files>.*)\$ /m) do |md|
  files = md[:files].split
  # do something with files
end

wr.puts('cat very-large-file')
contents = rd.fexpect('$ ')
```

## Development

After checking out the repo, run `bin/setup` to install
dependencies. Then, run `rake spec` to run the tests. You can also run
`bin/console` for an interactive prompt that will allow you to
experiment.

To install this gem onto your local machine, run `bundle exec rake
install`. To release a new version, update the version number in
`version.rb`, and then run `bundle exec rake release`, which will
create a git tag for the version, push git commits and tags, and push
the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/[USERNAME]/cexpect.


## License

The gem is available as open source under the terms of the [BSD 2-Clause
License](https://opensource.org/licenses/BSD-2-Clause).
