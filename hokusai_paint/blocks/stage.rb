module HokusaiPaint
  class Stage < Hokusai::Block
    template <<-EOF
    [template]
      empty {
        @hover="hover"
        @click="click"
        @mousedown="start_move"
        @mousemove="move"
        @mouseout="mouseout"
        @keypress="keypress"
        @keydown="keydown"
        @keyup="keyup"
      }
    EOF

    uses(empty: Hokusai::Blocks::Empty)

    inject :control

    def hover(event)
      control.tool.hover(event)
    end

    def keypress(event)
      control.tool.keypress(event)
    end

    def keydown(event)
      control.tool.keydown(event)
    end

    def keyup(event)
      control.tool.keyup(event)
    end

    def mouseout(event)
      control.tool.mouseout(event)
    end

    def click(event)
      control.tool.click(event) if node.meta.focused
    end

    def start_move(event)
      control.tool.mousedown(event) if node.meta.focused
    end

    def move(event)
      control.tool.mousemove(event) if node.meta.focused
    end

    def render(canvas)
      control.render(canvas, self)
      control.tool.render(canvas, self)

      yield canvas
    end
  end
end