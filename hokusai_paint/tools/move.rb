module HokusaiPaint
  module Tools
    class MoveOptions < Hokusai::Block
      template <<~EOF
      [template]
        virtual
      EOF
    end

    class Move < Base
      attr_reader :control
      attr_accessor :moving

      def self.id
        "move"
      end

      def self.icon
        "hand"
      end

      def tool_options
        @opt ||= MoveOptions.mount
      end

      def initialize(control)
        @control = control
        @moving = false
      end

      def mousedown(event)
        self.moving = true
      end

      def mousemove(event)
        if moving && event.left.down
          control.sheet.move(event.delta.x, event.delta.y)
        else
          self.moving = false
        end
      end
    end
  end
end
