require File.dirname(__FILE__) + '/spec_helper.rb'
require 'webrick'
require 'base64'

describe Patron::Session do

  before(:each) do
    @session = Patron::Session.new
    @session.base_url = "http://localhost:9001"
  end

  it "should escape and unescape strings symetrically" do
    string = "foo~bar baz/"
    escaped = @session.escape(string)
    unescaped = @session.unescape(escaped)
    unescaped.should == string
  end

  it "should raise an error when no URL is provided" do
    @session.base_url = nil
    lambda {@session.get(nil)}.should raise_error(ArgumentError)
  end

  it "should retrieve a url with :get" do
    response = @session.get("/test")
    body = YAML::load(response.body)
    body.request_method.should == "GET"
  end

  it "should include custom headers in a request" do
    response = @session.get("/test", {"User-Agent" => "PatronTest"})
    body = YAML::load(response.body)
    body.header["user-agent"].should == ["PatronTest"]
  end

  it "should merge custom headers with session headers" do
    @session.headers["X-Test"] = "Testing"
    response = @session.get("/test", {"User-Agent" => "PatronTest"})
    body = YAML::load(response.body)
    body.header["user-agent"].should == ["PatronTest"]
    body.header["x-test"].should == ["Testing"]
  end

  it "should raise an exception on timeout" do
    @session.timeout = 1
    lambda {@session.get("/timeout")}.should raise_error(Patron::TimeoutError)
  end

  it "should follow redirects by default" do
    @session.max_redirects = 1
    response = @session.get("/redirect")
    body = YAML::load(response.body)
    response.status.should == 200
    body.path.should == "/test"
  end

  it "should include redirect count in response" do
    @session.max_redirects = 1
    response = @session.get("/redirect")
    response.redirect_count.should == 1
  end

  it "should not follow redirects when configured to do so" do
    @session.max_redirects = 0
    response = @session.get("/redirect")
    response.status.should == 301
    response.body.should be_empty
  end

  it "should retrieve URL metadata with :head" do
    response = @session.head("/test")
    response.status.should == 200
    response.body.should be_empty
    response.headers.should_not be_empty
  end

  it "should send a delete request with :delete" do
    response = @session.delete("/test")
    body = YAML::load(response.body)
    body.request_method.should == "DELETE"
  end

  it "should upload data with :put" do
    data = "upload data"
    response = @session.put("/test", data)
    body = YAML::load(response.body)
    body.request_method.should == "PUT"
    body.header['content-length'].should == [data.size.to_s]
  end

  it "should upload data with :post" do
    data = "upload data"
    response = @session.post("/test", data)
    body = YAML::load(response.body)
    body.request_method.should == "POST"
    body.header['content-length'].should == [data.size.to_s]
  end

  it "should pass credentials as http basic auth" do
    @session.username = "foo"
    @session.password = "bar"
    response = @session.get("/test")
    body = YAML::load(response.body)
    body.header['authorization'].should == [encode_authz("foo", "bar")]
  end

  def encode_authz(user, passwd)
    "Basic " + Base64.encode64("#{user}:#{passwd}").strip
  end

end
