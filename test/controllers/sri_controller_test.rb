require 'test_helper'

class SriControllerTest < ActionController::TestCase
  test "should get RecepcionWSDL" do
    get :RecepcionWSDL
    assert_response :success
  end

  test "should get AutorizacionWSDL" do
    get :AutorizacionWSDL
    assert_response :success
  end

end
