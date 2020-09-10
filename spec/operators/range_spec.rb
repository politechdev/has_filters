require 'spec_helper'

RSpec.describe HasFilters::Operators::Range do
  before do
    ActiveRecord::Base.connection.create_table "filterables" do |t|
      t.integer :filterable_integer
      t.date :filterable_date
    end

    Filterable = Class.new(ActiveRecord::Base)
    Filterable.table_name = "filterables"
  end

  after do
    ActiveRecord::Base.connection.drop_table "filterables"
  end

  describe "#query" do
    subject { operator.query }

    context "when filtering integer with range value" do
      let(:operator) { described_class.new(Filterable, :filterable_integer, 1..5) }

      let!(:record_in_range) { Filterable.create!(filterable_integer: 3) }
      let!(:record_outside_range) { Filterable.create!(filterable_integer: 6) }

      it { is_expected.to include(record_in_range) }
      it { is_expected.not_to include(record_outside_range) }
    end

    context "when filtering integer with array" do
      let(:operator) { described_class.new(Filterable, :filterable_integer, [1, 5]) }

      let!(:record_in_range) { Filterable.create!(filterable_integer: 3) }
      let!(:record_outside_range) { Filterable.create!(filterable_integer: 6) }

      it { is_expected.to include(record_in_range) }
      it { is_expected.not_to include(record_outside_range) }
    end

    context "when filtering integer with array in reverse order" do
      let(:operator) { described_class.new(Filterable, :filterable_integer, [5, 1]) }

      let!(:record_in_range) { Filterable.create!(filterable_integer: 3) }
      let!(:record_outside_range) { Filterable.create!(filterable_integer: 6) }

      it { is_expected.to include(record_in_range) }
      it { is_expected.not_to include(record_outside_range) }
    end

    context "when filtering integer with array with non-range-like object" do
      let(:operator) { described_class.new(Filterable, :filterable_integer, "what") }

      it { is_dynamically_expected.to raise_error(HasFilters::Operators::InvalidFilterParam) }
    end

    context "when filtering date with array" do
      let(:operator) { described_class.new(Filterable, :filterable_date, [3.days.ago, 1.day.ago]) }

      let(:record_in_range) { Filterable.create!(filterable_date: 2.days.ago) }
      let(:record_outside_range) { Filterable.create!(filterable_date: 4.days.ago) }

      it { is_expected.to include(record_in_range) }
      it { is_expected.not_to include(record_outside_range) }
    end
  end
end
