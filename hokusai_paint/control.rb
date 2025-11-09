require_relative "./sheet"
require_relative "./layer"

module HokusaiPaint
  class Control
    attr_accessor :layers, :active_layer, :tools, :sheet, :zoom, 
                  :canvas, :drag_layer, :drag_y,
                  :foreground_color, :background_color,
                  :picking_color, :undo_stack, :redo_stack, :counter

    attr_reader :active_layer, :active_tool

    def initialize(width, height)
      @sheet = Sheet.new(width, height, self)
      @layers = [Layer.new("initial", self)]
      @tools = {}
      @active_tool = nil
      @active_layer = "initial"
      @undo_stack = []
      @redo_stack = []

      @picking_color = nil
      @foreground_color = Hokusai::Color.new(0, 0, 0)
      @background_color = Hokusai::Color.new(255, 255, 255)

      @drag_layer = nil
      @drag_y = nil
      @zoom = 100
      @canvas = nil
      @counter = 0
    end

    def apply(command)
      command.execute(self)
      undo_stack << command

      if undo_stack.size > 10
        undo_stack.shift
      end
    end

    def undo
      if command = undo_stack.pop
        command.undo(self)

        self.redo_stack << command
      end
    end

    def redo
      if command = redo_stack.pop
        command.redo(self)

        undo_stack << command

        if undo_stack.size > 10
          undo_stack.shift
        end
      end
    end

    def centered_coords(canvas, item)
      # centered coords
      mx = (canvas.x + canvas.width) / 2.0
      my = (canvas.y + canvas.height) / 2.0

      w = (item.width) * zoomf
      h = (item.height) * zoomf

      cx = mx - (w / 2.0)
      cy = my - (h / 2.0)

      x = cx + sheet.offset_x.to_f 
      y = cy + sheet.offset_y.to_f

      Hokusai::Rect.new(x.round(2), y.round(2), w, h)
    end

    def flip_colors
      fg = self.foreground_color
      self.foreground_color = self.background_color
      self.background_color = fg
    end

    def move_layer(from, to, direction)
      new_layers = []
      from_layer = layers.find { |f| f.name == from }
      layers.delete(from_layer)

      while layer = layers.shift
        if layer.name == to
          if direction == :up
            new_layers << from_layer
            new_layers << layer
          else
            new_layers << layer
            new_layers << from_layer
          end
        else
          new_layers << layer
        end
      end

      self.layers = new_layers
    end

    def add_image_layer(name, path)
      image = Hokusai::Image.from_file(path)
      layer = Layer.new(name, self)
      texture = Hokusai::Texture.init(image.width.to_f, image.height.to_f)
      commands = Hokusai::Commands.new

      commands.image(image, 0.0, 0.0, image.width.to_f, image.height.to_f)
      texture.apply(commands.queue)
      layer.texture = texture
      layers << layer

      @active_layer = name
    end

    def add_layer(name)
      if name == "New Layer"
        name = "New Layer #{@counter}"
      end

      @counter += 1
      @layers << Layer.new(name, self)
    
      @active_layer = name
    end

    def layer_activate(name)
      tool.on_deactivate if tool.respond_to?(:on_deactivate)

      @active_layer = name
    end

    def layer_remove(name)
      return if @layers.size <= 1

      @layers.reject! { |l| l.name == name }

      if active_layer == name
        @active_layer = @layers.last.name
        @drag_layer = nil
        @drag_y = nil
      end
    end

    def tool_add(tool_klass)
      @tools[tool_klass.id] = tool_klass.new(self)
    end

    def tool_activate(id)
      tool.on_deactivate if tool.respond_to?(:on_deactivate)

      @active_tool = id
    end

    def tool
      @tools[@active_tool || "move"]
    end

    def layer
      @layers.find { |l| l.name == @active_layer }
    end

    def set_zoom(amount)
      self.zoom = amount
    end

    def zoomf
      zoom / 100.0
    end

    def direct_select(x, y)
      layers.select(&:visible).reverse.find do |layer|
        layer
      end
    end

    def image
      tex = Hokusai::Texture.init(sheet.width, sheet.height)
      commands = Hokusai::Commands.new

      layers.each do |layer|
        next unless layer.visible && layer.texture

        commands.blend_mode_begin(layer.blend_mode) if layer.blend_mode

        commands.texture(layer.texture, 0.0, 0.0) do |command|
          command.width = sheet.width.to_f
          command.height = sheet.height.to_f
        end    

        commands.blend_mode_end if layer.blend_mode
      end

      tex.clear
      tex.apply(commands.queue)
      image = Hokusai::Image.from_texture(tex)
      image.flip_vertical
      image
    end

    def render(canvas, block)
      self.canvas = canvas

      block.draw_with do |commands|
        commands.scissor_begin(canvas.x, canvas.y, canvas.width, canvas.height)
      end

      centered = sheet.render(canvas, block, zoom)
      centered.x = canvas.x if canvas.x > centered.x
      centered.y = canvas.y if canvas.y > centered.y

      
      block.draw_with do |commands|
        commands.scissor_begin(centered.x, centered.y, centered.width, centered.height)
      end

      layers.each do |layer|
        layer.render(canvas, block, zoom)
      end

      block.draw_with do |commands|
        commands.scissor_end
        commands.scissor_end
      end
    end
  end
end
