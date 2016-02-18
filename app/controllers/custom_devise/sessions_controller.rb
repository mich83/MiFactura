class CustomDevise::SessionsController < Devise::SessionsController
  def create
    Rails.logger.debug auth_options.inspect
    self.resource = warden.authenticate!(auth_options)
    Rails.logger.debug self.resource.inspect
    set_flash_message(:notice, :signed_in) if is_flashing_format?
    sign_in(resource_name, resource)
    yield resource if block_given?
    redirect_to "/recibidos/facturas"
    #respond_with resource, location: after_sign_in_path_for(resource)
  end

  def new
    self.resource = resource_class.new(sign_in_params)
    clean_up_passwords(resource)

    Rails.logger.debug self.resource.inspect
    if user_signed_in?
      redirect_to "/recibidos/facturas"
    else
      redirect_to "/", :alert => "Invalid user name or password"
    end
  end


  def activate
    user = User.find(params[:id])
    if !user.nil?
      if !user.locked
        redirect_to "/", :notice =>  :account_is_already_activated
        return
      end
      if user.unlockcode == params[:code]
        self.resource = user
      else
        redirect_to "/", :notice => :wrong_activation_code
        return
      end
    else
      redirect_to "/", :notice => :user_not_found
      return
    end
    user.locked = false
    user.unlockcode = nil
    if !user.save
      redirect_to "/", :notice => :error_saving_user

      return
    end

    sign_in(resource_name,resource)
    yield resource if block_given?
    redirect_to "/users/edit"


  end
end
