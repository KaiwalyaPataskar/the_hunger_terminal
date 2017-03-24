require "test_helper"

describe OrdersController do
  it "should get new" do
    get orders_new_url
    value(response).must_be :success?
  end

  it "should get index" do
    get orders_index_url
    value(response).must_be :success?
  end

  it "should get create" do
    get orders_create_url
    value(response).must_be :success?
  end

end
