module HokusaiPaint
  class Commands::Rect < Commands::Base
    def self.build(control)
      command = new(control)
      
      yield command
      
      command
    end

    attr_accessor :bounds, :color, :layer, :outline, :outline_color

    def initialize(control)
      @bounds = Hokusai::Rect.new(0.0, 0.0, 10.0, 10.0)
      @color = control.foreground_color
      @outline = Hokusai::Outline.new(0.0, 0.0, 0.0, 0.0)
      @outline_color = control.background_color
      @layer = control.layer
    end

    def execute(control)
      commands = Hokusai::Commands.new
      merged = layer.texture ? bounds.add(layer.bounds) : bounds

      tex = Hokusai::Texture.init(merged.width, merged.height)
      tex.clear

      if layer.texture
        ox = layer.offset_x
        oy = layer.offset_y

        if bounds.x < ox
          lx = ox - bounds.x
          rx = 0.0
        else
          lx = 0.0
          rx = bounds.x - ox
        end

        if bounds.y < oy
          ly = oy - bounds.y
          ry = 0.0
        else
          ly = 0.0
          ry = bounds.y - oy
        end

        commands.texture(layer.texture, lx, ly)

        commands.rect(rx, ry, bounds.width, bounds.height) do |command|
          command.color = color
          command.outline = outline
          command.outline_color = outline_color
        end
      else
        commands.rect(0.0, 0.0, bounds.width, bounds.height) do |command|
          command.color = color
          command.outline = outline
          command.outline_color = outline_color
        end
      end

      tex.apply(commands.queue)

      @before = layer.copy

      layer.offset_x = merged.x
      layer.offset_y = merged.y
      layer.texture = tex

      @after = layer.copy
    end

    def undo(control)
      if i = control.layers.index { |l| l.name == @after.name}
        control.layers[i] = @before
      end
  
      current = @before
      @before = @after
      @after = current
    end

    def redo(control)
      undo(control)
    end
  end
end
