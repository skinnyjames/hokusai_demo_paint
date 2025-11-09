module HokusaiPaint
  class Commands::Transform < Commands::Base
    def initialize(origin, transformed, control)
      @origin = origin
      @transformed = transformed
      @before = control.layer.copy
    end

    def execute(control)
      control.layer.transform(@transformed)

      @after = control.layer.copy
    end

    def undo(control)
      if i = control.layers.index { |l| l.name == @after.name}
        control.layers[i] = @before.copy
      end
  
      control.layer.active = nil
      control.layer.active_blocks = false
      current = @before
      @before = @after.copy
      @after = current
    end

    def redo(control)
      undo(control)
    end
  end
end
