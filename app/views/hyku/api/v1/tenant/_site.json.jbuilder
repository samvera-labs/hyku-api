# frozen_string_literal: true
json.cache! [:tenants, account, site] do
  json.site do
    json.id site.id
    json.account_id site.account_id
    json.application_name site.application_name
    json.institution_name site.institution_name
    json.institution_name_full site.institution_name_full
    json.created_at site.created_at
    json.updated_at site.updated_at
    json.banner_image site.banner_image.filename
    json.banner_images do
      # I think this might be wrong and need to be fixed
      json.url url_for("#{account.cname}#{site.banner_image}")
    end
  end
end
