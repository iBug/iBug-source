module Jekyll
  module Algolia
    module Hooks
      def self.before_indexing_each(record, node, context)
        record.delete :git
        record.delete :raw_content
        record
      end
    end
  end
end
