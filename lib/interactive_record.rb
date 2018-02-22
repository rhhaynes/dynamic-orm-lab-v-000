require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord
  
  def self.table_name
    self.to_s.downcase.pluralize
  end
  
  def self.column_names
    DB[:conn].results_as_hash = true
    sql = "PRAGMA table_info(#{table_name})"
    table_info = DB[:conn].execute(sql)
    names = []
    table_info.each do |row_hash|
      names << row_hash["name"]
    end
    names.compact
  end
  
  def self.find_by(attributes)
    binding.pry
    sql = "SELECT * FROM #{table_name} WHERE #{attributes.keys[0]} = ?"
    DB[:conn].execute(sql,attributes.values[0]).flatten
  end
  
  def self.find_by_name(name)
    sql = "SELECT * FROM #{table_name} WHERE name = ?"
    DB[:conn].execute(sql, name).flatten
  end
  
  def initialize(attributes={})
    attributes.each { |k,v| self.send("#{k}=",v) }
  end
  
  def save
    sql = <<~SQL.gsub("\n"," ")
      INSERT INTO #{table_name_for_insert} (#{col_names_for_insert})
      VALUES (#{values_for_insert})
    SQL
    DB[:conn].execute(sql)
    
    sql = "SELECT last_insert_rowid() FROM #{table_name_for_insert}"
    self.id = DB[:conn].execute(sql)[0][0]
  end
  
  def table_name_for_insert
    self.class.table_name
  end
  
  def col_names_for_insert
    self.class.column_names.delete_if{|name| name == "id"}.join(", ")
  end
  
  def values_for_insert
    values = []
    self.col_names_for_insert.split(", ").each do |name|
      values << "'#{self.send(name)}'"
    end
    values.join(", ")
  end
  
end