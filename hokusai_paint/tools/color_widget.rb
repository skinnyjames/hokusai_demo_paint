module HokusaiPaint
  class ColorPicker < Hokusai::Block
    style <<~EOF
    [style]
    container {
      background: rgb(37, 37, 37);
    }
    pickerStyle {
      height: 200.0;
    }
    inputContainer {
      height: 40.0;
      background: rgb(40, 40, 40);
    }
    inputStyle {
      size: 17;
      padding: padding(0.0, 0.0, 0.0, 0.0);
    }
    
    sliderStyle {
      min: 0;
      max: 255;
      step: 1;
      size: 18;
      height: 40.0;
      fill: rgb(111,111,111);
      background: rgb(22,22,22);
    }
    EOF
    template <<~EOF
    [template]
      vblock { @keypress="commit" ...container @mousemove="prevent" @mousedown="prevent" @click="prevent"}
        picker { @change="set_hue" ...pickerStyle}
        slider { ...sliderStyle :initial="initial_slider" @change="update_alpha" }
        vblock { ...inputContainer }
          input { :model="rgba" ...inputStyle }
    EOF

    uses(
      slider: Hokusai::Blocks::Slider,
      vblock: Hokusai::Blocks::Vblock,
      hblock: Hokusai::Blocks::Hblock,
      picker: Hokusai::Blocks::ColorPicker,
      input: Hokusai::Blocks::Input,
    )

    inject :control

    def prevent(event)
      # event.stop
    end

    def initial_slider
      control.foreground_color.alpha
    end

    def rgba
      @model ||= "#{control.foreground_color.r.round(0)}, #{control.foreground_color.g.round(0)}, #{control.foreground_color.b.round(0)}, #{control.foreground_color.a.round(0)}"
    end

    def commit(event)
      if event.symbol == :enter
        control.picking_color = nil
      end
    end

    def update_alpha(value)
      control.foreground_color.alpha = value
      @model = "#{control.foreground_color.r.round(0)}, #{control.foreground_color.g.round(0)}, #{control.foreground_color.b.round(0)}, #{control.foreground_color.a.round(0)}"
    end

    def set_hue(color)
      color.alpha = control.foreground_color.alpha
      control.foreground_color = color
      @model = "#{control.foreground_color.r.round(0)}, #{control.foreground_color.g.round(0)}, #{control.foreground_color.b.round(0)}, #{control.foreground_color.a.round(0)}"
    end
  end

  class ColorSwatches < Hokusai::Block
    template <<~EOF
    [template]
      empty {
        @click="change_color"
      }
    EOF

    uses(empty: Hokusai::Blocks::Empty)

    inject :control
    attr_accessor :last

    def change_color(event)
      if last
        flip_hit_box = Hokusai::Rect.new(last.x + 25, last.y, 15, 15)
        unless flip_hit_box.includes_x?(event.pos.x) && flip_hit_box.includes_y?(event.pos.y)
          control.picking_color = :foreground
          event.stop
        end
      end
    end

    def render(canvas)
      self.last = canvas.dup

      draw do
        rect(canvas.x, canvas.y, 25, 25) do |command|
          command.color = control.background_color
        end

        rect(canvas.x + 15, canvas.y + 15, 25, 25) do |command|
          command.color = control.foreground_color
        end
      end

      yield canvas
    end
  end

  class ColorWidget < Hokusai::Block
    style <<~EOF
    [style]
    container {
      padding: padding(10.0, 5.0, 10.0, 10.0);
    }
    EOF
    
    template <<~EOF
    [template]
      vblock { ...container @click="flip_swatch" }
        swatch
    EOF

    inject :control

    uses(
      vblock: Hokusai::Blocks::Vblock,
      swatch: HokusaiPaint::ColorSwatches
    )

    def flip_swatch(event)
      control.flip_colors
    end

    uses(vblock: Hokusai::Blocks::Vblock, swatch: HokusaiPaint::ColorSwatches)

    def render(canvas)
      font = Hokusai.fonts.get("icons")
      codepoint = Hokusai::Blocks::Icon::MAP[:repeat]
      text(codepoint, canvas.x + canvas.width - 20, canvas.y + 10) do |command|
        command.size = 10
        command.font = font
        command.color = Hokusai::Color.new(255, 255, 255)
      end

      yield canvas
    end
  end
end