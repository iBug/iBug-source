source "https://rubygems.org"

gem "jekyll", '~> 4.1.0'
gem "minimal-mistakes-jekyll", '>= 4.19.2'
gem "liquid-c", '~> 4.0'

# Required for LSI, too slow however
if ENV['LSI'] == 'true'
  gem "classifier-reborn"
  gem "gsl"
end

group :jekyll_plugins do
  # Class 1: Default plugins on GitHub Pages
  #gem "jekyll-gist"
  gem "jekyll-sitemap"
  #gem "jekyll-paginate"
  gem "jekyll-feed"
  #gem "jemoji"
  gem "jekyll-relative-links"
  gem "jekyll-optional-front-matter"
  #gem "jekyll-readme-index"
  #gem "jekyll-default-layout"
  #gem "jekyll-titles-from-headings"
  gem "jekyll-github-metadata" if ENV['CI'] == 'true'

  # Class 2: Optional plugins on GitHub Pages
  gem "jekyll-redirect-from"
  gem "jekyll-mentions"
  gem "jekyll-seo-tag"
  #gem "jekyll-coffeescript"
  gem "jekyll-include-cache"

  # Class 3: Extras
  gem "jekyll-environment-variables"
  gem "jekyll-tidy"
  gem "jekyll-last-modified"
  gem "jekyll-assets"
  gem "jekyll-algolia"
  gem "jekyll-archives", '>= 2.2.1'
  gem "jekyll-paginate-v2", '>= 3.0.0'
end
