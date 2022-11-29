# frozen_string_literal: true

require "rails_helper"

describe PipelineApi do
  describe "#check_samples_status" do
    let(:mock_class) { Class.new.extend(described_class) }
    let(:subject) { mock_class.check_samples_status(project_name_argument) }

    let(:project_name_argument) { project_1.name }
    let(:project_1_name) { "vaccine_sentiment" }
    let(:project_1) { create(:project, name: project_1_name) }
    let(:mturk_batch_job_1_creation_time) { "2022-01-01T08:06:00Z" }
    let!(:mturk_batch_job_1) { create(:mturk_batch_job, :with_auto, project: project_1, created_at: mturk_batch_job_1_creation_time) }

    let(:s3_filename_prefix) { "other/csv/automatic-samples/project_#{project_1.name}/auto_sample-no_text-#{project_1.name}" }
    let(:s3_file_1_key) { "#{s3_filename_prefix}-20220101080500-#{Digest::SHA2.hexdigest("file1")}.csv" }
    let(:s3_file_2_key) { "#{s3_filename_prefix}-20220101080700-#{Digest::SHA2.hexdigest("file2")}.csv" }
    let(:s3_file_1_data) { "1\n2\n3\n" }
    let(:s3_file_2_data) { "4\n6\n9\n" }
    let(:s3_client) {
      Aws::S3::Client.new(stub_responses: {
        list_objects_v2: {contents: [{key: s3_file_1_key}, {key: s3_file_2_key}]},
        get_object: lambda do |inst|
          case inst.params.fetch(:key)
          when s3_file_1_key
            {body: s3_file_1_data}
          when s3_file_2_key
            {body: s3_file_2_data}
          end
        end
      })
    }

    before { allow(Aws::S3::Client).to receive(:new).and_return(s3_client) }

    context "when there have never been batch jobs" do
      before { MturkBatchJob.destroy_all }

      it do
        expect { subject }.to raise_error(NoMethodError)
      end
    end

    context "when name argment matches no project" do
      let(:project_name_argument) { "bad_name" }

      it do
        expect(subject.status).to eq(:error)
        expect(subject.message).to eq("Sample files not found for project '#{project_1.name}'.")
      end
    end

    context "when job was created after all files" do
      let(:mturk_batch_job_1_creation_time) { "2022-01-01T08:08:00Z" }

      it do
        expect(subject.status).to eq(:error)
        expect(subject.message).to eq("Sample files not found for project '#{project_1.name}'.")
      end
    end

    context "when everything is nominal" do
      it do
        expect(subject.status).to eq(:success)
        expect(subject.body).to contain_exactly({sample_s3_key: s3_file_2_key, job_file: s3_file_2_data})
      end
    end

    context "when project name has a hyphen" do
      let(:project_1_name) { "vaccine-sentiment" }

      it do
        expect(subject.status).to eq(:success)
        expect(subject.body).to contain_exactly({
          sample_s3_key: "other/csv/automatic-samples/project_vaccine-sentiment/auto_sample-no_text-vaccine-sentiment-20220101080700-#{Digest::SHA2.hexdigest("file2")}.csv",
          job_file: s3_file_2_data
        })
      end
    end

    context "when job was created before all files" do
      let(:mturk_batch_job_1_creation_time) { "2022-01-01T08:00:00Z" }

      it do
        expect(subject.status).to eq(:success)
        expect(subject.body).to contain_exactly(
          {sample_s3_key: s3_file_1_key, job_file: s3_file_1_data},
          {sample_s3_key: s3_file_2_key, job_file: s3_file_2_data}
        )
      end
    end

    # Due to the the module using a class variable that we want to spoof, we force it here as the last action before the `it` block.
    before { described_class.class_variable_set(:@@s3_client, s3_client) }
  end
end
