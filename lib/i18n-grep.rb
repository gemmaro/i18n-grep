require "yaml"

module I18n
  class << self
    def grep(pattern, files)
      results = []

      files.each do |filepath|
        document = YAML.parse_file(filepath)
        messages = Set.new
        extract_messages_recursively(document, namespace: [], messages:)
        messages.each do |message|
          results << [filepath,
                      message[:line_number],
                      message[:namespace].join('.'),
                      message[:message]]
        end
      end

      results
    end

    module YAMLPatternMatch
      refine YAML::Nodes::Document do
        def deconstruct_keys(*_keys)
          { children: }
        end
      end

      refine YAML::Nodes::Mapping do
        def deconstruct_keys(*_keys)
          { children: }
        end
      end

      refine YAML::Nodes::Scalar do
        def deconstruct_keys(*_keys)
          { value: }
        end
      end
    end

    using YAMLPatternMatch

    def extract_messages_recursively(node, namespace:, messages:)
      case node
      in YAML::Nodes::Document[children:]
        children.each do |child|
          extract_messages_recursively(child, namespace:, messages:)
        end
      in YAML::Nodes::Mapping[children:]
        children.each_slice(2) do |key, value|
          key => YAML::Nodes::Scalar[value: String => key]
          extract_messages_recursively(value, namespace: [*namespace, key], messages:)
        end
      in YAML::Nodes::Scalar[value: String => message]
        messages << { namespace:, message:, line_number: node.start_line }
      end
    end
  end
end
