# When an OpenStruct is converted to json, it inludes @table.
# We inherit and overide as_json here to use to contain answer_settings, which
# is a json hash converted into an object by ActiveResource. Using a plain hash
# for answer_settings means there is no .access to attributes.
class DataStruct < OpenStruct
  def as_json(*args)
    super.as_json["table"]
  end
end

FactoryBot.define do
  factory :page do
    association :form

    question_text { Faker::Lorem.question }
    answer_type { Page::ANSWER_TYPES.sample }
    is_optional { nil }
    answer_settings { nil }
    sequence(:position)
    routing_conditions { [] }
    check_conditions { [] }
    goto_conditions { [] }

    trait :with_hints do
      hint_text { Faker::Quote.yoda }
    end

    trait :with_selections_settings do
      transient do
        only_one_option { "true" }
        selection_options { [{ name: "Option 1" }, { name: "Option 2" }] }
      end

      answer_type { "selection" }
      answer_settings { DataStruct.new(only_one_option:, selection_options:) }
    end
  end
end
