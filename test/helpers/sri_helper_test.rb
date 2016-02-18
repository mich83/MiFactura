require 'test_helper'

class SriHelperTest < ActionView::TestCase
  test "identificacion" do
    assert SriHelper::SRI.get_identificacion('1234567890123') == :passport
    assert SriHelper::SRI.get_identificacion('1234567890') == :passport
    assert SriHelper::SRI.get_identificacion('0931811392') == :cedula
  end
end
