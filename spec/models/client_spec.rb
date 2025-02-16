# frozen_string_literal: true

require "rails_helper"

RSpec.describe Client, type: :model do
  subject { build(:client) }

  describe "Validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).scoped_to(:company_id) }
    it { is_expected.to allow_value("valid@email.com").for(:email) }
    it { is_expected.not_to allow_value("invalid@email").for(:email) }
  end

  describe "Associations" do
    it { is_expected.to have_many(:projects) }
    it { is_expected.to have_many(:timesheet_entries) }
    it { is_expected.to belong_to(:company) }
  end

  describe "Scopes" do
    describe "default scope" do
      let(:company) { create(:company) }

      before do
        create_list(:client, 2, company:)
      end

      it "when a client is discarded default scope won't query discarded client record" do
        expect(company.clients.count).to eq(2)
        company.clients.first.update(discarded_at: Time.now)
        expect(company.clients.count).to eq(1)
        expect(company.clients.unscoped.count).to eq(2)
      end
    end
  end

  describe "Public methods" do
    describe "#total_hours_logged" do
      let(:company) { create(:company) }
      let(:user) { create(:user) }
      let(:client) { create(:client, company:) }
      let(:project_1) { create(:project, client:) }
      let(:project_2) { create(:project, client:) }
      let(:results) do
      end

      before do
        create_list(:timesheet_entry, 5, user:, project: project_1)
        create_list(:timesheet_entry, 5, user:, project: project_2)
      end

      context "when time_frame is last week" do
        let(:time_frame) { "last_week" }

        it "returns the total hours logged for a client in the last week" do
          range = 1.week.ago.beginning_of_week..1.week.ago.end_of_week
          result = ([project_1, project_2].map { |project|
            project.timesheet_entries.where(work_date: range).sum(:duration)
          }).sum
          expect(client.total_hours_logged(time_frame)).to eq(result)
        end
      end

      context "when time_frame in a week" do
        let(:time_frame) { "week" }

        it "returns the total hours logged for a client in that week" do
          range = 0.week.ago.beginning_of_week..0.week.ago.end_of_week
          result = ([project_1, project_2].map { |project|
            project.timesheet_entries.where(work_date: range).sum(:duration)
          }).sum
          expect(client.total_hours_logged(time_frame)).to eq(result)
        end
      end

      context "when time_frame in a month" do
        let(:time_frame) { "month" }

        it "returns the total hours logged for a client in that month" do
          range = 0.month.ago.beginning_of_week..0.month.ago.end_of_week
          result = ([project_1, project_2].map { |project|
            project.timesheet_entries.where(work_date: range).sum(:duration)
          }).sum
          expect(client.total_hours_logged(time_frame)).to eq(result)
        end
      end

      context "when time_frame in a year" do
        let(:time_frame) { "year" }

        it "returns the total hours logged for a client in that year" do
          range = 0.year.ago.beginning_of_week..0.year.ago.end_of_week
          result = ([project_1, project_2].map { |project|
            project.timesheet_entries.where(work_date: range).sum(:duration)
          }).sum
          expect(client.total_hours_logged(time_frame)).to eq(result)
        end
      end
    end

    describe "#project_details" do
      let(:company) { create(:company) }
      let(:user) { create(:user) }
      let(:client) { create(:client, company:) }
      let(:project_1) { create(:project, client:) }
      let(:project_2) { create(:project, client:) }
      let(:date_range_class) { Class.new { extend UtilityFunctions } }
      let(:results) do
        range = date_range_class.range_from_timeframe(time_frame)
        [project_1, project_2].map do | project |
          {
            id: project.id, name: project.name, billable: project.billable, team: project.project_member_full_names,
            minutes_spent: project.timesheet_entries.where(work_date: range).sum(:duration)
          }
        end
      end

      before do
        create_list(:timesheet_entry, 5, user:, project: project_1)
        create_list(:timesheet_entry, 5, user:, project: project_2)
      end

      context "when time_frame is last_week" do
        let(:time_frame) { "last_week" }

        it "returns the hours_logged for a project in the last week" do
          expect(client.project_details(time_frame)).to match_array(results)
        end
      end

      context "when time_frame is week" do
        let(:time_frame) { "week" }

        it "returns the hours_logged for a project in that week" do
          expect(client.project_details(time_frame)).to match_array(results)
        end
      end

      context "when time_frame is month" do
        let(:time_frame) { "month" }

        it "returns the hours_logged for a project in that month" do
          expect(client.project_details(time_frame)).to match_array(results)
        end
      end

      context "when time_frame is year" do
        let(:time_frame) { "year" }

        it "returns the hours_logged for a project in that year" do
          expect(client.project_details(time_frame)).to match_array(results)
        end
      end
    end

    describe "#client_overdue_and_outstanding_calculation" do
      let(:company) { create(:company) }
      let(:user) { create(:user) }
      let(:client) { create(:client, company:) }

      before do
        create_list(:invoice, 5, client:)
      end

      it "return outstanding_amount overdue_amount amounts" do
        currency = client.company.base_currency
        status_and_amount = client.invoices.group(:status).sum(:amount)
        status_and_amount.default = 0
        outstanding_amount = status_and_amount["sent"] + status_and_amount["viewed"]
        + status_and_amount["overdue"]
        result = {
          overdue_amount: status_and_amount["overdue"],
          outstanding_amount:,
          currency:
        }
        expect(client.client_overdue_and_outstanding_calculation).to match_array(result)
      end
    end

    describe "#register_on_stripe!" do
      let(:company) { create(:company) }
      let(:user) { create(:user) }
      let(:client) { create(:client, company:) }

      context "when associated stripe connected account doesn't exist" do
        it "raises ActiveRecord::RecordNotFound" do
          expect { client.register_on_stripe! }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "when associated stripe connected account exists" do
        let(:stripe_connected_account) { build(:stripe_connected_account, company:) }

        it "creates customer for the connected account" do
          allow(Stripe::Account).to receive(:create)
            .and_return(OpenStruct.new({ id: stripe_connected_account.account_id }))
          allow(Stripe::Customer).to receive(:create)
            .and_return(OpenStruct.new({ id: 123 }))
          stripe_connected_account.save!
          expect(client.register_on_stripe!).to eq(true)
        end
      end
    end
  end
end
