class HokusaiPaint::GroupOptions < Hokusai::Block
  template <<~EOF
  [template]
    hblock { :width="300.0" }
      icon { type="blender" size="18" color="255,255,255" width="60"}
      dropdown { size="18" @change="update_blend" direction="up" :options="blend_modes"}
  EOF

  computed! :control

  uses(
    hblock: Hokusai::Blocks::Hblock,
    icon: Hokusai::Blocks::Icon,
    dropdown: Hokusai::Blocks::Dropdown
  )

  def update_blend(value)
    value = nil if value == "none"

    control.layer.blend_mode = value
  end

  def render(canvas)
    draw do
      rect(canvas.x, canvas.y, canvas.width, canvas.height) do |command|
        command.color = Hokusai::Color.new(44, 44, 44)
      end
    end

    yield canvas
  end

  def blend_modes
    %w[none alpha multiply additive colors subtract]
  end
end