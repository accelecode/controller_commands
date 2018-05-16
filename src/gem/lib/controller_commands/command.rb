module ControllerCommands
  module Command

    module ClassMethods
      def validation_schema(&block)
        @validation_schema_provider = block
      end

      def validate(context, incoming_params)
        validation_schema =
          @validation_schema_provider ?
            @validation_schema_provider.call(context) :
            Dry::Validation.Schema # provide a default, empty validation schema if none was defined for the command
        validation_schema.call(incoming_params)
      end

      def success_message(&block)
        @success_message_block = block
      end

      def get_success_message
        @success_message_block&.call
      end

      def process_command(&block)
        @perform_block = block
      end

      def perform(context, validated_params)
        @perform_block.call(context, validated_params)
      end

      def before_success_render(&block)
        @before_render_success_block = block
      end

      def execute_before_success_render(context, output)
        @before_render_success_block ?
          @before_render_success_block.call(context, output) :
          output
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    def initialize(incoming_params, context)
      @incoming_params = incoming_params
      @context = context
    end

    def validated?
      !!@result
    end

    def errors
      @result.messages
    end

    def validated_params
      @result.output
    end

    def validate_params
      @result = self.class.validate(@context, @incoming_params)
      @result.messages.count == 0
    end

    def success_message
      self.class.get_success_message
    end

    def perform
      self.class.perform(@context, validated_params)
    end

    def render_success(output)
      self.class.execute_before_success_render(@context, output)
    end

  end
end
