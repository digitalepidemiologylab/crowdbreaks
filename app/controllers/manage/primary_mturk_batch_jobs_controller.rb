module Manage
  class PrimaryMturkBatchJobsController < BaseController
    # There's not gonna be an index page for that, it will be shown in MturkAutoController
    def index; end

    # Also in MturkAutoController
    def new; end

    # Should be automatic after creating a project
    # nullable, only read for the projects that have mturk_auto: true
    def create; end

    # The form from MturkAutoController should come in here
    # OR put this method directly to MturkAutoController
    def update; end

    # Should be automatically destroyed upon destroying the corresponding mturk batch job
    def destroy; end
  end
end
