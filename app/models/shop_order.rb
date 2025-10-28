# == Schema Information
#
# Table name: shop_orders
#
#  id                      :bigint           not null, primary key
#  approved_at             :datetime
#  frozen_address          :jsonb
#  frozen_unit_ticket_cost :integer
#  frozen_unit_usd_cost    :integer
#  fufilled_at             :datetime
#  fufillment_usd_cost     :integer
#  hold_reason             :string
#  internal_notes          :string
#  on_hold_at              :datetime
#  quantity                :integer
#  rejected_at             :datetime
#  rejection_reason        :string
#  state                   :integer          default("pending"), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  approved_by_id          :bigint
#  fufilled_by_id          :bigint
#  on_hold_by_id           :bigint
#  rejected_by_id          :bigint
#  shop_item_id            :bigint           not null
#  user_id                 :bigint           not null
#
# Indexes
#
#  index_shop_orders_on_approved_by_id  (approved_by_id)
#  index_shop_orders_on_fufilled_by_id  (fufilled_by_id)
#  index_shop_orders_on_on_hold_by_id   (on_hold_by_id)
#  index_shop_orders_on_rejected_by_id  (rejected_by_id)
#  index_shop_orders_on_shop_item_id    (shop_item_id)
#  index_shop_orders_on_user_id         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (approved_by_id => users.id)
#  fk_rails_...  (fufilled_by_id => users.id)
#  fk_rails_...  (on_hold_by_id => users.id)
#  fk_rails_...  (rejected_by_id => users.id)
#  fk_rails_...  (shop_item_id => shop_items.id)
#  fk_rails_...  (user_id => users.id)
#
class ShopOrder < ApplicationRecord
  enum :state, {
    pending: 0,
    awaiting_verification: 1,
    approved: 2,
    fufilled: 3,
    rejected: 4,
    on_hold: 5
  }

  belongs_to :user
  belongs_to :shop_item

  belongs_to :approved_by, class_name: "User", optional: true
  belongs_to :fufilled_by, class_name: "User", optional: true
  belongs_to :rejected_by, class_name: "User", optional: true
  belongs_to :on_hold_by, class_name: "User", optional: true

  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validate :quantity_within_stock, on: :create

  before_validation :freeze_unit_costs, on: :create

  private

  def freeze_unit_costs
    return unless shop_item

    self.frozen_unit_ticket_cost ||= shop_item.ticket_cost
    self.frozen_unit_usd_cost ||= shop_item.usd_cost
  end

  def quantity_within_stock
    return unless shop_item && quantity && shop_item.total_stock.present?

    if quantity > shop_item.total_stock
      errors.add(:quantity, "cannot exceed available stock of #{shop_item.total_stock}")
    end
  end
end
