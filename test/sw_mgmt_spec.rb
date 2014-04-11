#! /usr/bin/env rspec

require_relative "spec_helper"
require_relative "yast_stubs"

describe "Registration::SwMgmt" do
  let(:yast_pkg) { double("Yast::Pkg") }

  before do
    stub_yast_require
    require "registration/sw_mgmt"

    stub_const("Yast::Pkg", yast_pkg)
  end

  describe ".service_repos" do
    let(:services) { double }
    let(:service_name) { "SLES" }
    let(:repos) do
      {
        # installation repository, not from registration
        0 => {
          "alias"=>"SLES12", "autorefresh"=>false,
          "base_urls"=>["cd:///"],
          "enabled"=>true, "is_update_repo"=>false, "keeppackages"=>false,
          "mirror_list"=>"", "name"=>"SLES12", "priority"=>99, "product_dir"=>"",
          "service"=>"", "type"=>"SUSE",
          "url"=>"cd:///"
        },
        # pool repo from service
        1 => {
          "alias"=>"SLES:SLES12-Pool", "autorefresh"=>true,
          "base_urls"=>["https://nu.novell.com/suse/x86_64/update/SLE-SERVER/12-POOL"],
          "enabled"=>true, "is_update_repo"=>false, "keeppackages"=>false,
          "mirror_list"=>"", "name"=>"SLES12-Pool", "priority"=>99, "product_dir"=>"",
          "service"=>service_name, "type"=>"YUM",
          "url"=>"https://nu.novell.com/suse/x86_64/update/SLE-SERVER/12-POOL"
        },
        # update repo from service
        2 => {
          "alias"=>"SLES:SLES12-Updates", "autorefresh"=>true,
          "base_urls"=>["https://nu.novell.com/suse/x86_64/update/SLE-SERVER/12"],
          "enabled"=>true, "is_update_repo"=>false, "keeppackages"=>false,
          "mirror_list"=>"", "name"=>"SLES12-Updates", "priority"=>99, "product_dir"=> "",
          "service"=>service_name, "type"=>"YUM",
          "url"=>"https://nu.novell.com/suse/x86_64/update/SLE-SERVER/12"
        },
        # update repo from a different service
        3 => {
          "alias"=>"Another:SLES12-Updates", "autorefresh"=>true,
          "base_urls"=>["https://nu.novell.com/suse/x86_64/update/SLE-SERVER/12"],
          "enabled"=>true, "is_update_repo"=>false, "keeppackages"=>false,
          "mirror_list"=>"", "name"=>"SLES12-Updates", "priority"=>99, "product_dir"=> "",
          "service"=> "Another", "type"=>"YUM",
          "url"=>"https://nu.novell.com/suse/x86_64/update/SLE-SERVER/12"
        }
      }
    end

    before do
      service = double
      expect(service).to receive(:name).and_return(service_name)
      expect(services).to receive(:services).and_return([service])

      expect(yast_pkg).to receive(:SourceGetCurrent).with(false).and_return(repos.keys)
      repos.each do |id, repo|
        expect(yast_pkg).to receive(:SourceGeneralData).with(id).and_return(repo)
      end
    end

    it "returns list of repositories belonging to a service" do
      expect(Registration::SwMgmt.service_repos([services])).to eq([repos[1], repos[2]])
    end

    it "optionally returns only update repositories" do
      expect(Registration::SwMgmt.service_repos([services], only_updates: true)).to eq([repos[2]])
    end
  end

  describe ".base_product_to_register" do
    it "returns base product base version and release_type" do
      expect(Registration::SwMgmt).to receive(:find_base_product)
        .and_return({"name" => "SLES", "arch" => "x86_64", "version" => "12.1-1.47",
            "flavor" => "DVD"})

      expect(Registration::SwMgmt.base_product_to_register).to eq({"name" => "SLES",
          "arch" => "x86_64", "version" => "12.1", "release_type" => "DVD"})
    end
  end

end
