require 'active_support/concern'
require 'action_controller/metal/exceptions'
require 'dry/validation'
require 'hash_key_transformer'
require 'json'

module ControllerCommands
  module Concern
    extend ActiveSupport::Concern

    def handle_command(options = {})
      command_params = parse_params(options.fetch(:incoming_key_transformer, :transform_camel_to_underscore))
      context = options.fetch(:context, {})
      command = construct_command(command_params, context, options[:command_klass])

      # Validate & potentially execute the command
      is_command_valid = command.validate_params
      result =
        if is_command_valid
          if respond_to?(:flash)
            flash[:notice] = command.success_message
          end
          {data: command.perform}
        else
          {errors: command.errors}
        end

      # Render the results
      validation_failed_status_code = options.fetch(:validation_failed_status_code, :ok)
      status_code = (is_command_valid ? :ok : validation_failed_status_code)
      render status: status_code, json: HashKeyTransformer.transform_underscore_to_camel(result)
    end

    def parse_params(key_transformer_strategy)
      # We need to be cautious accepting array fields as input. Refer to CVE-2013-0155 for more details about the danger
      # of malicious users crafting JSON using an array for a where clause field:
      #
      #   https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2013-0155
      #
      # The default JSON parsing in Rails replaces empty arrays with nil as a part of their solution to the CVE above.
      # This is the reason we are manually parsing the JSON request body. Consistent use of dry-validation schema types
      # should protect us from this CVE and also provide the same protection as Rails strong parameters.
      parsed_params = JSON.parse(request.body.read)
      HashKeyTransformer.send(key_transformer_strategy, parsed_params)
    end

    def construct_command(incoming_params, context, command_klass = nil)
      unless command_klass
        # this should be fine given that the permissible action names are controlled by routing definitions
        command_klass_name = params.fetch(:action).camelize
        command_klass =
          "#{self.class.name}::#{command_klass_name}".safe_constantize or
          raise ActionController::RoutingError.new('Invalid Command')
      end
      command_klass.new(incoming_params, context)
    end
  end
end
