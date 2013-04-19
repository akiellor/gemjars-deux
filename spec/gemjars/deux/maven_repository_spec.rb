require 'spec_helper'
require 'gemjars/deux/maven_repository'
require 'timeout'

include Gemjars::Deux

RSpec::Matchers.define :be_an_io_with do |content|
  match do |io|
    Timeout::timeout(1) do
      @out = StringIO.new
      while chunk = io.read(1024)
        @out << chunk
      end
      @out.string == content
    end
  end

  failure_message_for_should do |io|
    "expected io to have content #{content.inspect} but had #{@out.string.inspect}"
  end
end

describe MavenRepository do
  let(:repository) { MavenRepository.new(store) }
  let(:store) { mock(:store) }

  it "should put jar, md5 and sha1 into store" do
    jar_r, jar_w = IO.pipe 
    md5_r, md5_w = IO.pipe 
    sha1_r, sha1_w = IO.pipe 

    store.stub(:put).with("org/rubygems/foo/1/foo-1.jar", :content_type => "application/java-archive") { jar_w }
    store.stub(:put).with("org/rubygems/foo/1/foo-1.jar.md5", :content_type => "text/plain") { md5_w }
    store.stub(:put).with("org/rubygems/foo/1/foo-1.jar.sha1", :content_type => "text/plain") { sha1_w }

    io = repository.pipe_to("foo", "1")

    io << "foo\n"
    io.close

    jar_r.should be_an_io_with("foo\n")
    jar_w.should be_closed
    md5_r.should be_an_io_with("d3b07384d113edec49eaa6238ad5ff00")
    md5_w.should be_closed
    sha1_r.should be_an_io_with("f1d2d2f924e986ac86fdf7b36c94bcdf32beec15")
    sha1_w.should be_closed
    io.should be_closed
  end
end
