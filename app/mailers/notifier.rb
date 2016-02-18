class Notifier < ActionMailer::Base
  default from: '"mi factura" <no-reply@mifactura.ec>'
  default subject: "Bienvenido"
  default "Message-ID"=> lambda {|v| "#{Digest::SHA2.hexdigest(Time.now.to_i.to_s)}@mifactura.ec"}

  def welcome(recipient,unlockcode)
    @unlockcode = unlockcode
    @user = recipient

    @host = Rails.application.host

    mail(to: recipient.email)
  end

  def document(recipient, doc, caption)
    @doc = doc
    @host = Rails.application.host
    mail(to: recipient, subject: caption)
  end
end
