module HokusaiPaint
  module Tools
    class BrushOptions < Hokusai::Block
      template <<~EOF
      [template]
        virtual
      EOF
    end

    class Brush < Base
      attr_reader :control

      def self.id
        "brush"
      end

      def self.icon
        "brush"
      end

      def tool_options
        @opt ||= BrushOptions.mount
      end

      def initialize(control)
        @control = control
      end
    end
  end
end
