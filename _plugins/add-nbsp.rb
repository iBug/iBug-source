def add_nbsp(page)
  page.content = page.content.gsub(/(\b\d+) ([KkMGTP]+i?[Bb]\b|byte)/, '\1&nbsp;\2')
end

Jekyll::Hooks.register :pages, :post_convert do |page|
  add_nbsp(page)
end

Jekyll::Hooks.register :posts, :post_convert do |page|
  add_nbsp(page)
end
