require 'spec_helper'
require 'gemjars/deux/specifications'

include Gemjars::Deux

describe Specifications do
  let(:specifications) { Specifications.new(specs) }
  let(:specs) { [["zzzzzz", Gem::Version.new("0.0.3"), "ruby"]] }
  
  it "should have number_of_releases" do
    specifications.number_of_releases("zzzzzz").should == 1
  end

  it "should have zero releases" do
    specifications.number_of_releases("foobar").should == 0
  end

  it "should have size" do
    specifications.size.should == 1
  end

  it "should have a single spec" do
    specifications["zzzzzz"].should == Set.new([Specification.new("zzzzzz", "0.0.3", "ruby")])
  end

  it "should be enumerable" do
    specifications.to_enum(:each).to_a.should == [Specification.new("zzzzzz", "0.0.3", "ruby")]
  end

  it "should be a set addition" do
    (specifications + specifications).should == specifications
  end

  it "should allow adding additional specifications" do
    version1 = ["abc", Gem::Version.new("0.0.1"), "ruby"]
    version2 = ["abc", Gem::Version.new("0.0.2"), "ruby"]
    (Specifications.new([version1]) + Specifications.new([version2])).should == Specifications.new([version1, version2])
  end

  context "from channel" do
    let(:specifications) { Specifications.from_channel(Streams.to_channel(Java::JavaIo::ByteArrayInputStream.new(io.to_java_bytes))) }
    let(:io) { Marshal.dump([["zzzzzz", Gem::Version.new("0.0.3"), "ruby"]]) }

    it "should have specifcations" do
      specifications["zzzzzz"].should == Set.new([Specification.new("zzzzzz", "0.0.3", "ruby")])
    end
  end

  context "many versions for gem" do
    let(:specs) { [
      ["zzzzzz", Gem::Version.new("0.3"), "ruby"],
      ["zzzzzz", Gem::Version.new("1.0"), "ruby"],
      ["zzzzzz", Gem::Version.new("0.2"), "ruby"]
    ]}
    
    it "should return the satisfactory spec for gem" do
      specifications.satisfactory_spec("zzzzzz", "~> 0.1").should == Specification.new("zzzzzz", "0.2", "ruby")
    end

    it "should return nil for unknown gem" do
      specifications.satisfactory_spec("foobar", "~> 0.1").should be_nil
    end

    it "should return nil for unknown gem version" do
      specifications.satisfactory_spec("zzzzzz", "~> 7.0").should be_nil
    end
    
    it "should have size" do
      specifications.size.should == 3
    end

    it "should be enumerable" do
      specifications.to_enum(:each).to_a.should == [
        Specification.new("zzzzzz", "0.3", "ruby"),
        Specification.new("zzzzzz", "1.0", "ruby"),
        Specification.new("zzzzzz", "0.2", "ruby")
      ]
    end

    it "should have number_of_releases" do
      specifications.number_of_releases("zzzzzz").should == 3
    end
  end

  context "many platforms for the same version" do
    let(:specs) { [
      ["zzzzzz", Gem::Version.new("0.2"), "ruby"],
      ["zzzzzz", Gem::Version.new("0.1"), "ruby"],
      ["zzzzzz", Gem::Version.new("0.1"), "java"],
      ["zzzzzz", Gem::Version.new("0.1"), "x86-mswin32"],
      ["zzzzzz", Gem::Version.new("0.3"), "x86-mswin32"]
    ]}

    it "should not include anything not java or ruby" do
      specifications.should_not include Specification.new("zzzzzz", "0.1", "x86-mswin32")
    end

    it "should not include ruby in the presense of java" do
      specifications.should_not include Specification.new("zzzzzz", "0.1", "ruby")
    end

    it "should include only java" do
      specifications.should include Specification.new("zzzzzz", "0.1", "java")
    end

    it "should include ruby when no java available for that version" do
      specifications.should include Specification.new("zzzzzz", "0.2", "ruby")
    end

    it "should never include non java or ruby even if only one available" do
      specifications.should_not include Specification.new("zzzzzz", "0.3", "x86-mswin32")
    end
  end
end
