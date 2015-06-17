require "spec_helper"
require "ftpd"
require "tmpdir"
require "pathname"

describe "File transfers", feature: true do
  class Driver
    def initialize(temp_dir)
      @temp_dir = temp_dir
    end

    def authenticate(user, password)
      true
    end

    def file_system(user)
      Ftpd::DiskFileSystem.new(@temp_dir)
    end
  end

  def ftp_server(dir)
    Ftpd::FtpServer.new(Driver.new(dir))
  end

  before(:all) do
    @dir = Pathname Dir.mktmpdir
    @ftp_server = ftp_server(@dir.to_s)
    @ftp_server.port = 40_000
    @ftp_server.start
  end

  after(:all) do
    @ftp_server.stop
    FileUtils.rm_f @dir
  end

  context "for a local file" do
    let(:source) { @dir.join('foo') }
    let(:target) { "ftp://user:pass@localhost:#{@ftp_server.bound_port}/bar" }
    before do
      File.open(@dir.join('foo'), 'w') do |f|
        f << "foobar"
      end
    end

    it "transfers the file from one location to another" do
      post("/jobs", json: {source: source.to_s, target: target})

      sleep 1
      expect(File.read(@dir.join('bar')).chomp).to eq "foobar"
    end

  end

end
