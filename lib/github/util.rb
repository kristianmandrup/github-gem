module GitHub
  class Util
    attr_accessor :options
  
    def initialize(opts = {})
      @options = opts || {}
    end

    def maxes(lines)
      max = {}            
      lines[0].keys.each do |k|
        max[k] = lines.sort_by {|line| line[k].size}.last[k].size
      end 
      max
    end

    def short_max_length_hash 
      {:branch => 30, :email => 21, :message => 30, :time_ago => 15}                  
    end
    
    def default_max_length_hash
      {:branch => 40, :email => 40, :message => 50, :time_ago => 25}      
    end
    
    def max_length_hash
      @max_length_hash ||= options[:short] ? short_max_length_hash : default_max_length_hash
    end

    def line_parts(line, max_hash, custom_max_length_hash = {})
      trunced_line_parts = {}
      max_hash.each_key do |k|
        line_part = line[k]
        line_part = truncate(line_part, :length => max_length_hash.merge(custom_max_length_hash))
        trunced_line_parts[k] = line_part.ljust(max_hash[k])
      end
      trunced_line_parts
    end
  
    def commit_line sha, ref_name, commit
      {
        :sha => sha,
        :branch => ref_name,
        :email => commit[1],
        :message => commit[2],
        :time_ago => commit[3],
      }
    end

    def truncate(text, opt = {})
      opt = {:length => 30, :omission => "..."}.merge(opt)
      if text
        l = opt[:length] - opt[:omission].length
        chars = text
        (chars.length > opt[:length] ? chars[0...l] + opt[:omission] : text).to_s
      else
        ""
      end
    end
  
  end
end