class Hokusai::Blocks::Icon < Hokusai::Block
  template <<~EOF
  [template]
    virtual
  EOF

  MAP = {
    eyeclose: "\u{F070}",
    eye: "\u{F06E}",
    up: "\u{F106}",
    down: "\u{F107}",
    right: "\u{F105}",
    left: "\u{F104}",
    trash: "\u{F1F8}",
    add: "\u{F0FE}",
    hand: "\u{F256}",
    square: "\u{F0C8}",
    dropper: "\u{F1FB}",
    brush: "\u{F1FC}",
    folder_open: "\u{F07C}",
    grip: "\u{F58E}",
    save: "\u{F0C7}",
    blender: "\u{F517}",
    repeat: "\u{F363}",
    pointer: "\u{f245}",
    resize: "\u{f424}",
  }

  computed! :type
  computed :size, default: 15, convert: proc(&:to_i)
  computed :color, default: Hokusai::Color.new(0, 0, 0), convert: Hokusai::Color
  computed :background, default: Hokusai::Color.new(255, 255, 255, 0), convert: Hokusai::Color
  computed :outline, default: Hokusai::Outline.default, convert: Hokusai::Outline
  computed :outline_color, default: Hokusai::Color.new(0, 0, 0, 0), convert: Hokusai::Color
  computed :padding, default: Hokusai::Padding.new(2.5, 5.0, 2.5, 5.0), convert: Hokusai::Padding
  computed :center, default: true

  def get_icon_from_type
    icon = MAP[type.to_sym]
    
    raise("No icon #{type}") if icon.nil?

    icon
  end

  def center_in(canvas, size)
    x = canvas.x + (canvas.width / 2.0) - ((size / 2) || 0.0)
    y = canvas.y + (canvas.height / 2.0) - ((size / 2) || 0.0)

    [x, y]
  end

  def render(canvas)
    if Hokusai.fonts.get("icons")
      draw do
        rect(canvas.x, canvas.y, canvas.width, canvas.height) do |command|
          command.color = background
          command.outline = outline
          command.outline_color = outline_color
        end

        x, y = center_in(canvas, size)

        text(get_icon_from_type, x, y) do |command|
          command.padding = padding
          command.font = Hokusai.fonts.get("icons")
          command.size = size
          command.color = color
        end
      end

      yield canvas
    end
  end
end
