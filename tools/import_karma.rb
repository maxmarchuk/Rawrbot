#!/usr/bin/env ruby
# ==============================================================================
# Import Karma
# ==============================================================================
#
# Import karma information from a flat file into a sqlite3 database. This script
# will replace any duplicate key information in the database with information
# from the flat file. In other words, it assumes the flat file is authoritative.
# Takes two command-line arguments.
#
# The first argument is the path to the flat file which contains the karma
# information to import into the database. The file should be formatted as a
# series of key-value pairs, separated by a delimiter. Only one key-value pair
# should exist per line. For example:
#
# foo => 30
# bar => -1
#
# The delimiter can be edited here:
#
delimiter = ' => '
#
# The second argument is the path to the sqlite database file to which you would
# like to import karma information. Be sure the bot is not running and using
# that database when you begin importing data.

require 'sqlite3'

source = ARGV[0]
target = ARGV[1]

# Check if input file exists.
if !(File.exists?(source))
  abort("Source file #{source} not found. Aborting.\n")
end

# Initialize database.
db = SQLite3::Database.new(target)
db.execute("CREATE TABLE IF NOT EXISTS karma(
              obj TEXT PRIMARY KEY,
              val INTEGER)")

# Import data into database.
puts("Importing...")
File.open(source, 'r:UTF-8') do |file|
  while (line = file.gets)
    begin
      line.delete!("\r","\n")
      line =~ /(.+)#{delimiter}(.+)/i 
    rescue => e
      warn("Failed to parse line. Error: #{e}\nLine: #{line}")
      break
    end
    key = $1
    val = $2
    r = db.get_first_value("SELECT val FROM karma WHERE obj=?", key)
    begin
      if (r.nil?)
        # Element does not yet exist in the db; insert it.
        db.execute("INSERT INTO karma (obj,val) VALUES (?,?)", key, val)
      else
        # Element already exists in the db; update it.
        db.execute("UPDATE karma SET val=? WHERE obj=?", val, key)
      end
    rescue => e
      warn("Failed to insert data. Error: #{e}\nLine: #{line}")
      break
    end
  end
end
puts("Done.")
