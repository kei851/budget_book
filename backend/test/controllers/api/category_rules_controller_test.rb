require "test_helper"

class Api::CategoryRulesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get api_category_rules_index_url
    assert_response :success
  end

  test "should get create" do
    get api_category_rules_create_url
    assert_response :success
  end

  test "should get update" do
    get api_category_rules_update_url
    assert_response :success
  end

  test "should get destroy" do
    get api_category_rules_destroy_url
    assert_response :success
  end

  test "should get bulk_update" do
    get api_category_rules_bulk_update_url
    assert_response :success
  end
end
