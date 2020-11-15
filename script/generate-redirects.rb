#!/usr/bin/ruby

require 'json'
require 'uri'
require 'yaml'

yaml_file = ARGV[0] || '_config.yml'
config = YAML.load_file yaml_file
site_url = config['url'] || ''
site_dir = ARGV[1] || config['destination'] || '_site'

redirects = nil
File.open "#{site_dir}/redirects.json", 'r' do |f|
  redirects = JSON.load f
end

File.open "#{site_dir}/_redirects", 'a' do |f|
  url_re = Regexp.new "^#{Regexp.escape site_url}"
  redirects.sort_by { |k, v| k }.each do |from, to|
    f.write "#{from} #{to.gsub url_re, ""} 302!\n"
  end
end
