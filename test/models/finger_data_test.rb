require 'minitest/autorun'
require 'mocha/setup'

require_relative '../../app/models/finger_data'

describe FingerData do
  describe ".initialize" do
    let(:xrd) { mock }

    it "assigns the extensible resource descriptor (XRD)" do
      FingerData.new(xrd).instance_variable_get("@xrd").must_equal xrd
    end
  end

  describe "#url" do
    let(:xrd) { mock }
    describe "when data is present" do
      before do
        xrd.stubs(:links).returns([{"rel"  => "http://schemas.google.com/g/2010#updates-from",
                                    "href" => "https://rstat.us/feeds/505...22c.atom"}])
      end

      it "gets the updates-from google finger data" do
        FingerData.new(xrd).url.must_equal "https://rstat.us/feeds/505...22c.atom"
      end
    end

    describe "when data cannot be found" do
      before do
        xrd.stubs(:links).returns([])
      end

      it "returns a blank string" do
        FingerData.new(xrd).url.must_equal ""
      end
    end
  end

  describe "#public_key" do
    let(:xrd) { mock }
    describe "when data is present" do
      before do
        xrd.stubs(:links).returns([{"rel"  => "magic-public-key",
                                    "href" => "data:application/magic-public-key,RSA.qHXlBk2so..."}])
      end

      it "gets the magic-public-key data" do
        FingerData.new(xrd).public_key.must_equal "RSA.qHXlBk2so..."
      end
    end

    describe "when data cannot be found" do
      before do
        xrd.stubs(:links).returns([])
      end

      it "returns a blank string" do
        FingerData.new(xrd).public_key.must_equal ""
      end
    end
  end

  describe "#salmon_url" do
    let(:xrd) { mock }
    describe "when data is present" do
      before do
        xrd.stubs(:links).returns([{"rel"  => "salmon",
                                    "href" => "https://rstat.us/feeds/505...22c/salmon"}])
      end

      it "gets the salmon data" do
        FingerData.new(xrd).salmon_url.must_equal "https://rstat.us/feeds/505...22c/salmon"
      end
    end

    describe "when data cannot be found" do
      before do
        xrd.stubs(:links).returns([])
      end

      it "returns a blank string" do
        FingerData.new(xrd).salmon_url.must_equal ""
      end
    end
  end
end
