# frozen_string_literal: true

# https://github.com/jekyll/jekyll/pull/7967

module Jekyll
  class LiquidRenderer
    class File
      def render(*args)
        reset_template_assigns

        measure_time do
          measure_bytes do
            measure_counts do
              @template.render(*args)
            end
          end
        end
      end

      # This method simply 'rethrows any error' before attempting to render the template.
      def render!(*args)
        reset_template_assigns

        measure_time do
          measure_bytes do
            measure_counts do
              @template.render!(*args)
            end
          end
        end
      end

      # clear assigns to `Liquid::Template` instance prior to rendering since
      # `Liquid::Template` instances are cached in Jekyll 4.
      def reset_template_assigns
        @template.instance_assigns.clear
      end
    end
  end
end
