module Api
  module V1
    class AssetSnapshotsController < ApplicationController
      def index
        month = parse_month(params[:month])
        accounts = AssetAccount.order(:display_order)
        snapshots = AssetSnapshot.where(recorded_month: month)
          .index_by(&:asset_account_id)

        render json: accounts.map { |a|
          snap = snapshots[a.id]
          {
            account_id: a.id,
            name: a.name,
            account_type: a.account_type,
            display_order: a.display_order,
            amount: snap&.amount || 0,
            recorded: snap.present?
          }
        }
      end

      def bulk_update
        month = parse_month(params[:month])
        entries = params[:entries] || []

        entries.each do |entry|
          snap = AssetSnapshot.find_or_initialize_by(
            asset_account_id: entry[:account_id],
            recorded_month: month
          )
          snap.amount = entry[:amount].to_i
          snap.save!
        end

        render json: { success: true }
      rescue => e
        render json: { success: false, error: e.message }, status: :unprocessable_entity
      end

      def history
        snapshots = AssetSnapshot.includes(:asset_account)
          .order(:recorded_month)

        by_month = snapshots.group_by { |s| s.recorded_month.strftime('%Y-%m') }

        accounts = AssetAccount.order(:display_order)

        result = by_month.map do |month, snaps|
          snap_by_account = snaps.index_by(&:asset_account_id)
          total = snaps.sum(&:amount)
          breakdown = accounts.map { |a|
            { name: a.name, account_type: a.account_type, amount: snap_by_account[a.id]&.amount || 0 }
          }
          { month: month, total: total, breakdown: breakdown }
        end

        render json: result
      end

      private

      def parse_month(month_str)
        return Date.today.beginning_of_month if month_str.blank?
        Date.parse("#{month_str}-01")
      rescue
        Date.today.beginning_of_month
      end
    end
  end
end
