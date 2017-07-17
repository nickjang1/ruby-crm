class String
  def to_bool
    ['t', 'true', '1', 'on', 'yes'].include? self
  end
end
