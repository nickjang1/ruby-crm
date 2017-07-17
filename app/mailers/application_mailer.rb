class ApplicationMailer < ActionMailer::Base
  layout 'mail'
  default from: 'no-reply@lodgistics.com'
end