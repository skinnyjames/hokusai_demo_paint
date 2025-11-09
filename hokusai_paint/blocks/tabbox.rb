
module HokusaiPaint
  class Tab < Hokusai::Block
    style <<~EOF
    [style]
    tabContainer {
      background: rgb(112, 101, 58);
      padding: padding(4.0, 4.0, 4.0, 8.0);
      outline: outline(0.0, 1.0, 0.0, 0.0);
      outline_color: rgb(122, 110, 65);
    }

    tabContainer@hover {
      background: rgb(222,88,88);
      cursor: "pointer";
    }
    
    labelStyle {
      size: 17;
      color: rgb(222,222, 222);
    }
    
    labelStyle@hover {
      color: rgb(22, 22, 22);
    }
    EOF
    template <<~EOF
    [template]
      vblock { ...tabContainer @click="activate" :background="background" }
        text { :content="tab.title" ...labelStyle  @width_updated="update_width" }
    EOF

    computed! :tab

    uses(
      vblock: Hokusai::Blocks::Vblock,
      text: Hokusai::Blocks::Label,
    )

    def update_width(width)
      node.meta.set_prop(:width, width + 15.0)
    end

    def activate(event)
      emit("activate", tab)
    end

    def background
      tab.active ? [141, 124, 57] : [112, 101, 58]
    end
  end


  class Tabbox < Hokusai::Block
    style <<~EOF
    [style]
    background {
      background: rgb(112, 101, 58);
      height: 28;
    }
    EOF

    template <<~EOF
    [template]
    vblock {  @hover="on_mousemove" }
      hblock { ...background }
        [for="tab in tabgroup"]
          tab { :key="index" :tab="tab" @activate="set_active" }
      vblock
        variable { :klass="tabgroup.active.klass" }
    EOF

    computed! :tabgroup

    uses(
      hblock: Hokusai::Blocks::Hblock,
      vblock: Hokusai::Blocks::Vblock,
      text: Hokusai::Blocks::Label,
      variable: Variable,
      tab: Tab,
    )

    attr_accessor :current_y, :moving, :resizing, :current_height

    def initialize(**args)
      @resizing = false
      @moving = false
      @current_y = 0.0
      @current_height = 0.0

      super
    end

    def on_mousemove(event)
      if event.pos.y >= current_y - 5 && event.pos.y <= current_y + 5
        Hokusai.set_mouse_cursor(:arrow)

        @resizing = true if event.left.down
      elsif @resizing && event.left.down
        height = current_height + (current_y - event.pos.y)
        # node.meta.set_prop(:height, height)
        self.current_y = event.pos.y
        # self.current_height = height
        event.stop
      else
        @resizing = false
      end

    end

    def on_mounted
      # node.meta.set_prop(:height, 400.0)
    end

    def set_active(tab)
      tabgroup.activate tab.title
    end

    def render(canvas)
      self.current_y = canvas.y
      # self.current_height = canvas.height

      yield canvas
    end
  end
end

class TabGroup
  include Enumerable

  def initialize(parent)
    @parent = parent
    @tabs = []
  end

  def active
    find(&:active) || begin
      first.active = true
      first
    end
  end

  def add(title, klass)
    @tabs << Tab.new(title, klass, @parent)
  end

  def remove(title)
    reject! do |tab|
      tab.title == title
    end
  end

  def activate(title)
    @tabs.each do |tab|
      if tab.title == title
        tab.active = true
      else
        tab.active = false
      end
    end
  end

  def each(&block)
    @tabs.each do |tab|
      block.call(tab)
    end
  end
end

class Tab
  attr_accessor :title, :klass, :active

  def initialize(title, klass, parent)
    @title = title
    @klass = klass.mount("root", parent.node)
    @active = false
  end
end
