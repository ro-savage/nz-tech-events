class ChangeCityToOptionalInEvents < ActiveRecord::Migration[8.1]
  def change
    change_column_null :events, :city, true
    change_column_null :events, :region, true
  end
end
