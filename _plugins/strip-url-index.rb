module Jekyll
  class Page
    def url
      @url ||= URL.new(
        :template     => template,
        :placeholders => url_placeholders,
        :permalink    => permalink
      ).to_s.chomp('index.html')
    end
  end
end
