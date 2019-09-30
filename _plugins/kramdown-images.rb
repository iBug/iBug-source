require 'kramdown/converter/html'

module StandaloneImages
  def convert_p(el, indent)
    return super unless el.children.size == 1 && (el.children.first.type == :img || (el.children.first.type == :html_element && el.children.first.value == "img"))
    if el.children.first.attr["class"].nil?
      el.children.first.attr["class"] = "block"
    else
      el.children.first.attr["class"] += " block"
    end
    #convert(el, indent)
    super
  end
end

Kramdown::Converter::Html.prepend StandaloneImages
