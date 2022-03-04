# Hyku::API

HykuAPI is an open source Ubiquity Press product which creates a number of useful endpoints to return JSON as a response.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hyku-api'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install hyku-api
```

# HykuAddons 

This Gem was primarily designed to work within [HykuAddons](https://github.com/ubiquitypress/hyku_addons), however it could be used with any Hyku installation. 

The following usage guide assumes you are using HykuAddons and is tailored to new developers getting started within the Samvera ecosystem.

## Usage

If you are using this Gem within HykuAddons development environment, you will need to add `frontend` to your tenant URL: 

```
# If your cname/URL is as follows
http://repo.hyku.docker:3000

# The URL to access the frontend API will be
http://repofrontend.hyku.docker:3000
```

### Routes

All of the endpoints are prefixed with `/api/v1` for the first version of the Gem, then require a `tenant` param be passed in order to differentiate between accounts - this Gem is targetted at Hyku so is multitenancy by default.

To get your tenant UUID, log into the console and query `Account.first.tenant`, or which ever account you wish to access. You can then create your primary URL: 

```ruby
2.7.4 :004 > Account.first.tenant
 => "0b199b49-8f52-4725-b9c0-3c4c78f2c58c"
```

#### Tenant

`/api/v1/tenant/0b199b49-8f52-4725-b9c0-3c4c78f2c58c`

```json
{
   "id":1,
   "tenant":"0b199b49-8f52-4725-b9c0-3c4c78f2c58c",
   "cname":"repo.hyku.docker",
   "name":"repo",
   "solr_endpoint":1,
   "fcrepo_endpoint":2,
   "redis_endpoint":3,
   "settings":{
      "locale_name":"anschutz",
      "allow_signup":"true",
      "email_format":[
         
      ],
      "file_size_limit":"",
      "hyrax_orcid_settings":{
         "client_id":"",
         "environment":"sandbox",
         "auth_redirect":"",
         "client_secret":""
      }
   },
   "site":{
      "id":1,
      "account_id":1,
      "application_name":null,
      "institution_name":null,
      "institution_name_full":null,
      "created_at":"2022-02-02T16:47:12.173Z",
      "updated_at":"2022-02-02T16:47:12.183Z",
      "banner_image":null,
      "banner_images":{
         "url":"repo.hyku.docker"
      }
   },
   "content_block":[
      {
         "id":1,
         "name":"featured_researcher",
         "value":null,
         "created_at":"2022-02-08T09:52:49.936Z",
         "updated_at":"2022-02-08T09:52:49.936Z",
         "external_key":null,
         "site_id":null
      }
   ]
}
```

#### Works 

`/api/v1/tenant/7143fb2e-8e25-4763-9df4-1eadf8a97408/work/`

The response from this endpoint will depend on the fields specified for the work types return, however a simple example might be: 

```json
{
   "total":1,
   "items":[
      {
         "uuid":"5ffa54bc-20d6-4bd8-9e15-cbc326bdf787",
         "abstract":"sdf",
         "adapted_from":null,
         "additional_info":null,
         "additional_links":null,
         "admin_set_name":"Default Admin Set",
         "advisor":null,
         "alternate_identifier":null,
         "alternative_journal_title":null,
         "alternative_book_title":null,
         "alternative_title":[
            "alt title"
         ],
         "article_number":null,
         "audience":null,
         "book_title":null,
         "buy_book":null,
         "challenged":null,
         "citation":null,
         "cname":"repo.hyku.docker",
         "committee_member":null,
         "creator":[
            {
               "creator_organization_name":"",
               "creator_given_name":"Jessica",
               "creator_middle_name":"middle",
               "creator_family_name":"Demes",
               "creator_name_type":"Personal",
               "creator_orcid":"asdsd",
               "creator_ror":"",
               "creator_grid":"",
               "creator_wikidata":"",
               "creator_suffix":"Mx",
               "creator_institutional_email":"ssdf@test.com",
               "creator_profile_visibility":"closed",
               "creator_institution":[
                  "Inst."
               ],
               "creator_role":[
                  "Actor"
               ]
            }
         ],
         "contributor":[],
         "date_accepted":null,
         "date_published":[
            "2028-1-1"
         ],
         "date_published_text":null,
         "date_submitted":"03/02/2022",
         "degree":null,
         "dewey":null,
         "doi":"https://doi.org/10.25677/wnjc-9s14",
         "duration":null,
         "edition":null,
         "eissn":null,
         "event_date":null,
         "event_location":null,
         "extent":null,
         "event_title":null,
         "files":{
            "has_private_files":false,
            "has_registered_files":false,
            "has_public_files":false
         },
         "funder":[],
         "funder_project_ref":null,
         "funding_description":null,
         "georeferenced":null,
         "institution":null,
         "irb_number":null,
         "irb_status":null,
         "is_included_in":null,
         "isbn":null,
         "issn":null,
         "issue":null,
         "is_format_of":null,
         "part_of":null,
         "journal_title":null,
         "journal_frequency":null,
         "keywords":[],
         "language":[
            "English"
         ],
         "library_of_congress_classification":null,
         "license":[
            {
               "name":"CC BY 4.0 Attribution",
               "link":"https://creativecommons.org/licenses/by/4.0/"
            }
         ],
         "location":null,
         "latitude":null,
         "longitude":null,
         "medium":null,
         "mentor":null,
         "mesh":[
            "Mesh"
         ],
         "official_url":null,
         "official_link":null,
         "org_unit":null,
         "outcome":null,
         "page_display_order_number":null,
         "pagination":null,
         "participant":null,
         "photo_caption":null,
         "photo_description":null,
         "place_of_publication":[
            "England"
         ],
         "prerequisites":null,
         "project_name":null,
         "publisher":[],
         "qualification_grantor":null,
         "qualification_level":null,
         "qualification_subject_text":null,
         "reading_level":null,
         "references":null,
         "refereed":null,
         "related_exhibition":null,
         "related_exhibition_date":null,
         "related_exhibition_venue":null,
         "related_material":null,
         "related_url":null,
         "repository_space":"University of Colorado Anschutz Medical Campus Strauss Health Sciences Library",
         "time":null,
         "resource_type":[
            "Collection"
         ],
         "rights_holder":null,
         "rights_statement":[
            "http://rightsstatements.org/vocab/CNE/1.0/"
         ],
         "rights_statement_text":null,
         "series_name":null,
         "source":[],
         "subject":null,
         "subject_text":[
            "Subject"
         ],
         "suggested_reviewers":null,
         "suggested_student_reviewers":null,
         "thumbnail_url":null,
         "table_of_contents":null,
         "title":"anschutz_works - works",
         "type":"work",
         "version":null,
         "visibility":"open",
         "volume":null,
         "work_type":"AnschutzWork",
         "workflow_status":null,
         "collections":[]
      }
   ]
}
```

#### Work

Using the work UUID from the previous query, you can then get data for an individual work. 

`/api/v1/tenant/0b199b49-8f52-4725-b9c0-3c4c78f2c58c/work/5ffa54bc-20d6-4bd8-9e15-cbc326bdf787`

An individual work might look as follows: 

```json
{
   "uuid":"5ffa54bc-20d6-4bd8-9e15-cbc326bdf787",
   "abstract":"sdf",
   "adapted_from":null,
   "additional_info":null,
   "additional_links":null,
   "admin_set_name":"Default Admin Set",
   "advisor":null,
   "alternate_identifier":null,
   "alternative_journal_title":null,
   "alternative_book_title":null,
   "alternative_title":[
      "alt title"
   ],
   "article_number":null,
   "audience":null,
   "book_title":null,
   "buy_book":null,
   "challenged":null,
   "citation":null,
   "cname":"repo.hyku.docker",
   "committee_member":null,
   "creator":[
      {
         "creator_name_type":"Personal",
         "creator_family_name":"Demes",
         "creator_given_name":"Jessica",
         "creator_middle_name":"middle",
         "creator_suffix":"Mx",
         "creator_role":[
            "Actor"
         ],
         "creator_institution":[
            "Inst."
         ],
         "creator_orcid":"asdsd",
         "creator_institutional_email":"ssdf@test.com",
         "creator_profile_visibility":"closed"
      }
   ],
   "contributor":[],
   "date_accepted":null,
   "date_published":[
      "2028-1-1"
   ],
   "date_published_text":null,
   "date_submitted":"03/02/2022",
   "degree":null,
   "dewey":null,
   "doi":"https://doi.org/10.25677/wnjc-9s14",
   "duration":null,
   "edition":null,
   "eissn":null,
   "event_date":null,
   "event_location":null,
   "extent":null,
   "event_title":null,
   "files":{
      "has_private_files":false,
      "has_registered_files":false,
      "has_public_files":true
   },
   "funder":[],
   "funder_project_ref":null,
   "funding_description":null,
   "georeferenced":null,
   "institution":null,
   "irb_number":null,
   "irb_status":null,
   "is_included_in":null,
   "isbn":null,
   "issn":null,
   "issue":null,
   "is_format_of":null,
   "part_of":null,
   "journal_title":null,
   "journal_frequency":null,
   "keywords":[
      
   ],
   "language":[
      "English"
   ],
   "library_of_congress_classification":null,
   "license":[
      {
         "name":"CC BY 4.0 Attribution",
         "link":"https://creativecommons.org/licenses/by/4.0/"
      }
   ],
   "location":null,
   "latitude":null,
   "longitude":null,
   "medium":null,
   "mentor":null,
   "mesh":[
      "Mesh"
   ],
   "official_url":null,
   "official_link":null,
   "org_unit":null,
   "outcome":null,
   "page_display_order_number":null,
   "pagination":null,
   "participant":null,
   "photo_caption":null,
   "photo_description":null,
   "place_of_publication":[
      "England"
   ],
   "prerequisites":null,
   "project_name":null,
   "publisher":[
      
   ],
   "qualification_grantor":null,
   "qualification_level":null,
   "qualification_subject_text":null,
   "reading_level":null,
   "references":null,
   "refereed":null,
   "related_exhibition":null,
   "related_exhibition_date":null,
   "related_exhibition_venue":null,
   "related_material":null,
   "related_url":null,
   "repository_space":"University of Colorado Anschutz Medical Campus Strauss Health Sciences Library",
   "time":null,
   "resource_type":[
      "Collection"
   ],
   "rights_holder":null,
   "rights_statement":[
      "http://rightsstatements.org/vocab/CNE/1.0/"
   ],
   "rights_statement_text":null,
   "series_name":null,
   "source":[
      
   ],
   "subject":null,
   "subject_text":[
      "Subject"
   ],
   "suggested_reviewers":null,
   "suggested_student_reviewers":null,
   "thumbnail_url":"http://repo.hyku.docker/assets/work-ff055336041c3f7d310ad69109eda4a887b16ec501f35afc0a547c4adb97ee72.png",
   "table_of_contents":null,
   "title":"anschutz_works - works",
   "type":"work",
   "version":null,
   "visibility":"open",
   "volume":null,
   "work_type":"AnschutzWork",
   "workflow_status":null,
   "collections":[
      
   ]
}
```

#### Manifest

http://repofrontend.hyku.docker:3000/api/v1/tenant/0b199b49-8f52-4725-b9c0-3c4c78f2c58c/work/5ffa54bc-20d6-4bd8-9e15-cbc326bdf787/manifest

```json
{
   "@context":"http://iiif.io/api/presentation/2/context.json",
   "@type":"sc:Manifest",
   "@id":"http://repofrontend.hyku.docker/concern/anschutz_works/5ffa54bc-20d6-4bd8-9e15-cbc326bdf787/manifest",
   "label":"anschutz_works - works"
}
```

#### Files

`/api/v1/tenant/0b199b49-8f52-4725-b9c0-3c4c78f2c58c/work/5ffa54bc-20d6-4bd8-9e15-cbc326bdf787/files`

```json
[
   {
      "uuid":"d19f80a6-fabc-42ae-8d4d-0fe110ad7979",
      "type":"file_set",
      "name":"_mz_9024-cropped-500x500.jpg",
      "description":null,
      "mimetype":"image/jpeg",
      "license":[],
      "thumbnail_url":"https://repo.hyku.docker/assets/default-f936e9c3ea7a38e2c2092099586a71380b11258697b37fb4df376704495a849a.png",
      "date_uploaded":"2022-03-04",
      "current_visibility":"open",
      "embargo_release_date":null,
      "lease_expiration_date":null,
      "size":null,
      "download_link":"https://repo.hyku.docker/downloads/d19f80a6-fabc-42ae-8d4d-0fe110ad7979"
   }
]
```

#### Search

`/api/v1/tenant/0b199b49-8f52-4725-b9c0-3c4c78f2c58c/search?search=test`

```json
{
   "total":1,
   "items":[
      {
         "uuid":"5ffa54bc-20d6-4bd8-9e15-cbc326bdf787",
         "abstract":"sdf",
         "adapted_from":null,
         "additional_info":null,
         "additional_links":null,
         "admin_set_name":"Default Admin Set",
         "advisor":null,
         "alternate_identifier":null,
         "alternative_journal_title":null,
         "alternative_book_title":null,
         "alternative_title":[
            "alt title"
         ],
         "article_number":null,
         "audience":null,
         "book_title":null,
         "buy_book":null,
         "challenged":null,
         "citation":null,
         "cname":"repo.hyku.docker",
         "committee_member":null,
         "creator":[
            {
               "creator_name_type":"Personal",
               "creator_family_name":"Demes",
               "creator_given_name":"Jessica",
               "creator_middle_name":"middle",
               "creator_suffix":"Mx",
               "creator_role":[
                  "Actor"
               ],
               "creator_institution":[
                  "Inst."
               ],
               "creator_orcid":"asdsd",
               "creator_institutional_email":"ssdf@test.com",
               "creator_profile_visibility":"closed"
            }
         ],
         "contributor":[],
         "date_accepted":null,
         "date_published":[
            "2028-1-1"
         ],
         "date_published_text":null,
         "date_submitted":"03/02/2022",
         "degree":null,
         "dewey":null,
         "doi":"https://doi.org/10.25677/wnjc-9s14",
         "duration":null,
         "edition":null,
         "eissn":null,
         "event_date":null,
         "event_location":null,
         "extent":null,
         "event_title":null,
         "files":{
            "has_private_files":false,
            "has_registered_files":false,
            "has_public_files":true
         },
         "funder":[ ],
         "funder_project_ref":null,
         "funding_description":null,
         "georeferenced":null,
         "institution":null,
         "irb_number":null,
         "irb_status":null,
         "is_included_in":null,
         "isbn":null,
         "issn":null,
         "issue":null,
         "is_format_of":null,
         "part_of":null,
         "journal_title":null,
         "journal_frequency":null,
         "keywords":[],
         "language":[
            "English"
         ],
         "library_of_congress_classification":null,
         "license":[
            {
               "name":"CC BY 4.0 Attribution",
               "link":"https://creativecommons.org/licenses/by/4.0/"
            }
         ],
         "location":null,
         "latitude":null,
         "longitude":null,
         "medium":null,
         "mentor":null,
         "mesh":[
            "Mesh"
         ],
         "official_url":null,
         "official_link":null,
         "org_unit":null,
         "outcome":null,
         "page_display_order_number":null,
         "pagination":null,
         "participant":null,
         "photo_caption":null,
         "photo_description":null,
         "place_of_publication":[
            "England"
         ],
         "prerequisites":null,
         "project_name":null,
         "publisher":[ ],
         "qualification_grantor":null,
         "qualification_level":null,
         "qualification_subject_text":null,
         "reading_level":null,
         "references":null,
         "refereed":null,
         "related_exhibition":null,
         "related_exhibition_date":null,
         "related_exhibition_venue":null,
         "related_material":null,
         "related_url":null,
         "repository_space":"University of Colorado Anschutz Medical Campus Strauss Health Sciences Library",
         "time":null,
         "resource_type":[
            "Collection"
         ],
         "rights_holder":null,
         "rights_statement":[
            "http://rightsstatements.org/vocab/CNE/1.0/"
         ],
         "rights_statement_text":null,
         "series_name":null,
         "source":[],
         "subject":null,
         "subject_text":[
            "Subject"
         ],
         "suggested_reviewers":null,
         "suggested_student_reviewers":null,
         "thumbnail_url":"http://repo.hyku.docker/assets/work-ff055336041c3f7d310ad69109eda4a887b16ec501f35afc0a547c4adb97ee72.png",
         "table_of_contents":null,
         "title":"anschutz_works - works",
         "type":"work",
         "version":null,
         "visibility":"open",
         "volume":null,
         "work_type":"AnschutzWork",
         "workflow_status":null,
         "collections":[]
      }
   ],
   "facet_counts":{
      "resource_type_sim":{
         "Collection":1
      },
      "creator_display_ssim":{
         "Demes, Jessica":1
      },
      "keyword_sim":{ },
      "member_of_collections_ssim":{},
      "institution_sim":{},
      "language_sim":{
         "eng":1
      },
      "org_unit_sim":{} ,
      "audience_sim":{},
      "file_availability":{
         "available":1
      }
   }
}
```

Other routes can be explored via the `config/routes.rb` file. 

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
