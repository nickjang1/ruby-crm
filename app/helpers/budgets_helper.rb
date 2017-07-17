module BudgetsHelper

  def range_title first_half, year
    I18n.t("date.abbr_month_names")[first_half*6 + 1] + ' ~ ' + I18n.t("date.abbr_month_names")[first_half * 6 + 6] + ', ' + year.to_s
  end
  
  def month_name month
    I18n.t("date.month_names")[month]
  end

end