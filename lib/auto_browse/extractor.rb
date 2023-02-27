require "nokogiri"

class NokogiriExtractor
  def self.from_file(path)
    new(path: path)
  end

  def initialize(html: nil, path: nil)
    @html = html
    @path = path
  end

  def content
    case
    when @html
      @html
    when @path
      File.read(@path)
    end
  end

  def nokogiri
    @nokogiri ||= Nokogiri::HTML(content)
  end


  # extractor logic

  def text_at(css_path, parent_node = nokogiri, blank_as_nil: true)
    text = parent_node.at_css(css_path)&.text&.strip
    text unless text.blank? && blank_as_nil
  end

  def html2text_at(css_path, parent_node = nokogiri, blank_as_nil: true)
    node = parent_node.at_css(css_path)
    html2text(node, blank_as_nil: blank_as_nil)
  end

  def html2text(node_or_html, blank_as_nil: true)
    html = node_or_html.is_a?(String) ? node_or_html : node_or_html&.inner_html
    text = Html2Text.convert(html).strip if html
    text unless text.blank? && blank_as_nil
  end

  def htmltable2text_at(css_path, parent_node = nokogiri, blank_as_nil: true)
    table = css_path == :self ? parent_node : parent_node.at_css(css_path)
    rows = table.xpath("./thead/tr | ./tbody/tr | ./tr")
    rows.map do |row|
      cells = row.xpath("./th | ./td")
      cells.map {|cell| html2text(cell.inner_html, blank_as_nil: blank_as_nil) }
    end
  end
end
