class HitTypeValidator < ActiveModel::Validator

  def validate(record)
    # If two records have exactly the same properties we won't be able to create a new HIT type.
    # Having tasks which share the same HIT type destroy logic such as reviewing or qualifications


    fields = [:title, :description, :keywords, :reward, :assignment_duration_in_seconds, :auto_approval_delay_in_seconds, :minimal_approval_rate]
    
    match_records = MturkBatchJob.where(Hash[fields.map{|f| [f, record[f]]}])
    p match_records
    p Hash[fields.map{|f| [f, record[f]]}]
    match_records.each do |match_record|
      if match_record.status != 'completed'
        record.errors[:base] << "The parameters given for the fields '#{fields.map(&:to_s).join(', ')}' match the pre-existing Mturk batch job '#{match_record.name}'. This means that the current job will generate the same HIT type ID which causes problems down the line."
        return
      end
    end
  end


  private
end
