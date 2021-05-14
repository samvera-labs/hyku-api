# frozen_string_literal: true
json.cache_root! [:tenants, @account, @content_blocks.count, @content_blocks.max(&:updated_at)] do
  json.partial! 'tenant', account: @account, site: @site, content_blocks: @content_blocks
end
