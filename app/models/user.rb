class User
  include Mongoid::Document
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable

  store_in collection: "users"
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable

  ## Database authenticatable
  field :email,              type: String, default: ""
  field :encrypted_password, type: String, default: ""

  ## Recoverable
  field :reset_password_token,   type: String
  field :reset_password_sent_at, type: Time

  ## Rememberable
  field :remember_created_at, type: Time

  ## Trackable
  field :sign_in_count,      type: Integer, default: 0
  field :current_sign_in_at, type: Time
  field :last_sign_in_at,    type: Time
  field :current_sign_in_ip, type: String
  field :last_sign_in_ip,    type: String

  ## Confirmable
  # field :confirmation_token,   type: String
  # field :confirmed_at,         type: Time
  # field :confirmation_sent_at, type: Time
  # field :unconfirmed_email,    type: String # Only if using reconfirmable

  ## Lockable
  # field :failed_attempts, type: Integer, default: 0 # Only if lock strategy is :failed_attempts
  # field :unlock_token,    type: String # Only if unlock strategy is :email or :both
  # field :locked_at,       type: Time

  field :locked, type: Boolean

  field :RUC, type: String
  field :razonSocial, type: String
  field :unlockcode, type: String
  field :apiLimit, type: Integer

  before_save :check_ruc

  def update_with_password(params, *options)

    current_password = params.delete(:current_password)
    password_is_blank = false
    if params[:password].blank?
      password_is_blank = true
      params.delete(:password)
      params.delete(:password_confirmation) if params[:password_confirmation].blank?
    end
    result = if valid_password?(current_password) || encrypted_password.length == 0
               if password_is_blank
                  self.assign_attributes(params, *options)
                  self.valid?
                  self.errors.add(:password, :blank)
                  false
               else
                  Rails.logger.debug params.inspect
                  update_attributes(params, *options)
               end
             else
               self.assign_attributes(params, *options)
               self.valid?
               self.errors.add(:current_password, current_password.blank? ? :blank : :invalid)
               false
             end
    clean_up_passwords

    result
  end

  def self.find_by_ruc(ruc)
    user = self.find_by(:RUC=>ruc)
    #user = self.find_by(:RUC=>ruc.to_i.to_s) if user.nil?
    return user
  end

  private

  def check_ruc
    if SriHelper::SRI.get_identificacion(self.RUC) == :passport
      self.RUC.gsub!(/^0+/, '')
    end
  end
end
