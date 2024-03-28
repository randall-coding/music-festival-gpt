class CreateQueryLogs < ActiveRecord::Migration[6.1]
  def change
    create_table :query_logs do |t|
      t.text :query_text
      t.text :qerry_result

      t.timestamps
    end
  end
end
