require 'mail'

# test with
# rvmsudo ruby -e "load 'my_mail.rb';MyMail.send()"
# using sudo requires -E to pass enviroment variables
# sudo -E ruby -e "load 'my_mail.rb';MyMail.send()"

GMAIL_EMAIL = ENV['GMAIL_EMAIL'] # ENV['rvm_EMAIL_USER_NAME'],
GMAIL_PASSWORD = ENV['GMAIL_PASSWORD'] # ENV['rvm_EMAIL_PASSWORD'],
EXCEPTION_RECIPIENTS = ENV['EXCEPTION_RECIPIENTS'] # ENV['rvm_EMAIL_RECIPIENT_EMAIL']

options = {
  address: 'smtp.gmail.com',
  port: 587,
  user_name: GMAIL_EMAIL,
  password: GMAIL_PASSWORD,
}
# puts options

Mail.defaults do
  delivery_method :smtp, options
end

module MyMail
  def self.send(subject: 'alert', text: 'hi', attachment: nil)
    puts "Send email #{text} #{attachment}"
    Mail.deliver do
      to EXCEPTION_RECIPIENTS
      from GMAIL_EMAIL
      subject subject
      body text
      add_file attachment unless attachment.nil?
    end
  rescue StandardError => e
    puts "MyMail.send failed #{e}"
  end
end
