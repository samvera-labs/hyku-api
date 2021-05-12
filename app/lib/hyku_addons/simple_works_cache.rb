module HykuAddons
  class SimpleWorksCache

    CACHE_EXPIRATION_IN_SECONDS = ENV['CACHE_EXPIRATION_IN_SECONDS'].presence || 60

    def initialize(tenant_id)
      unless tenant_id.present?
        raise ArgumentError, 'You must provide a tenant id'
      end

      @tenant_id = tenant_id
    end

    #
    def fetch(options = {})
      options[:ex] ||= CACHE_EXPIRATION_IN_SECONDS
      raise ArgumentError, 'You must provide a Proc to load the doc in case the cache misses' unless block_given?

      cache_key_name = cache_key_name_from_options(options)
      Rails.logger.info "[SimpleWorksCache] Loading cache for #{cache_key_name}"
      cache_hit = Redis.current.get(cache_key_name)&.force_encoding(Encoding::BINARY)
      if (marshalled_doc = cache_hit.presence)
        Rails.logger.info "[SimpleWorksCache] CACHE HIT -> #{cache_key_name}"
        Marshal.load(marshalled_doc)
      else
        Rails.logger.info "[SimpleWorksCache] NO CACHE -> #{cache_key_name}"
        new_value = yield
        Redis.current.set(cache_key_name, Marshal.dump(new_value), ex: options[:ex]) if all_public_docs?(new_value)
        new_value
      end
    end

    protected

      def cache_key_name_from_options(opts = {})
        ordered_params = opts[:work] || opts[:query]&.sort_by { |k, v| k }
        "#{@tenant_id}-#{ordered_params}"
      end

      def all_public_docs?(docs)
        if docs.is_a?(Array) && docs.first&.is_a?(Blacklight::Solr::Response)
          all_public_docs?(docs.last)
        else
          Array.wrap(docs).all? { |doc| doc.visibility == 'open' }
        end
      end
  end
end
