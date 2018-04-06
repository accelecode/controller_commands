# ControllerCommands

A Rails controller concern which makes it easy to encapsulate validation and processing of complex incoming data into command classes.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'controller_commands'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install controller_commands

## Usage

Following is an example:

```ruby
class MyRecordController < ApplicationController
  include ControllerCommands::Concern

  def save_command
    handle_command(context: {parent: ParentRecord.find(params[:parent_id])})
  end

  class SaveCommand
    include ControllerCommands::Command

    validation_schema do |context|
      Dry::Validation.JSON do
        required(:id).maybe(:int?)
        required(:first_name).maybe(:str?)
        required(:last_name).maybe(:str?)
        end
      end
    end

    handle_command do |context, valid_params|
      parent = context.fetch(:parent)
      child = parent.child || parent.build_child
      child.save!(valid_params)
      {id: child.id}
    end
  end

end
```

## Development

Source code for  the gem itself is located under the `src/gem` directory. Source code for the tests is located under `src/test`. Separating the test source code into a separate project allows the tests to consume the gem source code as a gem, which more closely mirrors actual use by other developers.

### Gem

Navigate to `src/gem` in your terminal.

After checking out the repo, run `bin/setup` to install gem dependencies.

You can also run `bin/console` for an interactive prompt that will allow you to experiment.

*Publishing Gem Releases*

To install this gem onto your local machine, run `bundle exec rake install`.

To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Tests

Navigate to `src/test` in your terminal.

Sorry, there are currently no tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at [here](https://github.com/accelecode/controller_commands.)
