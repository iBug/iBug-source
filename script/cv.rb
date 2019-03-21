#!/usr/bin/ruby

require 'yaml'
require 'time'

front_matter = {
  'title' => 'Curriculum Vitae',
  'description' => "iBug's Timeline",
  'layout' => "cv",
}

data = YAML.load_file 'cv.yml'

body = data['events'].sort.reverse.map do |date, text|
  "<dt>#{date.strftime "%b %e, %Y"}</dt>\n<dd>\n#{text.strip}\n</dd>\n"
end

links = data['links'].sort.map do |k, v|
  "  [#{k}]: #{v}"
end

File.open "cv.md", "w" do |f|
  f.write "#{front_matter.to_yaml}---\n\n<dl>\n#{body.join "\n"}</dl>\n\n#{links.join "\n"}\n"
end
