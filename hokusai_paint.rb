require_relative "./hokusai_paint/patches"
require_relative "./hokusai_paint/control"

require_relative "./hokusai_paint/commands/base"
require_relative "./hokusai_paint/commands/rect"
require_relative "./hokusai_paint/commands/layer"
require_relative "./hokusai_paint/commands/transform"
require_relative "./hokusai_paint/tools/color_widget"

require_relative "./hokusai_paint/blocks/toolbar"
require_relative "./hokusai_paint/blocks/stage"
require_relative "./hokusai_paint/blocks/rulered"
require_relative "./hokusai_paint/blocks/group_options"

require_relative "./hokusai_paint/groups/navigator"
require_relative "./hokusai_paint/groups/layers"

require_relative "./hokusai_paint/tools/base"
require_relative "./hokusai_paint/tools/move"
require_relative "./hokusai_paint/tools/rect"
require_relative "./hokusai_paint/tools/dropper"
require_relative "./hokusai_paint/tools/brush"
require_relative "./hokusai_paint/tools/direct_select"
require_relative "./hokusai_paint/tools/transform"

class Variable < Hokusai::Block
  template <<~EOF
  [template]
    empty
  EOF

  uses(empty: Hokusai::Blocks::Empty)

  computed! :klass
  inject :control

  attr_accessor :last

  def after_updated
    if @last_height != children[0].node.meta.get_prop(:height)
      @last_height = children[0].node.meta.get_prop(:height)

      node.meta.set_prop(:height, @last_height)
      emit("height_updated", @last_height)
    end
  end

  def before_updated
    if last != klass
      self.last = klass
      app = klass

      app.node.meta.set_prop(:control, control)
      node.meta.set_child(0, app)
    end
  end

  def on_mounted
    raise Hokusai::Error.new("Class #{klass} is not a Hokusai::Block") unless klass.is_a?(Hokusai::Block)
    self.last = klass
    app = klass
    app.node.meta.set_prop(:control, control)
    node.meta.set_child(0, app)
  end

  def render(canvas)
    if Hokusai.can_render(canvas)
      yield canvas
    end
  end
end

require_relative "./hokusai_paint/blocks/tabbox"

class HokusaiPaint::App < Hokusai::Block
  style <<-EOF
  [style]
  toolStyle {
    background: rgb(48, 48, 48);
    outline: outline(0.0, 0.0, 0.0, 1.0);
    outline_color: rgb(62, 62, 62);
  }

  dropdownStyle {
    size: 20;
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

  rulerIconStyle {
    type: "numbers";
    color: rgb(244, 244, 244);
    width: 45.0;
    outline: outline(0.0, 1.0, 0.0, 0.0);
    outline_color: rgb(33, 33, 33);
  }

  bottomIcon {
    color: rgb(222, 222, 222);
    width: 35.0;
    height: 38.0;
  }

  bottomIcon@hover {
    color: rgb(222,88,88);
    cursor: "pointer";
  }

  picker {
    z: 2;
    zposition: bounds(-340.0, 0.0, 0.0, 0.0);
    width: 300.0;
    height: 300.0;
  }
  EOF
  template <<-EOF
  [template]
    hblock#app { @keypress="handle_keypress" }
      toolbar
      vblock.stage
        rulered
          stage
        group_options { :control="control" :height="40"}
      vblock { :width="350.0" ...toolStyle }
        navigator { :control="control" height="200.0" }
        colorpicker
        tabbox { :tabgroup="tabgroup" }
    hblock { :height="40.0" background="22,22,22" }
      icon { ...bottomIcon @click="open" type="folder_open" }
      icon { ...bottomIcon @click="save" type="save" }
  EOF

  uses(
    group_options: HokusaiPaint::GroupOptions,
    navigator: HokusaiPaint::Navigator,
    empty: Hokusai::Blocks::Empty,
    vblock: Hokusai::Blocks::Vblock,
    hblock: Hokusai::Blocks::Hblock,
    toolbar: HokusaiPaint::Toolbar,
    colorpicker: HokusaiPaint::ColorPicker,
    stage: HokusaiPaint::Stage,
    dropdown: Hokusai::Blocks::Dropdown,
    slider: Hokusai::Blocks::Slider,
    variable: Variable,
    rulered: HokusaiPaint::Rulers,
    tooltip: Hokusai::Blocks::Tooltip,
    icon: Hokusai::Blocks::Icon,
    tabbox: HokusaiPaint::Tabbox,
  )

  provide :control, :control

  attr_reader :ruler

  SHORTCUTS = {
    h: "move",
    a: "direct select",
    t: "transform",
    r: "rect",
    e: "dropper",
    b: "brush"
  }

  def handle_keypress(event)
    if event.symbol == :z && (event.ctrl || event.super)
      if event.shift
        control.redo
      else
        control.undo
      end

      return
    end

    if tool = SHORTCUTS[event.symbol]
      control.tool_activate tool

      return
    end
  end

  def control
    @control ||= begin
      control = HokusaiPaint::Control.new(500,500)
      control.tool_add(HokusaiPaint::Tools::Move)
      control.tool_add(HokusaiPaint::Tools::DirectSelect)
      control.tool_add(HokusaiPaint::Tools::Transform)
      control.tool_add(HokusaiPaint::Tools::Rect)
      control.tool_add(HokusaiPaint::Tools::Dropper)
      control.tool_add(HokusaiPaint::Tools::Brush)
      control
    end
  end

  def show_color
    control.picking_color
  end

  def save(event)
    if file = Hokusai.save_file(filter: "png,jpg,jpeg,gif")
      control.image.export(file)
    end
  end

  def open(event)
    if file = Hokusai.open_file(filter: "png,jpg,jpeg,gif")
      basename = File.basename(file)
      control.add_image_layer(basename, file)
    end
  end

  def tabgroup
    @tabgroup ||= begin
      group = TabGroup.new(self)
      group.add("Layers", HokusaiPaint::LayerMenu)

      group
    end
  end

  def tabgroup_top
    @tabgroup_top ||= begin
      group = TabGroup.new(self)
      group.add("Color", HokusaiPaint::ColorPicker)
      group
    end
  end

  def toggle_ruler(event)
    @ruler = !@ruler
  end

  def tool_options
    control.tool.tool_options
  end

  def file_opts
    %w[open new etc]
  end

  def initialize(**args)
    @ruler = true
    super
  end
end

Hokusai::Backend.run(HokusaiPaint::App) do |config|
  config.title = "Hokusai Paint"
  config.fps = 60
  config.width = 1400
  config.height = 800
  # config.draw_fps = true
  # config.log = true
  config.audio = false

  config.after_load do
    Hokusai.fonts.register "default", Hokusai::Backend::Font.from_ext("assets/OpenSans.ttf", 60)
    Hokusai.fonts.activate "default"

    Hokusai.fonts.register "icons", Hokusai::Backend::Font.from_ext("assets/fa2.ttf", 30, Hokusai::Blocks::Icon::MAP.values.join(""))
  end
end
