module HokusaiPaint
  class ToolbarButton < Hokusai::Block
    style <<~EOF
    [style]
    tooltipStyle {
      direction: "right";
    }
    iconStyle {
      width: 30.0;
      color: rgb(222,222,222);
      outline: outline(0.0, 1.0, 1.0, 0.0);
      outline_color: rgb(122, 110, 65);
      size: 12;
    }

    iconStyle@hover {
      cursor: "pointer";
    }

    iconStyle@mousedown {
      color: rgb(0, 0, 0);
      cursor: "pointer";
    }
    EOF

    template <<-EOF
    [template]
      tooltip { ...tooltipStyle :label="label" }
        icon { 
          @click="emit_icon" 
          ...iconStyle 
          :type="icon" 
          :background="background"
        }
    EOF

    computed! :icon
    computed! :label
    computed :active, default: false

    uses(
      tooltip: Hokusai::Blocks::Tooltip,
      icon: Hokusai::Blocks::Icon
    )

    def background
      return Hokusai::Color.new(142, 127, 65) if active
    end

    def emit_icon(event)
      emit("selected", label)
    end
  end

  class Toolbar < Hokusai::Block
    style <<~EOF
    [style]
    container {
      background: rgb(112, 101, 58);
    }

    row {
      wrap: true;
    }

    tooltipStyle {
      direction: "right";
    }

    iconStyle {
      width: 30.0;
      color: rgb(222,222,222);
      outline: outline(0.0, 1.0, 1.0, 0.0);
      outline_color: rgb(75, 75, 75);
      size: 23;
    }

    iconStyle@mousedown {
      background: rgb(141, 127, 70);
      color: rgb(0, 0, 0);
      cursor: "pointer";
    }

    size {
      width: 30.0;
      height: 30.0;
    }
    
    bottom {
      height: 60.0;
    }
    EOF
    
    template <<~EOF
    [template]
      vblock { ...container }
        hblock { ...row }
          [for="button in buttons"]
            button {
              ...size
              :label="label(button)"
              :icon="icon(button)"
              :active="is_active(button)
              :key="button_index(button)"
              @selected="activate"
            }
        vblock { ...bottom }
          colorwidget
    EOF

    uses(
      vblock: Hokusai::Blocks::Vblock,
      hblock: Hokusai::Blocks::Hblock,
      button: ToolbarButton,
      tooltip: Hokusai::Blocks::Tooltip,
      icon: Hokusai::Blocks::Icon,
      colorwidget: HokusaiPaint::ColorWidget,
    )

    inject :control
    attr_accessor :active

    def on_mounted
      node.meta.set_prop(:width, 60)
    end

    def button_index(button)
      "#{button.last}-#{is_active(button)}"
    end

    def label(button)
      button.first
    end

    def icon(button)
      button.last
    end
    
    def is_active(button)
      control.active_tool == button.first
    end

    def activate(button)
      self.active = button

      control.tool_activate button
    end

    def buttons
      control.tools.map do |k, v|
        [k, v.class.icon]
      end
    end
  end
end
