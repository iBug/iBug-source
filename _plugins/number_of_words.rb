CJK_REGEX = /\p{Han}|\p{Katakana}|\p{Hiragana}|\p{Hangul}/
module Jekyll
  module Filters
    def number_of_words input
      input.scan(CJK_REGEX).length + input.gsub(CJK_REGEX, ' ').split.length
    end
  end
end
