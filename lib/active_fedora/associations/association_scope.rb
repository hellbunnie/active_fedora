module ActiveFedora
  module Associations
    class AssociationScope #:nodoc:

      attr_reader :association

      delegate :klass, :owner, :reflection, :interpolate, :to => :association
      delegate :chain, :scope_chain, :options, :source_options, :active_record, :to => :reflection

      def initialize(association)
        @association = association
      end

      def scope
        scope = klass.unscoped
        add_constraints(scope)
      end

      private

      def add_constraints(scope)
        chain.each_with_index do |reflection, i|
          if reflection.source_macro == :belongs_to
            # Create a partial solr query using the ids. We may add additional filters such as class_name later
            scope = scope.where( ActiveFedora::SolrService.construct_query_for_ids([owner[reflection.foreign_key]]))
          elsif reflection.source_macro == :has_and_belongs_to_many
          else
            scope = scope.where( ActiveFedora::SolrService.construct_query_for_rel(association.send(:find_reflection) => owner.id))
          end

          is_first_chain = i == 0
          klass = is_first_chain ? self.klass : reflection.klass
        end

        scope
      end
    end
  end
end
