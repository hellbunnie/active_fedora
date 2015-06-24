module ActiveFedora
  module Identifiable
    extend ActiveSupport::Concern

    included do
      ##
      # :singleton-method
      #
      # Accepts a proc that takes an id and transforms it to a URI
      mattr_reader :translate_id_to_uri

      # This method is mixed into ActiveFedora::Base and ActiveFedora::File, so don't
      # overwrite the value if it's already set.
      @@translate_id_to_uri ||= Core::FedoraIdTranslator

      def self.translate_id_to_uri=(translator)
        @@translate_id_to_uri = translator || Core::FedoraIdTranslator
      end

      ##
      # :singleton-method
      #
      # Accepts a proc that takes a uri and transforms it to an id
      mattr_reader :translate_uri_to_id

      # This method is mixed into ActiveFedora::Base and ActiveFedora::File, so don't
      # overwrite the value if it's already set.
      @@translate_uri_to_id ||= Core::FedoraUriTranslator

      def self.translate_uri_to_id=(translator)
        @@translate_uri_to_id = translator || Core::FedoraUriTranslator
      end
    end


    module ClassMethods
      ##
      # Transforms an id into a uri
      # if translate_id_to_uri is set it uses that proc, otherwise just the default
      def id_to_uri(id)
        translate_id_to_uri.call(id)
      end

      ##
      # Transforms a uri into an id
      # if translate_uri_to_id is set it uses that proc, otherwise just the default
      def uri_to_id(uri)
        translate_uri_to_id.call(uri)
      end

      ##
      # Provides the common interface for ActiveTriples::Identifiable
      def from_uri(uri,_)
        begin
          self.find(uri_to_id(uri))
        rescue ActiveFedora::ObjectNotFoundError, Ldp::Gone
          ActiveTriples::Resource.new(uri)
        end
      end
    end
  end
end