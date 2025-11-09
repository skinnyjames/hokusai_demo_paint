module HokusaiPaint
  module Tools
    class DropperOptions < Hokusai::Block
      template <<~EOF
      [template]
        virtual
      EOF
    end

    class Dropper < Base
      attr_reader :control
      attr_accessor :last_event, :last_color

      def self.id
        "dropper"
      end

      def self.icon
        "dropper"
      end

      def tool_options
        @opt ||= DropperOptions.mount
      end

      def initialize(control)
        @control = control
        @last_color = nil
        @last_event = nil
      end

      def hover(event)
        @hovering = true
        px = event.pos.x - control.sheet.read_x
        py = event.pos.y - control.sheet.read_y
        image = control.image
        image.flip_vertical

        self.last_event = event
        self.last_color = image.color_at(px, py)
      end

      def mouseout(event)
        @hovering = false
      end

      def click(event)
        control.foreground_color = last_color
      end

      def render(canvas, block)
        return unless @hovering

        if pos = last_event&.pos
          lcolor = last_color
          block.draw do
            circle(pos.x + 20, pos.y - 20, 10.0) do |command|
              command.color = Hokusai::Color.new(255, 255, 255)
            end
            circle(pos.x + 20, pos.y - 20, 8.0) do |command|
              command.color = lcolor
            end
          end
        end
      end
    end
  end
end
