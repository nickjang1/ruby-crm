class Report < ActiveRecord::Base
  has_many :report_favoritings
  has_many :favoriting_users, through: :report_favoritings, source: :user
  has_many :report_runs

  scope :for_maintenance, -> { where('groups ILIKE ?', 'maintenance') }

  ALL_KINDS = [
    {permalink: 'vendor_spend', name: 'Vendor Spend', description: "Provides analysis of the total spending on your Vendors.  Useful to understand who are your top Vendors to negotiate contracts with.", groups: 'spending' },
    {permalink: 'category_spend', name: 'Category Spend', description: "Understand your Hotel's spending by Category. Analyze which categories comprise most of your hotel's spending", groups: 'spending' },
    {permalink: 'items_spend', name: 'Items Spend', description: "Analyze which items comprise 80% of your spending. Optimize the procurement and inventory to reduce costs.", groups: 'spending' }, {permalink: 'purchase_history_report', name: 'Purchase History Report', description: "Understand your Hotel's spending by Category. Analyze which categories comprise most of your hotel's spending", groups: 'purchases' },
    # {permalink: 'budget_vs_spend', name: 'Budget vs Spend', description: "Description goes here", groups: 'budget' },
    # {permalink: 'cpor_analysis', name: 'CPOR Analysis', description: "Description goes here", groups: 'budget' },
    # {permalink: 'vendor_list', name: 'Vendor List', description: "Description goes here", groups: 'misc' },
    # {permalink: 'list_item_coverage', name: 'List Item Coverage', description: "Description goes here", groups: 'misc' },
    {permalink: 'items_consumption', name: 'Items Consumption', description: "Consumption Report allows you to analyze the frequency, size and value of your Ordering for individual items to understand and compare your consumption between periods.", groups: 'purchases,misc' },
    {permalink: 'item_price_variance', name: 'Item Price Variance', description: "Provides data from Item's Received Orders to analyze the variation in the PO price and the Actual price an item is received at.", groups: 'spending,misc' },
    # {permalink: 'inventory_vs_ordering', name: 'Inventory vs Ordering', description: "...", groups: 'purchases, misc' },
    {permalink: 'maintenance_work_orders', name: 'Work Order Listing', description: "View all work orders for the hotel.", groups: 'maintenance' },
    {permalink: 'pm_productivity_report', name: 'PM Productivity Report', description: "Analyze the productivity of the Maintenance department", groups: 'maintenance' },
    {permalink: 'guest_room_pm_analysis', name: 'Guest Room PM Analysis', description: "Understand the Guest Room PM status for the current Quarter, and analyze the history of PM completions.", groups: 'maintenance' },
    {permalink: 'public_area_pm_analysis', name: 'Public Area PM Analysis', description: "Understand the Public Area PM status for the current Quarter, and analyze the history of PM completions.", groups: 'maintenance' },
    {permalink: 'equipment_pm_analysis', name: 'Equipment PM Analysis', description: "Understand the Equipment PM status for the current Quarter, and analyze the history of PM completions.", groups: 'maintenance' },
    {permalink: 'work_order_trendings', name: 'Hotel Trending Issue', description: "The trending issues report will allow managers to understand the frequently seen issues during PMs and Work Orders in a given period of time", groups: 'maintenance' }
  ]

  def groups_as_array
    self.groups.split(',').map(&:strip)
  end

  def toggle_favorited_by!(user)
    if favorited_by?(user)
      favoriting_users.delete(user)
    else
      favoriting_users << user
    end
  end

  def favorited_by?(user)
    favoriting_users.include?(user)
  end

  def record_run_by!(user)
    report_runs.create(user: user)
  end

  def last_run
    @last_run ||= report_runs.order(:created_at).last
  end

  def last_run_by_name
    last_run.user.name
  end

 def last_run_at
   last_run.created_at
 end
end
