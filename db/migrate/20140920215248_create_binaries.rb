class CreateBinaries < ActiveRecord::Migration
  def up()
    create_table(:binaries, :id => false)  do |t|
      t.string(:id, :limit => 36, :primary => true, :null => false)
      t.string(:name)
      t.string(:filename)
      t.integer(:parent_id)
      t.text(:comment)

      t.timestamps()
    end
  end

  def down()
    drop_table :binaries
  end
end