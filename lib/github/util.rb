module GitHub
  class Util
    attr_accessor :options
  
    def initilialize(options = {})
      @options = options || {}
    end
  
    def commit_line sha, ref_name, commit
      {
        :sha => commit_entry(sha, :length => 6), 
        :branch => commit_entry(ref_name, :ljust => 25), 
        :email => commit_entry(commit[1], :length => 30, :ljust => 31, :max_length => 21),
        :message => commit_entry(commit[2], :length => 50, :ljust => 52, :max_length => 30),
        :time_ago => commit_entry(commit[3], :length => 25, :max_length => 15)
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

    def commit_entry(entry, opt = {})
      entry = entry[0, opt[:length]] if opt[:length]
      entry = truncate(entry, :length => opt[:max_length]) if options && options[:short] && opt[:max_length]
      entry = entry.ljust opt[:ljust] if opt[:ljust]
      entry
    end
  
  end
end