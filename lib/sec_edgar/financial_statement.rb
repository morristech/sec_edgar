module SecEdgar

  class FinancialStatement
    attr_accessor :log, :rows, :name
  
    def initialize
      @rows = []
      @name = ""
    end
  
    def parse(edgar_fin_stmt)
      edgar_fin_stmt.children.each do |row_in| 
        if row_in.is_a? Hpricot::Elem
          row_out = []
          row_in.children.each do |cell_str|
            cell = Cell.new { |c| c.log = @log }
            cell.parse( String(cell_str.to_plain_text) )
            row_out.push(cell)
          end

          @rows.push(row_out)
        end
      end

      delete_empty_columns

      return true
    end
   
    def write_to_csv(filename=nil)
      filename = @name + ".csv" if filename.nil?
      f = File.open(filename, "w")
      @rows.each do |row|
        f.puts row.join("~")
      end
      f.close
    end
  
    def print
      puts
      puts @name
      @rows.each do |row|
        puts row.join("~")
      end
    end
  
    def merge(stmt2)
      # print each statement to a file
      [ [ @rows,      "/tmp/merge.1" ],
        [ stmt2.rows, "/tmp/merge.2" ] ].each do | cur_rows, cur_file |
        f = File.open(cur_file, "w")
        cur_rows.each do |row| 
          if !row[0].nil?
            f.puts(row[0].text) 
          end
        end
        f.close
      end
  
      # run an sdiff on it
      @diffs = []
      IO.popen("sdiff -w1 /tmp/merge.1 /tmp/merge.2") do |f|
        f.each { |line| @diffs.push(line.chomp) }
      end
      system("rm /tmp/merge.1 /tmp/merge.2")
      
      # paralellize the arrays, by inserting blank rows
      @diffs.each_with_index do |cur_diff,idx|
        if cur_diff == "<"
          new_row = [@rows[idx][0]]
          while new_row.length < stmt2.rows[idx].length
            new_row.push(Cell.new)
          end
          stmt2.rows.insert(idx,new_row)
        elsif cur_diff == ">"
          new_row = [stmt2.rows[idx][0]]
          while new_row.length < @rows[idx].length
            new_row.push(Cell.new)
          end
          @rows.insert(idx,new_row)
        else
        end
      end
  
      # merge them together
      @rows.size.times do |i|
        @rows[i].concat(stmt2.rows[i])
      end
    end

  private
 
    def delete_empty_columns

      last_col = @rows.collect{ |r| r.length }.max - 1

      # figure out how many times each column is actually filled in
      col_filled_count = (0..last_col).map do |col|
        col_filled = @rows.collect do |r|
          if (col < r.length) and (not r[col].empty?)
            1
          else
            0
          end
        end
        eval col_filled.join("+")
      end

      # define a threshold (must be filed in >50% of the time)
      min_filled_count = Integer(col_filled_count.max * 5/10)

      # delete each column that isn't sufficiently filled in
      Array(0..last_col).reverse.each do |idx|
        if col_filled_count[idx] < min_filled_count
          @log.debug("Column #{idx} - delete (#{col_filled_count[idx]} < #{min_filled_count})") if @log
          @rows.each { |r| r.delete_at(idx) }
        else
          @log.debug("Column #{idx} - keep (#{col_filled_count[idx]} >= #{min_filled_count})") if @log
        end
      end

    end
  end
  
end
