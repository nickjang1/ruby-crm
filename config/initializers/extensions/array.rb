class Array
  def include_in_hash?(value, key = :option)
    any? { |a| a.is_a?(Hash) ? a[key] == value : a == value }
  end

  def select_in_hash(value, key = :option)
    select { |a| a.is_a?(Hash) ? a[key] == value : a == value }
  end
end