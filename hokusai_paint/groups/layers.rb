module HokusaiPaint
  class LayerTex < Hokusai::Block
    template <<-EOF
    [template]
      virtual
    EOF

    computed! :layer

    def render(canvas)
      draw do
        texture(layer.control.sheet.texture, canvas.x, canvas.y) do |command|
          command.width = canvas.width
          command.height = canvas.height
        end

        if layer.texture
          texture(layer.texture, canvas.x, canvas.y) do |command|
            command.width = canvas.width
            command.height = canvas.height
          end
        end
      end

      yield canvas
    end
  end


  class LayerItem < Hokusai::Block
    style <<-EOF
    [style]
    icon {
      color: rgb(222,222,222);
      size: 13;
      width: 40.0;
      height: 40.0;
      background: rgb(22,22,22, 0);
    }
    icon@hover {
      cursor: "pointer";
      color: rgb(202, 66, 66);
    }
    label {
      color: rgb(222, 222, 222);
      size: 18;
    }

    preview {
      width: 40.0;
      height: 40.0;
    }
  
    outer {
      height: 50.0;
      padding: padding(5.0, 5.0, 5.0, 5.0);

      outline: outline(0.0, 0.0, 1.0, 0.0);
      outline_color: rgb(84, 84, 84);
    }
    container {
      padding: padding(10.0, 5.0, 5.0, 10.0);
    }
    container@hover {
      cursor: "pointer";
    }
    EOF
    template <<~EOF
    [template]
      hblock { ...outer :background="bg" @mouseout="stop_drop" @hover="handle_drop" }
        icon { type="grip" width="20.0" ...icon @click="start_drag" }
        texture { :layer="layer" ...preview }
        hblock { ...container @click="activate" }
          text { :content="layer.name" ...label }
          empty
        icon { :type="eye_type" ...icon @click="toggle" }
        icon { type="trash" ...icon @click="delete" }
    EOF

    computed! :layer

    uses(
      texture: LayerTex,
      icon: Hokusai::Blocks::Icon,
      text: Hokusai::Blocks::Label,
      empty: Hokusai::Blocks::Empty,
      hblock: Hokusai::Blocks::Hblock,
    )

    def stop_drop(_)
      @dropping = false
      @dragging = false
    end

    def start_drag(event)
      if event.left.down && !@dragging
        @dragging = true
        layer.control.drag_layer = layer.name
        layer.control.drag_y = event.pos.y
      elsif event.left.up
        @dragging = false
        layer.control.drag_layer = nil
      end
    end

    def handle_drop(event)
      if event.left.up && layer.control.drag_layer && !node.meta.focused
        direction = event.pos.y > layer.control.drag_y ? :down : :up
        layer.control.move_layer(layer.control.drag_layer, layer.name, direction)

        layer.control.drag_layer = nil
      elsif event.left.down && layer.control.drag_layer && !node.meta.focused
        @dropping = true
      elsif event.left.up
        @dragging = false
        @dropping = false
        layer.control.drag_layer = nil
      end
    end

    def eye_type
      layer.visible ? "eye" : "eyeclose"
    end

    def bg
      return Hokusai::Color.new(65, 87, 125) if @dragging
      return Hokusai::Color.new(72, 64, 32) if @dropping

      if layer.control.active_layer == layer.name
        Hokusai::Color.new(46, 63, 92)
      else
        Hokusai::Color.new(22, 22, 22, 0)
      end
    end

    def activate(event)
      layer.control.layer_activate layer.name
    end

    def delete(event)
      layer.control.apply(Commands::LayerDelete.new(layer.name))
    end

    def on_mounted
      node.meta.set_prop(:height, 50.0)
    end

    def toggle(event)
      layer.visible = !layer.visible
    end

    def render(canvas)
      if Hokusai.can_render(canvas)
        yield canvas
      end
    end
  end

  class LayerMenu < Hokusai::Block
    style <<~EOF
    [style]
    icon {
      width: 40;
      background: rgb(77, 77, 77);
      color: rgb(187, 174, 125);
    }

    icon@hover {
      color: rgb(202, 66, 66);
      cursor: "pointer";
    }
    
    input {
      cache: false;
      size: 18;
      color: rgb(50, 50, 50);
      padding: padding(10.0, 0.0, 0.0, 10.0);
    }
    new {
      outline: outline(1.0, 0.0, 0.0. 0.0);
      background: rgb(50, 50, 50);
      outline_color: rgb(55,55,55);
    }
    container {
      background: rgb(82, 74, 43);
    }
    EOF
    template <<~EOF
    [template]
    panel { ...container }
      [for="layer in layers"]
        layer { :layer="layer" :key="index" }
    hblock { height="40"  ...new }
      input { :model="name" ...input }
      icon { type="add" ...icon @click="add_layer" }
    EOF

    computed :control, default: nil

    uses(
      input: Hokusai::Blocks::Input,
      hblock: Hokusai::Blocks::Hblock,
      empty: Hokusai::Blocks::Empty,
      dynamic: Hokusai::Blocks::Dynamic,
      icon: Hokusai::Blocks::Icon,
      panel: Hokusai::Blocks::Panel,
      vblock: Hokusai::Blocks::Vblock,
      layer: LayerItem,
    )

    attr_accessor :name

    def initialize(**args)
      @name = "New Layer"

      super
    end

    def add_layer(event)
      control.tool.on_deactivate if control.tool.respond_to?(:on_deactivate)

      control.apply(Commands::LayerNew.new(@name))

      @name = "New Layer"
    end

    def layers
      control&.layers || []
    end

    def layer_index(layer, idx)
      "#{layer.name}-#{idx}"
    end
  end
end
