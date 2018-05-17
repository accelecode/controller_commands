# Why use `controller_commands`?

The `controller_commands` gem makes it even easier to write JSON-based Rails APIs for browser and mobile client applications. Commands integrate with the standard Rails MVC approach, being called from controller actions.

You can use `controller_commands` for new apps. However, `controller_commands` also shines when used with existing Rails apps, allowing you to start sprinkling in more advanced JavaScript UIs using React, Angular, Ember, etc.

The standard Rails MVC approach to defining controller actions, including validation and rendering responses has served us well for many years. `controller_commands` does not change the MVC approach Rails advocates.

However, as web application development has progressed, there has been a shift toward moving part or all of an application's UI (the view, V in MVC) into a client application. Client applications could be a JavaScript application in the browser or one or more mobile applications. It is common to use JSON-based APIs to make data available to client applications. While Rails has progressed in making it easier to provide JSON-based APIs, this gem provides further conventions which make it even easier. This gem also fills in some gaps that Rails does not currently address.

#### Filling Gaps In Rails

What gaps does this gem fill? There are two problems that are not currently addressed well in Rails.

First, Rails controller actions and the their supporting Active Record models are designed to work with "flat" incoming data - data with very little nesting. A typical Rails controller action receives params that map very closely to a single model. Active Model validation is oriented toward this "flat" incoming data.

```ruby
# Example of params which Rails is GREAT at validating
{
  first_name: 'John',
  last_name: 'Smith'
}
```

Think for a moment about the type of data a heavier client application might send to a JSON-based API. How does Rails Active Model validation fair when presented with a complex nested data structure such as an online order. An order would have a few different parts: a billing address, a shipping address, details about the order itself (the customer id, for example) and a collection of line items. How will you validate this incoming order data in a single controller action? Rails validation is not designed to deal well with nested incoming params.

```ruby
# Example of params which Rails is NOT GREAT at validating
{
  customer_id: '',
  shipping_address: {
    street1: '',
    street2: '',
    city: '',
    state: '',
    zip: ''
  },
  billing_address: {
    street1: '',
    street2: '',
    city: '',
    state: '',
    zip: ''
  },
  line_items: [
    {item_id: '', quantity: ''},
    {item_id: '', quantity: ''}
  ]
}
```

How does `controller_commands` fill this first gap? The `controller_commands` approach to validation makes it easy to define nested validation. The `controller_commands` gem leans heavily on the excellent `dry-validation` gem to support validation of nested data.

How about the second gap? Dealing with incoming and outgoing JSON hash keys is the second gap that `controller_commands` fills.

What is the problem? JSON clients typically expect JSON data to use `camelCase` keys for hashes. Ruby conventions call for using `snake_case` keys. Rails (even an API-only Rails application) does not convert incoming and outgoing keys between `camelCase` and `snake_case`. You can transform outgoing JSON keys to `camelCase` if you are using either of the `jbuilder` or `active_model_serializers` gems in combination with Rails. However, neither of these gems transform incoming JSON keys to `snake_case` to make it easier to work with incoming data in Ruby. Rails is flexible enough to allow you to write your own solution to this problem, but it would be nice to use a pre-built solution.

`controller_commands` fills the second gap by allowing JSON clients to send and receive `camelCase`-formatted keys. `controller_commands` relies on the gem `hash_key_transformer` to handle the transformation of incoming and outgoing hash keys.

#### Other Benefits

In addition to filling the gaps outlined above, there are other benefits to using `controller_commands`. These benefits are subjective and are presented as such. Your mileage may vary.

By decoupling validation from models it is very easy to read and understand what is required to perform a particular API action. You may also find that validation defined at a controller action/command-level is also easier to read and understand.

While Rails does allow partial validation of a model, using validation at the controller action-level makes it easier to see what's being validated and the context for why those fields are being validated.

When adding validation to a model in a traditional Rails application, there is a greater chance of unintentionally impacting other parts of the application with the new validation. By scoping validation to a single action, changing validation in one action is less likely to impact other parts of your application.

Commands can more easily and clearly modify multiple models at the same time and it becomes clear, when looking at the command, why these modifications are being made at the same time. Additionally, by extracting the processing from controller actions, a seperation of concerns is enforced such that business-oriented code is placed in the command and http-related code is handled by `controller_commands` itself. Arguably, something similar could be said about moving business-oriented code out of Active Record models (though it is so common to have business-oriented code in models in traditional rails applications that it could almost be viewed as contriversial to move away from that approach completely).

By integrating commands with controller actions, we gain two other key benefits. First, it is easier to start using `controller_commands` in an existing Rails app. You can start using commands inside your existing controllers as new controller actions which are called from client-side JavaScript in your views. Second, you can utilize your existing controller action authorization scheme to allow/disallow users to perform commands.

## Getting Started

### Installation

Add this line to your application's Gemfile:

```ruby
gem 'controller_commands'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install controller_commands

### Usage

Continuing on with the example of validating and processing an order, the following example code is designed to accept the example nested order data presented earlier in this readme, validate the incoming data and save a new order using active record.

```ruby
class OrdersController < ApplicationController
  include ControllerCommands::Concern

  def create_command
    handle_command(context: {store: Store.find(store_id_from_hostname)})
  end

  class CreateCommand
    include ControllerCommands::Command

    validation_schema do |context|
      Dry::Validation.JSON do
        required(:customer_id).filled(:int?)
        required(:shipping_address).schema do
          required(:street1).filled(:str?)
          required(:street2).maybe(:str?)
          required(:city).filled(:str?)
          required(:state).filled(:str?)
          required(:zip).filled(:str?)
        end
        required(:billing_address).schema do
          required(:street1).filled(:str?)
          required(:street2).maybe(:str?)
          required(:city).filled(:str?)
          required(:state).filled(:str?)
          required(:zip).filled(:str?)
        end
        required(:line_items).each do
          required(:item_id).filled(:str?)
          required(:quantity).filled(:int?)
        end
      end
    end

    process_command do |context, attrs|
      store = context.fetch(:store)
      customer = store.customers.find(attrs.fetch(:customer_id))

      order = customer.orders.build
      order.build_shipping_address(attrs.fetch(:shipping_address))
      order.build_billing_address(attrs.fetch(:billing_address))
      attrs.fetch(:line_items).each {|line_item_attrs| order.line_items.build(line_item_attrs)}
      order.save!

      {id: order.id}
    end
  end

end
```

Let's walk through this controller and discuss what each part is doing.

```ruby
class OrdersController < ApplicationController
  include ControllerCommands::Concern
```

First, we include `ControllerCommands::Concern`.

```ruby
  def create_command
    handle_command(context: {store: Store.find(store_id_from_hostname)})
  end
```

Next, we define an action, which is routed like a traditional Rails controller action should be. In this case, we have named the action `create_command`. We would need to add this action to the routes.rb file to make it accessible as an HTTP call from a client application. Although we are not doing it here for the sake of this example, we would expect this controller to require authentication and possibly authorization for the `create_command` action.

```ruby
  class CreateCommand
    include ControllerCommands::Command
```

We define a class with the sole purpose of responding to an API call. By using a separate class for this purpose, we enforce a seperation of concerns and the command class is isolated from the HTTP-oriented concerns of the controller which uses it.

We include `ControllerCommands::Command` in the class in order to provide the class methods used to wire up validation and processing.

The `#handle_command` method called in the controller action will inspect the current controller action name and use that to create the command class. You can  override this default behavior by providing the `command_klass: Klass` option as a parameter to `#handle_command` called in the controller.

```ruby
    validation_schema do |context|
      Dry::Validation.JSON do
        required(:customer_id).filled(:int?)
        required(:shipping_address).schema do
          required(:street1).filled(:str?)
          required(:street2).maybe(:str?)
          required(:city).filled(:str?)
          required(:state).filled(:str?)
          required(:zip).filled(:str?)
        end
        required(:billing_address).schema do
          required(:street1).filled(:str?)
          required(:street2).maybe(:str?)
          required(:city).filled(:str?)
          required(:state).filled(:str?)
          required(:zip).filled(:str?)
        end
        required(:line_items).each do
          required(:item_id).filled(:str?)
          required(:quantity).filled(:int?)
        end
      end
    end
```

The `validation_schema` block defines the dry-validation schema which will be applied to the incoming params automatically. Notice that we are using `Dry::Validation.JSON` which handles validating JSON types for us automatically. If validation fails, the errors collection will be rendered as JSON output for the controller action. The client application can then render the errors in such a way that the user can resolve the validation errors and resubmit the form.

```ruby
    process_command do |context, attrs|
      store = context.fetch(:store)
      customer = store.customers.find(attrs.fetch(:customer_id))

      order = customer.orders.build
      order.build_shipping_address(attrs.fetch(:shipping_address))
      order.build_billing_address(attrs.fetch(:billing_address))
      attrs.fetch(:line_items).each {|line_item_attrs| order.line_items.build(line_item_attrs)}
      order.save!

      {id: order.id}
    end
  end
```

The `process_command` block will perform processing when validation succeeds. The context hash we pass in from the controller is available here. You can inject anything from the controller that you might need in order to perform processing. For example, you can provide models to the command which are already being loaded through controller before filters, middleware, etc.

The `attrs` argument is the dry-validation output which only includes values defined in `validation_schema`. The result of the `process_command` block will be rendered as the JSON output of the controller action, which is sent to the client application.

On a side note, the command class is defining validation and processing as blocks given in the class definition. Using this approach allows us to get the benefits of inheritance using the template method pattern but gives us the added benefit of keeping the code in each block isolated from other code in the class. This does not allow us to as easily break processing code into separate functions within the same class. However, if `process_command` blocks are small and focused it renders the ability to extract code from them less useful to begin with. Additionally, methods can be extracted into modules (or controller concerns) and those modules used to extend the block itself:

```ruby
process_command do |context, attrs|
  extend(MyCustomModule)
  # Use the extracted methods here
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

Bug reports and pull requests are welcome on GitHub [here](https://github.com/accelecode/controller_commands).
