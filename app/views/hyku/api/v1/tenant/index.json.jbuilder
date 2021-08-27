# frozen_string_literal: true
# Note that @accounts is really unnecessary because there will only ever be one
# and @site and @content_blocks are not multivalued but only for the one account in @account
json.cache_root! [:tenants, :index, @account, @content_blocks&.count, @content_blocks&.map(&:updated_at)&.max] do
  json.array!(@accounts) do |_account|
    json.partial! 'tenant', account: @account, site: @site, content_blocks: @content_blocks
  end
end
