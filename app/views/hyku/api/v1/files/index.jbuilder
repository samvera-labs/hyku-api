# frozen_string_literal: true
json.array! @files.each do |file|
  json.uuid file.id
  json.type    'file_set'
  json.name    file.title.try(:first)
  json.description file.description.try(:first)
  json.mimetype   file.mime_type

  license_array = file.solr_document.license
  license_hash = Hyrax::LicenseService.new.select_all_options.to_h
  if license_array.present?
    json.license do
      json.array! license_array do |item|
        if license_hash.values.include?(item)
          json.name  license_hash.key(item)
          json.link  item
        end
      end
    end
  else
    json.license nil
  end

  json.thumbnail_url  'https://' + @account.cname + file.solr_document.thumbnail_path
  json.date_uploaded  file.date_uploaded
  json.current_visibility file.solr_document.visibility
  json.embargo_release_date file.embargo_release_date
  json.lease_expiration_date file.lease_expiration_date
  json.size file.file_size
  json.download_link 'https://' + @account.cname + hyrax.download_path(id: file.id)
end
