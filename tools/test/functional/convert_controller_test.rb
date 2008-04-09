require File.dirname(__FILE__) + '/../test_helper'
require 'convert_controller'

# Re-raise errors caught by the controller.
class ConvertController; def rescue_action(e) raise e end; end

class ConvertControllerTest < Test::Unit::TestCase
  def setup
    @controller = ConvertController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
