class Date
  def week_number
    date = self + 1
    date.cweek
  end
end