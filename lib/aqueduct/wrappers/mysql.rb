require 'aqueduct'

module Aqueduct
  module Wrappers
    class Mysql
      include Aqueduct::Wrapper

      def sql_codes
        { text: 'CHAR(255)', numeric: nil, open: '`', close: '`' } # Using "5.4" + 0.0 to convert
      end

      def connect
        @db_connection = Mysql2::Client.new(host: @source.host, username: @source.username, password: @source.password, database: @source.database, port: @source.port)
      end

      def disconnect
        @db_connection.close if @db_connection
        true
      end

      def query(sql_statement)
        results = []
        total_count = 0
        if @db_connection
          results = @db_connection.query(sql_statement, as: :array)
          total_count = results.each.size
        end
        [results, total_count]
      end

      def connected?
        result = false
        error = ''
        begin
          db_connection = Mysql2::Client.new(host: @source.host, username: @source.username, password: @source.password, database: @source.database, port: @source.port)
        rescue Mysql2::Error => e
          error = "#{e.errno}: #{e.error}"
        ensure
          result = true if db_connection
          db_connection.close if db_connection
        end
        { result: result, error: error }
      end

      def get_table_metadata
        result = {}
        error = ''
        begin
          db_connection = Mysql2::Client.new(host: @source.host, username: @source.username, password: @source.password, database: @source.database, port: @source.port)
          if db_connection
            tables = []
            results = db_connection.query("SHOW TABLES;")
            results.each do |row|
              row.values.each do |table|
                tables << table
              end
            end

            tables.sort{|table_a, table_b| table_a.downcase <=> table_b.downcase}.each do |my_table|
              results = db_connection.query("SHOW COLUMNS FROM #{my_table}")
              columns = []
              results.each do |row|
                columns << {column: row['Field'], datatype: row['Type']}
              end
              result[my_table] = columns.sort{|a,b| a[:column].downcase <=> b[:column].downcase}
            end
          end
        rescue Mysql2::Error => e
          error = "#{e.errno}: #{e.error}"
        ensure
          db_connection.close if db_connection
        end
        { result: result, error: error }
      end

      def tables
        tables = []
        error = ''
        begin
          db_connection = Mysql2::Client.new(host: @source.host, username: @source.username, password: @source.password, database: @source.database, port: @source.port)
          if db_connection
            results = db_connection.query("SHOW TABLES;")
            results.each do |row|
              row.values.each do |table|
                tables << table
              end
            end
          end
        rescue Mysql2::Error => e
          error = "#{e.errno}: #{e.error}"
        ensure
          db_connection.close if db_connection
        end
        { result: tables, error: error }
      end

      def table_columns(table)
        columns = []
        error = ''
        begin
          db_connection = Mysql2::Client.new(host: @source.host, username: @source.username, password: @source.password, database: @source.database, port: @source.port)
          if db_connection
            results = db_connection.query("SHOW COLUMNS FROM #{table}")
            results.each { |row| columns << {column: row['Field'], datatype: row['Type']} }
          end
        rescue Mysql2::Error => e
          error = "Error retrieving column information. Please make sure that this database is configured correctly."
        ensure
          db_connection.close if db_connection
        end
        { columns: columns, error: error }
      end

      def get_all_values_for_column(table, column)
        values = []
        error = ''
        begin
          db_connection = Mysql2::Client.new(host: @source.host, username: @source.username, password: @source.password, database: @source.database, port: @source.port)
          if db_connection
            column_found = false
            db_connection.query("DESCRIBE #{table}").each do |field|
              column_found = true if field['Field'] == column
            end
            if not column_found
              result += " <i>#{column}</i> does not exist in <i>#{@source.database}.#{table}</i>"
            else
              results = db_connection.query("SELECT `#{column}` FROM #{table};")
              results.each do |row|
                row.values.each do |value|

                  if value.class != String and value.respond_to?('round') and value.round == value
                    values << value.round
                  else
                    values << value
                  end
                end
              end
            end
          end
        rescue Mysql2::Error => e
          error = "#{e.errno}: #{e.error}"
        ensure
          if db_connection
            db_connection.close
          else
            error += " unable to connect to <i>#{@source.name}</i>"
          end
        end
        { values: values, error: error }
      end

      def column_values(table, column)
        error = ''
        result = []
        begin
          db_connection = Mysql2::Client.new(host: @source.host, username: @source.username, password: @source.password, database: @source.database, port: @source.port)
          column_found = false
          db_connection.query("DESCRIBE #{table}").each do |field|
            column_found = true if field['Field'] == column
          end
          if column_found
            results = db_connection.query("SELECT `#{column}` as 'column', count(*) FROM #{table} GROUP BY `#{column}`;")
            results.each do |row|
              if row['column'].class != String and row['column'].respond_to?('round') and row['column'].round == row['column']
                result << row['column'].round
              else
                result << row['column']
              end
            end
          end
        rescue Mysql2::Error => e
          error = "Error: #{e.inspect}"
        ensure
          db_connection.close if db_connection
        end
        { result: result, error: error }
      end

      def count(query_concepts, conditions, tables, join_conditions, concept_to_count)
        result = 0
        error = ''
        sql_conditions = ''
        begin
          t = Time.now
          if tables.size > 0
            sql_conditions = "SELECT count(#{concept_to_count ? 'DISTINCT ' + concept_to_count : '*'}) as record_count FROM #{tables.join(', ')} WHERE #{join_conditions.join(' and ')}#{' and ' unless join_conditions.blank?}#{conditions}"
            Rails.logger.info sql_conditions
            db_connection = Mysql2::Client.new(host: @source.host, username: @source.username, password: @source.password, database: @source.database, port: @source.port)
            if db_connection
              results = db_connection.query(sql_conditions)
              results.each do |row|
                result = row['record_count']
              end
            end
          else
            error = "Database [#{@source.name}] Error: No tables for concepts. Database not fully mapped."
          end
        rescue Mysql2::Error => e
          error = "Database [#{@source.name}] Error: #{e}"
        ensure
          db_connection.close if db_connection
        end
        { result: result, error: error, sql_conditions: sql_conditions }
      end
    end
  end
end