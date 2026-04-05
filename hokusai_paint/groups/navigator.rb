module HokusaiPaint
  class Navigator < Hokusai::Block
    style <<~EOF
    [style]
    slider {
      height: 40.0;
      background: rgb(232, 159, 175);
    }

    container {
      background: rgb(114, 45, 60);
    }
    sliderStyle {
      min: 1;
      max: 1200;
      step: 1;
      initial: 100;
      height: 40;
      background: rgb(43, 28, 28);
      fill: rgb(138, 57, 57);
    }
    EOF

    template <<~EOF
    [template]
      empty {
        @hover="move"
      }
      vblock {...slider }
        slider#zoom { ...sliderStyle @change="zoom"}
    EOF

    uses(
      empty: Hokusai::Blocks::Empty,
      slider: Hokusai::Blocks::Slider,
      vblock: Hokusai::Blocks::Vblock,
    )

    computed! :control

    def initialize(**args)
      @moving = false
      super
    end

    def zoom(amount)
      control.set_zoom(amount)
    end

    def move(event)
        event.stop
      if event.left.down && @moving
        control.sheet.move(event.delta.x, event.delta.y)
      elsif event.left.down
        @moving = true
        event.stop
      else
        @moving = false
      end
    end

    def render(canvas)
      draw do
        tw = control.sheet.width
        th = control.sheet.height

        ratio = tw / th
        # subtract the zoom slider height
        ch = canvas.height - 40.0
        cw = ch * ratio

        x = ((canvas.width - cw) / 2.0) + canvas.x
        y = ((canvas.height - ch) / 2.0) + canvas.y - 20.0

        # background
        rect(canvas.x, canvas.y, canvas.width, canvas.height) do |command|
          command.color = Hokusai::Color.new(114, 45, 60)
        end

        # foreground
        rect(x, y, cw, ch) do |command|
          command.color = Hokusai::Color.new(222, 222, 222)
        end

        if control.layer.texture
          texture(control.layer.texture, x, y) do |command|
            command.width = cw
            command.height = ch
          end
        end

        # we actually want to render the stage viewport dimensions
        # # centered coords
        fzoom = control.zoomf
        vratio = control.canvas.width / control.canvas.height
        
        zh = ch / fzoom
        zw = zh * vratio

        mx = x + (cw / 2.0)
        my = canvas.y + (canvas.height / 2.0)

        cx = mx - (zw / 2.0)
        cy = my - (zh / 2.0) - 20

        cx = canvas.x if cx < canvas.x
        cy = canvas.y if cy < canvas.y
        zw = canvas.width if cx < canvas.x
        zh = canvas.height - 40 if zh > canvas.height - 40

        rect(cx, cy, zw, zh) do |command|
          command.color = Hokusai::Color.new(55, 55,55, 0)
          command.outline = Hokusai::Outline.convert(1.0)
          command.outline_color = Hokusai::Color.new(222, 33, 22)
        end
      end

      yield canvas
    end
  end
end
