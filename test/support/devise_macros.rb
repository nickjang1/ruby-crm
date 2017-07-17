module DeviseMacros
  def sign_in(resource)
    login_as resource, scope: :user
  end

  def sign_out
    logout :user
  end
end
