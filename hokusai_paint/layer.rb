module HokusaiPaint

  class Layer
    attr_accessor  :name, :strokes, :canvas, :control,
                   :active, :visible, :texture, :blend_mode,
                   :diff_rect, :resize_rect, :diff_rotation,
                   :offset_x, :offset_y, :strokes, :active_blocks

    def initialize(name, control)
      @name = name
      @control = control
      @strokes = []
      @visible = true
      @transparency = 1
      @active = nil
      @active_blocks = false
      @blend_mode = nil
      @selected = false

      @offset_x = 0.0
      @offset_y = 0.0

      @diff_rotation = 0.0
    end

    def copy
      obj = self.dup
      obj.texture = texture.dup if texture
      obj
    end

    def bounds
      return if texture.nil?

      Hokusai::Rect.new(offset_x, offset_y, texture.width, texture.height)
    end

    def width
      return if texture.nil?

      texture.width
    end

    def height
      return if texture.nil?

      texture.height
    end

    def transform(rect, rotation = 0.0)
      commands = Hokusai::Commands.new
      tex = Hokusai::Texture.init(rect.width, rect.height)
      tex.clear


      commands.texture(@texture, 0.0,0.0) do |command|
        command.width = rect.width.to_f
        command.height = rect.height.to_f
        command.rotation = rotation
      end

      tex.apply(commands.queue)
      @texture = tex
      self.offset_x = rect.x
      self.offset_y = rect.y
    end

    def render(canvas, block, zoom)
      return unless visible

      if texture && (active.nil? || !active_blocks)
        block.draw_with do |commands|
          centered = control.sheet.to_screen(bounds)

          commands.blend_mode_begin(blend_mode) if blend_mode

          commands.texture(@texture, centered.x, centered.y) do |f|
            f.width = centered.width
            f.height = centered.height
            f.flip = true
            f.rotation = 0.0
          end

          #   commands.rotation_begin(centered.x + centered.width / 2.0, centered.y + centered.height / 2.0, diff_rotation)
            
          #   commands.texture(texture, -(centered.width / 2.0), -(centered.height / 2.0)) do |command|
          #     command.width = centered.width
          #     command.height = centered.height
          #   end
            
          #   commands.rotation_end

          commands.blend_mode_end if blend_mode
        end
      end

      if active
        block.draw_with do |commands|
          commands.blend_mode_begin(blend_mode) if blend_mode
        end
        active.call(canvas, block, zoom)
        block.draw_with do |commands|
          commands.blend_mode_end if blend_mode
        end
      end
    end
  end
end