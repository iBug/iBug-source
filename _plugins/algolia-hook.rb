module Jekyll
  module Algolia
    module Hooks
      def self.before_indexing_each(record, node, context)
        return nil if node.matches? 'git'
        record
      end
    end
  end
end
