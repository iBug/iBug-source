module HtmlBeautifier
  def self.beautify(html, options = {})
    options[:indent] = "\t"
    "".tap { |output|
      HtmlParser.new.scan html.to_s, Builder.new(output, options)
    }
  end
end
