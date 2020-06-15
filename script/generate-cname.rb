require 'yaml'

yaml_file = ARGV[0] || '_config.yml'
output_dir = ARGV[1] || '_site'

config = YAML.load_file yaml_file
File.open "#{output_dir}/CNAME", 'w' do |f|
  f.write URI(config['url']).hostname
end
