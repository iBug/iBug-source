module Jekyll
  module AddNonBreakingSpacesFilter
    def add_nbsp(text)
      text = text.gsub(/(\b\d+) ([KkMGTP]+i?[Bb]\b|byte)/, '\1&nbsp;\2')
      text
    end
  end
end

Liquid::Template::register_filter(Jekyll::AddNonBreakingSpacesFilter)
