require "test_helper"

class Api::V1::TransactionsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get api_v1_transactions_index_url
    assert_response :success
  end

  test "should get update" do
    get api_v1_transactions_update_url
    assert_response :success
  end

  test "should get import" do
    get api_v1_transactions_import_url
    assert_response :success
  end

  test "should get monthly" do
    get api_v1_transactions_monthly_url
    assert_response :success
  end

  test "should get analytics" do
    get api_v1_transactions_analytics_url
    assert_response :success
  end
end
