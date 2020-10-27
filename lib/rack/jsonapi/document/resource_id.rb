# frozen_string_literal: true

module JSONAPI
  class Document
    # A jsonapi resource identifier
    class ResourceId

      attr_accessor :type, :id

      def initialize(type, id)
        @type = type
        @id = id
      end
    end
  end
end