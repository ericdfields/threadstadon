class AddStatusToStatuses < ActiveRecord::Migration[7.0]
  def change
    add_reference :statuses, :status
  end
end
