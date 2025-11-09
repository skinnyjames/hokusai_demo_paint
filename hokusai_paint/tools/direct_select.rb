module HokusaiPaint
  module Tools
    class DirectSelectOptions < Hokusai::Block
      template <<~EOF
      [template]
        virtual
      EOF
    end

    class DirectSelect < Base
      attr_reader :control
      attr_accessor :moving

      def self.id
        "direct select"
      end

      def self.icon
        "pointer"
      end

      def tool_options
        @opt ||= DirectSelectOptions.mount
      end

      def initialize(control)
        @control = control
      end

      # def click(event)
      #   control.direct_select(event.pos.x, event.pos.y)
      # end
    end
  end
end
