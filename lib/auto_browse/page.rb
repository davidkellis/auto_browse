require "fileutils"
require "mini_magick"

require_relative "ferrum_ext"

module AutoBrowse

  module Pagelike
    def page
      browser.driver
    end

    def scroll_to(*args, **options)
      page.scroll_to(*args, **options)
    end

    def mouse
      browser.mouse
    end

    def move(x, y)
      browser.move(x, y)
    end

    def goto(product_url)
      page.visit(product_url)
    end

    # returns [top, left, bottom, right] of element
    def bounding_box(element)
      top = element.evaluate_script("this.getBoundingClientRect().top;").to_i
      left = element.evaluate_script("this.getBoundingClientRect().left;").to_i
      bottom = element.evaluate_script("this.getBoundingClientRect().bottom;").to_i
      right = element.evaluate_script("this.getBoundingClientRect().right;").to_i
      [top, left, bottom, right]
    end

    # returns [x, y] of element
    def coords(element)
      top, left, bottom, right = *bounding_box(element)
      [left, top]
    end

    # returns [width, height] of element
    def dimensions(element)
      top, left, bottom, right = *bounding_box(element)
      height = bottom - top
      width = right - left
      [width, height]
    end

    # returns [x, y, width, height] of element
    def coords_dimensions(element)
      top, left, bottom, right = *bounding_box(element)
      height = bottom - top
      width = right - left
      [left, top, width, height]
    end

    # this method will only work if the browser window has focus; otherwise, this method will raise a timeout exception
    def viewport_screenshot(path)
      page.save_screenshot(path, full: false)   # this delegates to https://github.com/rubycdp/ferrum/blob/3a2dc276ba312831487b05cb6e176cae5a7375a4/lib/ferrum/page/screenshot.rb#L31
    end

    # this method will only work if the browser window has focus; otherwise, this method will raise a timeout exception
    def full_page_screenshot(path)
      page.save_screenshot(path, full: true)   # this delegates to https://github.com/rubycdp/ferrum/blob/3a2dc276ba312831487b05cb6e176cae5a7375a4/lib/ferrum/page/screenshot.rb#L31
    end

    # containing_frame_offset_coords is an array of the form: [ [outer_frame.x, outer_frame.y], [inner_frame.x, inner.frame.y] ]
    #   that lists the [top, left] cords of all (if any) frames that contain the given element
    def element_screenshot(element, output_file_path, containing_frame_offset_coords = [])
      raise "A temporary screenshot must be taken before trying to capture an element screenshot." unless @last_screenshot

      x, y, width, height = *coords_dimensions(element)

      frame_offset_x, frame_offset_y = *containing_frame_offset_coords.reduce([0, 0]) {|memo, coord_pair| [ memo[0] + coord_pair[0], memo[1] + coord_pair[1] ] }
      page_x = frame_offset_x + x
      page_y = frame_offset_y + y

      # this imagemagick command performs the crop on the full screenshot
      # convert images/captcha/20210128_161014/tiles.png -crop 95x95+123+154 +repage images/captcha/20210128_161014/tile0.png
      image = MiniMagick::Image.open(@last_screenshot_path)
      image.combine_options do |cmd|
        cmd.crop "#{width}x#{height}+#{page_x}+#{page_y}"
        cmd.repage.+
      end

      FileUtils.mkdir_p(File.dirname(output_file_path))
      image.write(output_file_path)
    end

    # example:
    # with_temp_screenshot do |tmp_path|
    #   puts "temp screenshot is at #{tmp_path}"
    # end
    def with_temp_screenshot(temp_screenshot_path = "./tmp_screenshot.png", &blk)
      temp_screenshot(temp_screenshot_path)
      blk.call(@last_screenshot_path)
      delete_temp_screenshot
    end

    def temp_screenshot(path = "./tmp_screenshot.png")
      delete_temp_screenshot if @last_screenshot

      @last_screenshot_path = path
      @last_screenshot = viewport_screenshot(@last_screenshot_path)
    end

    def delete_temp_screenshot
      if @last_screenshot && @last_screenshot_path && File.exist?(@last_screenshot_path)
        File.delete(@last_screenshot_path)

        @last_screenshot_path = nil
        @last_screenshot = nil
      end
    end
  end


  class Page
    include Pagelike

    attr_accessor :browser

    def initialize(browser)
      @browser = browser
    end
  end

end
