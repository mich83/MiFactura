class CustomDevise::RegistrationsController < Devise::RegistrationsController
  def create


    s_params = sign_up_params
    old_user = User.find_by(:email=>s_params[:email], :RUC=>s_params[:RUC],:locked => true)
    if s_params.has_key?(:clave)
      clave = s_params[:clave]
      s_params.delete(:clave)
    else
      clave = nil
    end
    if old_user.nil?
      if User.find_by(:email=>s_params[:email]) || User.find_by(:RUC=>s_params[:RUC])
        redirect_to "/", :notice=> :email_is_already_registered
        return
      end
      begin
        build_resource(s_params)
      rescue
        redirect_to "/", :notice => :invalid_options
        return
      end
    else
      self.resource = old_user
    end

    resource_saved = resource.save


    Rails.logger.debug resource.inspect
    yield resource if block_given?
    if resource_saved
      if !clave.nil?
        doc = Doc.find_by(:clave => clave )
        Rails.logger.debug doc.inspect
        if !doc.nil?
          SriHelper::SRI.send_password(doc)
        end
      end
      Rails.logger.debug "Saved"
      if !resource.locked
        set_flash_message :notice, :signed_up if is_flashing_format?
        sign_up(resource_name, resource)
        respond_with "/users/edit"
      else
        set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_flashing_format?
        expire_data_after_sign_in!
        redirect_to "/"
      end
    else
      Rails.logger.debug "Error in saving"

      clean_up_passwords resource
      @validatable = devise_mapping.validatable?
      if @validatable
        @minimum_password_length = resource_class.password_length.min
      end
      redirect_to "/", :notice => :error_in_registration_process
    end
  end
  def edit
    @check_password = current_user.encrypted_password.length != 0
    Rails.logger.debug current_user.encrypted_password.length
    render :edit
  end

  # PUT /resource
  # We need to use a copy of the resource because we don't want to change
  # the current user in place.
  def update
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    Rails.logger.debug self.resource.inspect
    prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)

    Rails.logger.debug account_update_params.inspect
    resource_updated = update_resource(resource, account_update_params)
    yield resource if block_given?
    if resource_updated
      if is_flashing_format?
        flash_key = update_needs_confirmation?(resource, prev_unconfirmed_email) ?
            :update_needs_confirmation : :updated
        set_flash_message :notice, flash_key
      end
      sign_in resource_name, resource, bypass: true
      redirect_to "/recibidos/facturas"
    else
      clean_up_passwords resource
      respond_with resource
    end
  end
  protected

  def sign_up_params
    s_params = devise_parameter_sanitizer.params.permit(devise_parameter_sanitizer.for(:sign_up))
    s_params[:locked] = true
    return s_params
  end


end
