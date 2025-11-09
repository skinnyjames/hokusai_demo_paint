module HokusaiPaint
  module Tools
    class RectOptions < Hokusai::Block
      template <<~EOF
      [template]
        virtual
      EOF
    end

    class Rect < Base
      attr_reader :control, :bounds
      attr_accessor :moving, :color,

      def self.id
        "rect"
      end

      def self.icon
        "square"
      end

      def tool_options
        @opts ||= RectOptions.mount
      end

      def initialize(control)
        @control = control
        @bounds = Hokusai::Rect.new(0.0, 0.0, 0.0, 0.0)
        @color = Hokusai::Color.new(222, 222, 222)
      end

      def mousedown(event)
        if !moving && event.left.down
          self.moving = true
          self.bounds.x = event.pos.x
          self.bounds.y = event.pos.y
          self.bounds.width = self.bounds.x
          self.bounds.height = self.bounds.y
    
          control.layer.active = ->(canvas, block, zoom) do
            block.draw_with do |commands|
              z = control.zoomf
  
              nw = (bounds.width / z)
              nh = (bounds.height / z)
        
              cx = (bounds.x * z).round / z
              cy = (bounds.y * z).round / z

              commands.rect(cx.round, cy.round, bounds.width, bounds.height) do |command|
                command.color = control.foreground_color
              end
            end
          end
        end
      end

      def mousemove(event)
        Hokusai.set_mouse_cursor(:crosshair) if moving

        event.stop
        if moving && event.left.down
          self.bounds.width = (event.pos.x - bounds.x)
          self.bounds.height = (event.pos.y - bounds.y)
        elsif moving && event.left.up
          self.moving = false

          normal = control.sheet.normalized(bounds)

          rect_command = Commands::Rect.build(control) do |command|
            command.bounds = normal
          end

          control.apply(rect_command)
    
          control.layer.active = nil
          self.bounds.x = 0.0
          self.bounds.y = 0.0
          self.bounds.width = 0.0
          self.bounds.height = 0.0
        end
      end
    end
  end
end
