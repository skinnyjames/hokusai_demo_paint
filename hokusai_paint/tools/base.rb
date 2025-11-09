module HokusaiPaint
  module Tools
    class Base
      def mousedown(event); end
      def mousemove(event); end
      def mouseout(event); end
      def click(event); end
      def hover(event); end
      def keypress(event); end
      def keydown(event); end
      def keyup(event); end

      def render(canvas, block); end
    end
  end
end
