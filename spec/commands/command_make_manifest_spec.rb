require "bosh/cli/commands/01_make_manifest"

describe Bosh::Cli::Command::Manifests do

  let(:command) { Bosh::Cli::Command::Manifests.new }
  let(:work_dir) { asset_dir("manifests-repo") }
  let(:manifest) { instance_double("Bosh::Manifests::DeploymentManifest") }
  let(:filename) { "foo" }
  let(:filename_path) { File.join(work_dir, "deployments", "#{filename}.yml") }
  let(:deployment_cmd) { instance_double("Bosh::Cli::Command::Deployment") }

  before do
    setup_home_dir
    command.add_option(:config, home_file(".bosh_config"))
    command.add_option(:non_interactive, true)
    command.stub(:work_dir).and_return(work_dir)
  end

  describe "#deployment" do
    subject { command.deployment(filename) }

    context "filename given" do
      let(:valid) { true }

      before do
        Bosh::Manifests::DeploymentManifest.should_receive(:new)
          .with(filename_path).and_return(manifest)
        manifest.should_receive(:valid?).and_return(valid)
      end

      it "sets current deployment" do
        Bosh::Cli::Command::Deployment.should_receive(:new)
          .and_return(deployment_cmd)
        deployment_cmd.should_receive(:add_option).twice
        deployment_cmd.should_receive(:set_current).with(filename)
        subject
      end

      context "validation errors" do
        let(:valid) { false }

        it "raises validation errors" do
          manifest.should_receive(:errors).and_return(%w[foo-error])
          command.should_receive(:say).with("Validation errors:")
          command.should_receive(:say).with("- foo-error")
          expect { subject }.to raise_error /is not valid/
        end
      end
    end

    context "no filename given" do
      let(:filename) { nil }

      it "returns current deployment" do
        Bosh::Cli::Command::Deployment.should_receive(:new)
          .and_return(deployment_cmd)
        deployment_cmd.should_receive(:add_option).twice
        deployment_cmd.should_receive(:set_current).with(filename)
        subject
      end
    end
  end

  describe "#prepare" do
    let(:name) { "foo" }
    let(:manifest_builder) { Bosh::Manifests::ManifestBuilder }

    xit "generates a manifest" do
      manifest_manager.should_receive(:find).with(name).and_return(manifest)
      manifest_builder.should_receive(:build).with(manifest, work_dir)
        .and_return("target_manifest")
      command.should_receive(:say).with(/build succesfull: 'target_manifest'/)
      command.prepare name
    end
  end

  describe "deploy" do
    it "deploy" do
      Bosh::Cli::Command::Deployment.should_receive(:new)
        .and_return(deployment_cmd)
      deployment_cmd.should_receive(:add_option).twice
      deployment_cmd.should_receive(:add_option).with(:recreate, true)
      deployment_cmd.should_receive(:perform)
      command.add_option(:recreate, true)
      command.deploy
    end
  end
end
