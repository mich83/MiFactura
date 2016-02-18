require 'test_helper'

class CustomDevise::RegistrationsControllerControllerTest < ActionController::TestCase
  test "should get create" do
    get :create
    assert_response :success
  end

end
