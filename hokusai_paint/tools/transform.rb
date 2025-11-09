module HokusaiPaint
  module Tools
    class TransformOptions < Hokusai::Block
      template <<~EOF
      [template]
        virtual
      EOF
    end

    class Transform < Base
      class Corners
        attr_reader :value

        def initialize
          @value = {
            tl: nil,
            tm: nil,
            tr: nil,

            ml: nil,
            mr: nil,

            bl: nil,
            bm: nil,
            br: nil
          }
        end

        def values
          value.values
        end

        def adjust_corner(key, delta)
          @value[key] = [@value[key].first + delta.x, @value[key].last + delta.y]
        end

        def []=(key, value)
          @value[key] = value
        end

        def [](key)
          @value[key]
        end

        def hovered(event)
          @value.find do |k, coords|
            x, y = coords

            rect = Hokusai::Rect.new(x - 10, y - 10, 26.0, 26.0)
            rect.includes_x?(event.pos.x) && rect.includes_y?(event.pos.y)
          end
        end
      end

      attr_reader :control
      attr_accessor :moving

      def self.id
        "transform"
      end

      def self.icon
        "resize"
      end

      def tool_options
        @opt ||= TransformOptions.mount
      end

      attr_reader :corners
      attr_accessor :start, :bounds

      def initialize(control)
        @control = control
        @corners = Corners.new
        @resizing = nil
        @moving = false
        @start = false
        @bounds = nil
      end

      def on_deactivate
        control.layer.active = nil
        control.layer.active_blocks = false
        @resizing = nil
        @moving = false
        @start = false
        @bounds = nil
      end

      def keypress(event)
        return unless control.layer.texture && bounds
        if event.symbol == :enter
          command = Commands::Transform.new(control.layer.bounds, bounds, control)

          control.apply(command)
          # commit transform
          @resizing = nil
          @moving = false
          @corners = Corners.new
          @bounds = nil
          @start = false
          control.layer.active = nil
          control.layer.active_blocks = false
        end
      end

      def hover(event)
        delta_x = event.delta.x / control.zoomf
        delta_y = event.delta.y / control.zoomf

        if event.left.down && @resizing
          x, y = @resizing.last

          case @resizing.first
          when :tl
            bounds.x += delta_x
            bounds.y += delta_y

            bounds.width -= delta_x
            bounds.height -= delta_y
          when :tm
            bounds.y += delta_y
            bounds.height -= delta_y
          when :tr
            bounds.y += delta_y

            bounds.width += delta_x
            bounds.height -= delta_y
          when :ml
            bounds.x += delta_x
            bounds.width -= delta_x
          when :mr

            bounds.width += delta_x
          when :bl
            bounds.x += delta_x
            bounds.width -= delta_x
            bounds.height += delta_y
          when :bm
            bounds.height += delta_y
          when :br
            bounds.width += delta_x
            bounds.height += delta_y
          end
        elsif event.left.down && @moving
          bounds.x += delta_x
          bounds.y += delta_y
        elsif event.left.up
          @resizing = nil
          @moving = nil
        end
      end

      def click(event)
        self.start = true
        return if corners.values.any?(&:nil?) || bounds.nil?

        corner = corners.hovered(event)
        tmp = control.sheet.to_screen(bounds)

        if corner
          @resizing = corner
        elsif tmp.includes_x?(event.pos.x) && tmp.includes_y?(event.pos.y)
          @moving = true
        else

          control.layer.active = nil
          control.layer.active_blocks = false
        end
      end

      def render(canvas, block)
        return unless control.layer.texture

        if start
          self.bounds ||= begin
            control.layer.bounds
          end

          tmp = control.sheet.to_screen(bounds)
          bounds = tmp
          x = bounds.x
          y = bounds.y
          w = bounds.width
          h = bounds.height

          color = Hokusai::Color.new(138, 57, 57)

          control.layer.active = ->(canvas, block, zoom) do
            return if control.layer.texture.nil? || bounds.nil?

            block.draw_with do |commands|
              commands.texture(control.layer.texture, x, y) do |command|
                command.width = bounds.width
                command.height = bounds.height
              end
            end
          end

          control.layer.active_blocks = true

          # this should be the new position, i think...
          corners[:tl] = [x - 17, y - 17]
          corners[:tm] = [x - 17 + w / 2.0, y - 18]
          corners[:tr] = [x + w + 17.0, y - 17]
          corners[:ml] = [x - 18, y - 17 + h / 2.0]
          corners[:mr] = [x + w + 17, y - 17 + h / 2.0]
          corners[:bl] = [x - 17, y + h + 17]
          corners[:bm] = [x - 17 + w / 2.0, y + h + 17]
          corners[:br] = [x + w + 17, y + h + 17]

          block.draw do
            rect(x - 20.0, y - 20, w + 40, h + 40) do |command|
              command.color = Hokusai::Color.new(0, 0, 0, 0)
              command.outline = Hokusai::Outline.new(1.0, 1.0, 1.0, 1.0)
              command.outline_color = color
            end
          end

          corners.values.each do |arr|
            block.draw do
              circle(*arr, 6.0) do |command|
                command.color = color
              end
            end
          end
        end
      end
    end
  end
end
