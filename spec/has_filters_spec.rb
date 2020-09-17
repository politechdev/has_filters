require 'spec_helper'

RSpec.describe HasFilters do
  before(:context) do
    ActiveRecord::Base.connection.create_table "filterables" do |t|
      t.integer :filterable_friend_id
      t.string :filterable_string
      t.integer :filterable_integer
      t.datetime :filterable_datetime
      t.date :filterable_date
      t.date :filterable_date
      t.integer :filterable_enum
    end

    ActiveRecord::Base.connection.create_table "filterable_friends" do |t|
      t.string :friends_attr
    end

    Filterable = Class.new(ActiveRecord::Base) do
      include HasFilters

      belongs_to :filterable_friend
    end
    Filterable.table_name = "filterables"

    FilterableFriend = Class.new(ActiveRecord::Base) do
      include HasFilters

      has_many :filterables
    end
    FilterableFriend.table_name = "filterable_friends"
  end

  after(:context) do
    ActiveRecord::Base.connection.drop_table "filterable_friends"
    ActiveRecord::Base.connection.drop_table "filterables"
  end


  describe ".filterable columns" do
    subject { Filterable.filterable_attrs }

    before do
      Filterable.class_eval do
        has_filters :filterable_string
      end
    end

    it { is_expected.to include(:filterable_string) }
  end

  describe ".filter" do
    context "with nested inclusive filters when base scope is limited" do
      subject { Filterable.limit(1).filter(rules: rules) }

      let(:rules) do
        [
          {
            rules: [
              { column: "filterable_string", operator: "containing", param: "what" },
              { column: "filterable_string", operator: "is", param: "testing" }
            ],
            conjunction: 'inclusive'
          },
          {
            rules: [
              { column: "filterable_string", operator: "is", param: "test" },
              { column: "filterable_string", operator: "is", param: "test" },
              { column: "filterable_string", operator: "containing", param: "ing" }
            ],
            conjunction: 'inclusive'
          }
        ]
      end

      before do
        Filterable.class_eval do
          has_filters :filterable_string
        end

        Filterable.create!(filterable_string: "testing")
        Filterable.create!(filterable_string: "test")
      end

      it { is_expected.to have(1).items }
    end

    context "when inclusive filter is chained" do
      subject { Filterable.limit(1).filter(rules: [{ column: "filterable_string", operator: "is", param: "test" }, { column: "filterable_string", operator: "is", param: "testing" }], conjunction: :inclusive) }

      before do
        Filterable.class_eval do
          has_filters :filterable_string
        end

        Filterable.create!(filterable_string: "testing")
        Filterable.create!(filterable_string: "test")
      end

      it { is_expected.to have(1).items }
    end

    context "when inclusive filter is chained with another condition" do
      subject { Filterable.where(filterable_string: "test").filter(rules: [{ column: "filterable_string", operator: "is", param: "test" }, { column: "filterable_string", operator: "is", param: "testing" }], conjunction: :inclusive) }

      before do
        Filterable.class_eval do
          has_filters :filterable_string
        end

        Filterable.create!(filterable_string: "testing")
        Filterable.create!(filterable_string: "test")
      end

      it { is_expected.to have(1).items }
    end

    context "with default operator" do
      subject { Filterable.filter(rules: rules) }

      let(:rules) do
        [
          { column: "filterable_string", operator: "is", param: "test" },
          { column: "filterable_string", operator: "containing", param: "what" }
        ]
      end

      before do
        Filterable.class_eval do
          has_filters :filterable_string
        end

        Filterable.create!(filterable_string: "testing")
        Filterable.create!(filterable_string: "test")
      end

      it { is_expected.to be_empty }
    end

    context "when a non-array arg is passed" do
      subject { Filterable.filter(rules: "wrong") }

      before do
        Filterable.class_eval do
          has_filters :filterable_string
        end
      end

      it { is_dynamically_expected.to raise_error(HasFilters::InvalidFilterError) }
    end

    context "when a non-hash filter is passed" do
      subject { Filterable.filter(rules: ["wrong"]) }

      before do
        Filterable.class_eval do
          has_filters :filterable_string
        end
      end

      it { is_dynamically_expected.to raise_error(HasFilters::InvalidFilterError) }
    end

    context "with inclusive operator" do
      subject { Filterable.filter(rules: rules, conjunction: :inclusive) }

      let!(:exact_match) { Filterable.create!(filterable_string: "test") }

      let(:rules) do
        [
          { column: "filterable_string", operator: "is", param: "test" },
          { column: "filterable_string", operator: "containing", param: "what" }
        ]
      end

      before do
        Filterable.class_eval do
          has_filters :filterable_string
        end

        Filterable.create!(filterable_string: "testing")
      end

      it { is_expected.to contain_exactly(exact_match) }
    end

    context "with a nested rule set" do
      subject { Filterable.filter(rules: rules) }

      let!(:exact_match) { Filterable.create!(filterable_string: "test") }

      let(:rules) do
        [
          {
            rules: [
              { column: "filterable_string", operator: "is", param: "test" },
            ]
          },
          { column: "filterable_string", operator: "containing", param: "es" }
        ]
      end

      before do
        Filterable.class_eval do
          has_filters :filterable_string
        end

        Filterable.create!(filterable_string: "testing")
      end

      it { is_expected.to contain_exactly(exact_match) }
    end

    context "with a nested rule set with string keys" do
      subject { Filterable.filter(rules: rules) }

      let!(:exact_match) { Filterable.create!(filterable_string: "test") }

      let(:rules) do
        [
          {
            "rules" => [
              { "column" => "filterable_string", "operator" => "is", "param" => "test" },
            ]
          },
          { column: "filterable_string", operator: "containing", param: "es" }
        ]
      end

      before do
        Filterable.class_eval do
          has_filters :filterable_string
        end

        Filterable.create!(filterable_string: "testing")
      end

      it { is_expected.to contain_exactly(exact_match) }
    end

    context "with invalid rule" do
      subject { Filterable.filter(rules: [{ not: "real" }]) }

      before do
        Filterable.class_eval do
          has_filters :filterable_string
        end
      end

      it { is_dynamically_expected.to raise_error(HasFilters::InvalidFilterError) }
    end

    context "with blank rule" do
      subject { Filterable.filter(rules: [{}]) }

      let!(:match) { Filterable.create! }

      before do
        Filterable.class_eval do
          has_filters :filterable_string
        end
      end

      it { is_expected.to include(match) }
    end

    context "when column refers to existing scope" do
      subject { Filterable.filter(rules: [{ column: "with_custom_scope", param: "value" }]) }

      before do
        Filterable.class_eval do
          has_filters scopes: %i(with_custom_scope)

          def self.with_custom_scope(_rule); all end
        end

        Filterable.create!
      end

      it { is_expected.to include(*Filterable.all) }
    end

    context "when column refers to existing scope with multiple arguments" do
      subject { Filterable.filter(rules: [{ column: "with_custom_scope", param: %w(arg1 arg2) }]) }

      before do
        Filterable.class_eval do
          has_filters scopes: %i(with_custom_scope)

          def self.with_custom_scope(_one, _two); all end
        end
      end

      it { is_dynamically_expected.not_to raise_error }
    end

    context "when column refers to existing scope with keyword arguments" do
      subject { Filterable.filter(rules: [{ column: "with_custom_scope", param: { "arg1" => 1, "arg2" => 2 } }]) }

      before do
        Filterable.class_eval do
          has_filters scopes: %i(with_custom_scope)

          def self.with_custom_scope(arg1:, arg2:); all end
        end
      end

      it { is_dynamically_expected.not_to raise_error }
    end

    context "when column refers to association scope" do
      subject { Filterable.filter(rules: [{ column: "filterable_friend_with_custom_scope", param: "value" }]) }

      before do
        FilterableFriend.class_eval do
          has_filters scopes: %i(with_custom_scope)

          def self.with_custom_scope(_rule); all end
        end

        Filterable.class_eval do
          has_filters :filterable_friend, scopes: %i(filterable_friend_with_custom_scope)
        end

        Filterable.create!(filterable_string: "testing")
        Filterable.create!(filterable_string: "test")
      end

      it { is_expected.to include(*Filterable.all) }
    end

    context "when column refers to association scope that takes multiple arguments" do
      subject { Filterable.filter(rules: [{ column: "filterable_friend_with_custom_scope", param: %w(arg1 arg2) }]) }

      before do
        FilterableFriend.class_eval do
          has_filters scopes: %i(with_custom_scope)

          def self.with_custom_scope(_one, _two); all end
        end

        Filterable.class_eval do
          has_filters :filterable_friend, scopes: %i(filterable_friend_with_custom_scope)
        end
      end

      it { is_dynamically_expected.not_to raise_error }
    end

    context "when column refers to non-existing scope" do
      subject { Filterable.filter(rules: rules) }

      let(:rules) { [{ column: "name", operator: "is", param: "test" }] }

      before do
        Filterable.class_eval do
          has_filters :filterable_string
        end
      end

      it { is_dynamically_expected.to raise_error(HasFilters::UnfilterableAttrError) }
    end
  end

  context "with virtual column" do
    subject { Filterable.by_cccombo("test 1") }

    let(:match) { Filterable.create!(filterable_string: "test", filterable_integer: 1) }

    before do
      Filterable.class_eval do
        has_filters aliases: { cccombo: "filterable_string || ' ' || filterable_integer::text" }
      end
    end

    it { is_expected.to include(match) }
  end

  context "with string column" do
    before do
      Filterable.class_eval do
        has_filters :filterable_string
      end
    end

    context "with nil value" do
      subject { Filterable.by_filterable_string(nil) }

      let(:match) { Filterable.create!(filterable_string: nil) }
      let(:non_match) { Filterable.create!(filterable_string: "test") }

      it { is_expected.to include(match) }
      it { is_expected.not_to include(non_match) }
    end

    context "with inverted nil value" do
      subject { Filterable.by_filterable_string(is: nil, invert: true) }

      let(:non_match) { Filterable.create!(filterable_string: nil) }
      let(:match) { Filterable.create!(filterable_string: "test") }

      it { is_expected.to include(match) }
      it { is_expected.not_to include(non_match) }
    end

    context "when no operator is specified" do
      subject { Filterable.by_filterable_string("test") }

      let(:exact_match) { Filterable.create!(filterable_string: "test") }
      let(:close_match) { Filterable.create!(filterable_string: "testing") }

      it { is_expected.to include(exact_match) }
      it { is_expected.not_to include(close_match) }
    end

    context "when inverted" do
      subject { Filterable.by_filterable_string(is: "testing", invert: true) }

      let(:non_match) { Filterable.create!(filterable_string: "test") }
      let(:match) { Filterable.create!(filterable_string: "testing") }
      let(:nil_match) { Filterable.create!(filterable_string: nil) }

      it { is_expected.to include(non_match) }
      it { is_expected.to include(nil_match) }
    end

    context "when containing operator is specified" do
      subject { Filterable.by_filterable_string(containing: "test") }

      let(:exact_match) { Filterable.create!(filterable_string: "test") }
      let(:close_match) { Filterable.create!(filterable_string: "testing") }

      it { is_expected.to include(exact_match) }
      it { is_expected.to include(close_match) }
    end
  end

  context "with integer column" do
    before do
      Filterable.class_eval do
        has_filters :filterable_integer
      end
    end

    context "when param is a string" do
      subject { Filterable.by_filterable_integer(is: 'what') }

      it { is_expected.to be_empty }
    end

    context "when greater operator is specified" do
      subject { Filterable.by_filterable_integer(more_than: 5) }

      let(:match) { Filterable.create!(filterable_integer: 6) }
      let(:non_match) { Filterable.create!(filterable_integer: 4) }

      it { is_expected.to include(match) }
      it { is_expected.not_to include(non_match) }
    end

    context "when lesser operator is specified" do
      subject { Filterable.by_filterable_integer(less_than: 5) }

      let(:non_match) { Filterable.create!(filterable_integer: 6) }
      let(:match) { Filterable.create!(filterable_integer: 4) }

      it { is_expected.to include(match) }
      it { is_expected.not_to include(non_match) }
    end
  end

  context "with date column" do
    before do
      Filterable.class_eval do
        has_filters :filterable_date
      end
    end

    context "when after operator is specified" do
      subject { Filterable.by_filterable_date(after: 2.days.ago) }

      let(:match) { Filterable.create!(filterable_date: 1.day.ago) }
      let(:non_match) { Filterable.create!(filterable_date: 3.days.ago) }

      it { is_expected.to include(match) }
      it { is_expected.not_to include(non_match) }
    end

    context "when lesser operator is specified" do
      subject { Filterable.by_filterable_date(before: 2.days.ago) }

      let(:non_match) { Filterable.create!(filterable_date: 1.day.ago) }
      let(:match) { Filterable.create!(filterable_date: 3.days.ago) }

      it { is_expected.to include(match) }
      it { is_expected.not_to include(non_match) }
    end
  end

  context "with has_many join" do
    let!(:non_match) { FilterableFriend.create! }
    let!(:friend) { Filterable.create!(filterable_friend: non_match) }

    before do
      FilterableFriend.class_eval do
        has_filters :filterables
      end

      Filterable.class_eval do
        has_filters
      end

      Filterable.create!(filterable_friend: non_match)
    end

    context "when inverted with matching child and non matching child" do
      subject { FilterableFriend.by_filterables(is: friend.id, invert: true) }

      it { is_expected.not_to include(non_match) }
    end
  end

  context "with enum" do
    subject { Filterable.by_filterable_enum(:test) }

    let(:match) { Filterable.create!(filterable_enum: :test) }

    before do
      Filterable.class_eval do
        has_filters :filterable_enum

        enum filterable_enum: %w(test)
      end
    end

    it { is_expected.to include(match) }
  end

  context "with join" do
    let(:friend) { FilterableFriend.create!(friends_attr: "test") }
    let(:match) { Filterable.create!(filterable_friend: friend) }

    before do
      FilterableFriend.class_eval do
        has_filters :friends_attr, aliases: { virtually: 'friends_attr' }
      end

      Filterable.class_eval do
        has_filters :filterable_friend
      end
    end

    context "with no joined record and nil param" do
      subject { Filterable.by_filterable_friend(nil) }

      let(:match) { Filterable.create!(filterable_friend: nil) }

      it { is_expected.to include(match) }
    end

    context "when no attribute is specified" do
      subject { Filterable.by_filterable_friend(friend.id) }

      let(:friend) { FilterableFriend.create! }
      let(:match) { Filterable.create!(filterable_friend: friend) }

      it { is_expected.to include(match) }
    end

    context "when attribute is specified" do
      subject { Filterable.by_filterable_friend_friends_attr("test") }

      it { is_expected.to include(match) }
    end

    context "with virtual attr" do
      subject { Filterable.by_filterable_friend_virtually("test") }

      it { is_expected.to include(match) }
    end
  end
end
