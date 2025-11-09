class HokusaiPaint::Rulers < Hokusai::Block
  template <<-EOF
  [template]
    empty {
      z="2"
      ztarget="root"
      @mousemove="update_position"
      width="0.0"
      height="0.0"
    }
    slot
  EOF

  uses(empty: Hokusai::Blocks::Empty)

  inject :control
  
  attr_accessor :x, :y

  def update_position(event)
    self.x = event.pos.x
    self.y = event.pos.y
  end

  def render(canvas)
    draw do 
      active = Hokusai.fonts.active
      rect(canvas.x, canvas.y, canvas.width, 25.0) do |command|
        command.color = Hokusai::Color.new(46, 63, 92)
      end

      rect(canvas.x, canvas.y, 25.0, canvas.height) do |command|
        command.color = Hokusai::Color.new(46, 63, 92)
      end

      if x >= canvas.x
        # draw arrow
        text(Hokusai::Blocks::Icon::MAP[:down], x, canvas.y + 10) do |command|
          command.size = 15
          command.color = Hokusai::Color.new(222,222,222)
          command.font = Hokusai.fonts.get("icons")
        end
      end

      if y >= canvas.y && y 
        text(Hokusai::Blocks::Icon::MAP[:right], canvas.x + 10, y) do |command|
          command.size = 15
          command.color = Hokusai::Color.new(222,222,222)
          command.font = Hokusai.fonts.get("icons")
        end
      end

      i = -1000
      while i < 2000
        rx = (control.sheet.read_x) + i * (control.zoom / 100.0)

        if rx < canvas.x || rx > (canvas.x + canvas.width)
          i += 50
          next
        end

        text(i.round.to_s, rx, canvas.y + 2) do |command|
          command.size = 12
          command.color = Hokusai::Color.new(222,222,222)
        end

        i += 50
      end
    
      i = -1000
      while i < 2000
        ry = (control.sheet.read_y) + i * (control.zoom / 100.0)

        if ry < canvas.y + 25.0 || ry > (canvas.y + canvas.height - 40.0)
          i += 100
          next
        end

        arr = i.round.to_s.split("")
        arr.each_with_index do |a, idx|
          text(a, canvas.x + 5, ry + (idx * 8)) do |command|
            command.size = 8
            command.color = Hokusai::Color.new(222,222,222)
          end
        end

        i += 100
      end
    end

    canvas.x += 25.0
    canvas.y += 25.0
    canvas.width -= 25.0
    canvas.height -= 25.0

    yield canvas
  end

  def initialize(**args)
    @x = 0
    @y = 0

    super
  end
end