module ActiveFedora
  module WithMetadata
    class MetadataNode < ActiveTriples::Resource
      include ActiveModel::Dirty
      attr_reader :file

      def initialize(file)
        @file = file
        super(file.uri, ldp_source.graph)
        return unless self.class.type && !type.include?(self.class.type)
        # Workaround for https://github.com/ActiveTriples/ActiveTriples/issues/123
        get_values(:type) << self.class.type
      end

      attr_writer :metadata_uri

      def metadata_uri
        @metadata_uri ||= if file.new_record?
                            ::RDF::URI.new nil
                          else
                            raise "#{file} must respond_to described_by" unless file.respond_to? :described_by
                            file.described_by
                          end
      end

      def set_value(*args)
        super
        attribute_will_change! args.first
      end

      def ldp_source
        @ldp_source ||= LdpResource.new(ldp_connection, metadata_uri)
      end

      def ldp_connection
        ActiveFedora.fedora.connection
      end

      def save
        raise "Save the file first" if file.new_record?
        SparqlInsert.new(changes_for_update, ::RDF::URI.new(file.uri)).execute(metadata_uri)
        @ldp_source = nil
        true
      end

      def changed_attributes
        super.tap do |changed|
          changed['type'] = true if type.present?
        end
      end

      private

        def changes_for_update
          ChangeSet.new(self, self, changed_attributes.keys).changes
        end

        class << self
          attr_writer :parent_class

          attr_reader :parent_class

          def property(name, options)
            parent_class.delegate name, :"#{name}=", :"#{name}_changed?", to: :metadata_node
            super
          end

          def create_delegating_setter(name)
            file.class.delegate(name, to: :metadata_node)
          end

          def exec_block(&block)
            class_eval(&block)
          end
        end
    end
  end
end
