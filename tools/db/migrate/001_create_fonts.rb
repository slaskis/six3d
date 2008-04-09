class CreateFonts < ActiveRecord::Migration
  def self.up
    create_table :fonts do |t|
    end
  end

  def self.down
    drop_table :fonts
  end
end
