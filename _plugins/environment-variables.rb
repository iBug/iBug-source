module Jekyll
  class EnvironmentVariablesGenerator < Generator
    def generate(site)
      # assigning to ENV will not work in liquid templates
      # must iterate through the keys & values and build a new map
      site.config['env'] = {}
      ENV.each do |key, value|
        site.config['env'][key] = value
      end
    end
  end
end
