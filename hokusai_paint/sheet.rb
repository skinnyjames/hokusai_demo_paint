module HokusaiPaint
    class Sheet
    attr_accessor :width, :height, :offset_x, :offset_y,
                  :read_x, :read_y, :read_w, :read_h
    attr_reader :texture, :control

    def initialize(width, height, control)
      @width = width
      @height = height
      @control = control
      @offset_x = 0
      @offset_y = 0

      @read_x = 0
      @read_y = 0
      @read_w = 0
      @read_h = 0
    end

    def to_screen(rect)
      x =  (rect.x * control.zoomf) + (read_x)
      y =  (rect.y * control.zoomf) + (read_y)
      w =  rect.width * control.zoomf
      h =  rect.height * control.zoomf

      Hokusai::Rect.new(x, y, w, h)
    end

    def normalized(rect)
      x =  (rect.x / control.zoomf) - (read_x / control.zoomf)
      y =  (rect.y / control.zoomf) - (read_y / control.zoomf)
      w =  rect.width / control.zoomf
      h =  rect.height / control.zoomf

      Hokusai::Rect.new(x, y, w, h)
    end

    def move(dx, dy)
      self.offset_x += dx
      self.offset_y += dy
    end

    def bounds
      [offset_x, offset_y, width + offset_x, height + offset_y]
    end

    def render(canvas, block, zoom)
      centered = control.centered_coords(canvas, self)

      @texture ||= begin
        texture = Hokusai::Texture.init(20, 20)
        commands = Hokusai::Commands.new

        commands.rect(0, 0, 20, 20) do |cmd|
          cmd.color = Hokusai::Color.new(222,222,222)
        end

        commands.rect(10, 0, 10, 10) do |cmd|
          cmd.color = Hokusai::Color.new(188,188,188)
        end

        commands.rect(0, 10, 10, 10) do |cmd|
          cmd.color = Hokusai::Color.new(188,188,188)
        end

        texture.apply(commands.queue)

        ntext = Hokusai::Texture.init(width, height)
        commands = Hokusai::Commands.new
        commands.texture(texture, 0.0, 0.0) do |f|
          f.width = width.to_f
          f.height = height.to_f
          f.repeat = true
        end

        ntext.clear
        ntext.apply(commands.queue)
        ntext
      end

      block.draw_with do |commands|
        # canvas background
        commands.rect(canvas.x, canvas.y, canvas.width, canvas.height) do |command|
          command.color = Hokusai::Color.new(111, 111, 111)
        end

        self.read_x = centered.x
        self.read_y = centered.y
        
        commands.texture(@texture, read_x, read_y) do |command|
          command.width = centered.width.to_f
          command.height = centered.height.to_f
        end
      end

      centered
    end
  end
end