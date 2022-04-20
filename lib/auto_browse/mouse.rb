require "bezier_curve"

module AutoBrowse
  module MouseMover

    module MathUtils
      def random_number_range(min, max)
        rand * (max - min) + min
      end

      # returns target if min < target < max
      # otherwise, returns min
      def clamp(target, min, max)
        [max, [min, target].max].min
      end

      def confine(target, min, max)
        case
        when target < min
          min
        when target > max
          max
        else
          target
        end
      end

      # Calculate the amount of time needed to move from (x1, y1) to (x2, y2)
      # given the width of the element being clicked on
      # https://en.wikipedia.org/wiki/Fitts%27s_law
      def fitts(distance, width)
        a = 0
        b = 2
        id = Math.log2(distance / width + 1)
        a + b * id
      end

      # returns 0 if the supplied value is less than 0; otherwise returns the given value
      def identity_floor0(x)
        x < 0 ? 0 : x
      end

      # coord is a pair: [x, y]
      # returns [identity_floor0(x), identity_floor0(y)]
      def coordinate_floor0(coord)
        coord.map {|val| identity_floor0(val) }
      end
    end

    # vector math comes from https://github.com/Xetera/ghost-cursor/blob/master/src/math.ts
    class Vector
      include MathUtils

      attr_accessor :x, :y

      def initialize(x, y)
        @x, @y = x.to_f, y.to_f
      end

      def to_a
        [x, y]
      end

      def +(other)
        Vector.new(x + other.x, y + other.y)
      end

      def -(other)
        Vector.new(x - other.x, y - other.y)
      end

      def *(multiplier)
        Vector.new(x * multiplier, y * multiplier)
      end

      def /(divisor)
        Vector.new(x / divisor, y / divisor)
      end

      def direction(other)
        other - self
      end

      def perpendicular
        Vector.new(y, -1 * x)
      end

      def magnitude
        Math.sqrt(x ** 2 + y ** 2)
      end

      def unit
        self / magnitude
      end

      def set_magnitude(magnitude)
        unit * magnitude
      end
      
      # returns a randomly chosen vector that points to some point on the vector from self to other.
      def random_vector_on_line(other)
        vec = direction(other)
        multiplier = rand
        self + (vec * multiplier)
      end

      def random_normal_line(other, magnitude)
        rand_mid = random_vector_on_line(other)
        normal_vector = direction(rand_mid).perpendicular.set_magnitude(magnitude)
        [rand_mid, normal_vector]
      end

      def generate_bezier_anchors(other, spread)
        side = rand.round == 1 ? 1 : -1
        calc = ->() do
          rand_mid, normal_vector = self.random_normal_line(other, spread)
          choice = normal_vector * side
          rand_mid.random_vector_on_line(rand_mid + choice)
        end
        [calc.(), calc.()].sort {|a, b| a.x - b.x }
      end

      def overshoot(radius)
        a = rand * 2 * Math::PI
        rad = radius * Math.sqrt(rand)
        vector = Vector.new(rad * Math.cos(a), rad * Math.sin(a))
        self + vector
      end

      def bezier_curve(finish)
        min = 10
        max = 90

        start = self
        deviation = start.direction(finish).magnitude * 0.2
        spread = confine(deviation, min, max)
        anchors = start.generate_bezier_anchors(finish, spread)
        
        control_point_vectors = [start] + anchors + [finish]
        control_points = control_point_vectors.map(&:to_a)
        BezierCurve.new(*control_points)
      end

      def bezier_curve_through_points(finish, intermediate_points = [])
        min = 10
        max = 90

        start = self
        deviation = start.direction(finish).magnitude * 0.2
        spread = confine(deviation, min, max)
        anchors = start.generate_bezier_anchors(finish, spread)
        
        control_point_vectors = [start] + anchors + [finish]
        control_points = control_point_vectors.map(&:to_a)
        BezierCurve.new(*control_points)
      end
    end

    class BrowserMouseMover
      include MathUtils

      # browser must have the following methods:
      #   #move(x, y) - moves the mouse cursor to the given (x, y) coordinates
      #   #
      attr_accessor :browser
      attr_reader :current_coords

      def initialize(browser, initial_x = 0, initial_y = 0)
        @browser = browser
        set_coords(initial_x, initial_y)
      end
      
      def set_coords(x, y)
        browser.move(x, y)
        @current_coords = [x, y]
      end

      def move(x2, y2, overshoot = true)
        x1, y1 = *current_coords
        if overshoot
          start = Vector.new(x1, y1)
          finish = Vector.new(x2, y2)
          overshoot_radius = [start.direction(finish).magnitude * 0.33, 100].min.to_i
          overshoot_x, overshoot_y = *finish.overshoot(overshoot_radius).to_a
          move_over_path(x1, y1, overshoot_x, overshoot_y)
          move_over_path(overshoot_x, overshoot_y, x2, y2)
        else
          move_over_path(x1, y1, x2, y2)
        end

        # move_over_path(x1, y1, x2, y2, overshoot)
      end

      def move_over_path(x1, y1, x2, y2, overshoot = false)
        # if overshoot
        #   start = Vector.new(x1, y1)
        #   finish = Vector.new(x2, y2)
        #   overshoot_radius = [start.direction(finish).magnitude * 0.20, 100].min.to_i
        #   overshoot_x, overshoot_y = *finish.overshoot(overshoot_radius).to_a
        #   move_over_path(x1, y1, overshoot_x, overshoot_y)
        #   move_over_path(overshoot_x, overshoot_y, x2, y2)
        # else
          path(x1, y1, x2, y2).each do |coords|
            x, y = *coords
            set_coords(x, y)
          end
        # end
      end

      # reimplements https://github.com/Xetera/ghost-cursor/blob/master/src/spoof.ts#L92
      def path(x1, y1, x2, y2, fitts = true)
        start = Vector.new(x1, y1)
        finish = Vector.new(x2, y2)

        if fitts
          default_width = 100
          min_steps = 25
          width = default_width
          curve = start.bezier_curve(finish)
          # length = curve.length() * 0.8
          length = start.direction(finish).magnitude * 0.8
          base_time = rand * min_steps
          steps = ((Math.log2(fitts(length, width) + 1) + base_time) * 3).ceil
          coordinate_points = curve.points(count: steps)
          coordinate_points.map {|coord| coordinate_floor0(coord) }
        else
          curve = start.bezier_curve(finish)
          curve.points
        end
      end
    end
  end
end