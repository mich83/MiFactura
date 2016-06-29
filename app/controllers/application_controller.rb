class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up).reject! { |a| true }
    devise_parameter_sanitizer.for(:sign_up) <<:RUC
    devise_parameter_sanitizer.for(:sign_up) <<:email
    devise_parameter_sanitizer.for(:sign_up) <<:clave
  end

  def view_init(variables)
    variables.each_key do |var|
      instance_variable_set("@#{var}".to_sym, variables[var])
    end
  end
end
