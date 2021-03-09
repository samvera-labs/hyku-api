# frozen_string_literal: true
FactoryBot.define do
  # FIXME: figure out how to override hyku's file set factory
  factory :api_file_set, class: FileSet do
    transient do
      user { create(:user) }
      content { nil }
    end
    after(:build) do |fs, evaluator|
      fs.apply_depositor_metadata evaluator.user.user_key
    end

    after(:create) do |file, evaluator|
      Hydra::Works::UploadFileToFileSet.call(file, evaluator.content) if evaluator.content
    end

    trait :public do
      visibility { 'open' }
    end

    trait :registered do
      visibility { 'authenticated' }
    end

    trait :private do
      visibility { 'restricted' }
    end

    trait :image do
      content { File.open(Hyku::API::Engine.root + 'spec/fixtures/world.png') }
    end
  end
end
