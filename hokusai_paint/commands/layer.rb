module HokusaiPaint
  class Commands::LayerNew < Commands::Base
    attr_accessor :name

    def initialize(name)
      @name = name
    end

    def execute(control)
      if name == "New Layer"
        @name = "New Layer #{control.counter}"
      end

      control.counter += 1
      control.layers << Layer.new(name, control)
    
      control.active_layer = name
    end

    def undo(control)
      control.layer_remove(@name)
    end

    def redo(control)
      control.add_layer(@name)
    end
  end

  class Commands::LayerDelete < Commands::Base
    def initialize(name)
      @name = name
    end

    def execute(control)
      control.layer_remove(@name)
    end

    def undo(control)
      control.add_layer(@name)
    end

    def redo(control)
      execute(control)
    end
  end
end
