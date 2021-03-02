#!/usr/bin/env ruby

require 'base64'
require 'mimemagic'
require 'sass'

module Sass::Script::Functions
  def urlb64(url)
    assert_type url, :String

    root = File.expand_path('..',  __FILE__)
    path = url.delete_prefix('url(').delete_suffix(')')
    ext = File.extname(path)

    if path.include? '://'
      URI.open(path) { |f| data = f.read }
    else
      fullpath = File.expand_path(path, root)
      data = File.read(fullpath, 'rb')
    end
    data_b64 = Base64.encode64(data).gsub(/\s+/m, '')
    mime = MimeMagic.by_extension ext
    contents = "url(data:#{mime};base64,#{data_b64})"

    Sass::Script::String.new(contents)
  end

  declare :urlb64, :args => [:string]
end

def main
end

if $PROGRAM_NAME == __FILE__
  main
end
