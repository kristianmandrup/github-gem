DEV_NULL = File.exist?("/dev/null") ? "/dev/null" : "nul:" unless const_defined?("DEV_NULL")

# merged patches: 
# http://github.com/dominikh/github-gem/commit/3756a55c840ddbaef60d596250372e51faf07afc
# http://github.com/snowblink/github-gem/commit/3726b5e0f1f1129e41550f753e1d2207a3f5063c
# http://github.com/barryk/github-gem/commit/6925e60733f1665d6d676454489d3084077a0d9d

helper :user_and_repo_from do |url|
  case url
  # when %r|^git://github\.com/([^/]+/[^/]+)$|: $1.split('/')
  # when %r|^(?:ssh://)?(?:git@)?github\.com:([^/]+/[^/]+)$|: $1.split('/')   
  when %r|^http://github\.com/([^/]+/[^/]+)$| 
    $1.split('/')
  when %r|^(?:git\+ssh://)?(?:git@)?github\.com/([^/]+/[^/]+)$| 
    $1.split('/')
  when %r|^git://github\.com/([^/]+/[^/]+)$|   
    $1.split('/')
  when %r|^(?:ssh://)?(?:git@)?github\.com:([^/]+/[^/]+)$|
    $1.split('/')   
  end
end

helper :mainline_repo do |*new_mainline|
    mainline_config = `git config --get-regexp '^remote\..*\.mainline$' true`;
    mainline_config =~ /^remote\.(.*)\.mainline true/;
    mainline = $1;

    if not new_mainline.nil? and not new_mainline.empty?
        system("git config --unset-all remote.#{mainline}.mainline") if mainline
        system("git config --add remote.#{new_mainline}.mainline true")
        mainline = new_mainline
    end

    mainline = "origin" if mainline.nil?
    return mainline
end

helper :user_and_repo_for do |remote|
  user_and_repo_from(url_for(remote))
end

helper :user_for do |remote|
  user_and_repo_for(remote).try.first
end

helper :repo_for do |remote|
  user_and_repo_for(remote).try.last
end

helper :origin do
  orig = `git config --get github.origin`.chomp
  orig = nil if orig.empty?
  orig || 'origin'
end

helper :project do
  repo = repo_for(origin)
  if repo.nil?
    if url_for(origin) == ""
      STDERR.puts "Error: missing remote 'origin'"
    else
      STDERR.puts "Error: remote 'origin' is not a github URL"
    end
    exit 1
  end
  repo.chomp('.git')
end

helper :url_for do |remote|
  `git config --get remote.#{remote}.url`.chomp
end

helper :local_heads do
  `git show-ref --heads --hash`.split("\n")
end

helper :has_commit? do |sha|
  `git show #{sha} >#{DEV_NULL} 2>#{DEV_NULL}`
  $?.exitstatus == 0
end

helper :resolve_commits do |treeish|
  if treeish
    if treeish.match(/\.\./)
      commits = `git rev-list #{treeish}`.split("\n")
    else
      commits = `git rev-parse #{treeish}`.split("\n")
    end
  else
    # standard in
    puts 'reading from stdin...'
    commits = $stdin.read.split("\n")
  end
  commits.select { |a| a.size == 40 } # only the shas, not the ^SHAs
end

helper :ignore_file_path do
  dir = `git rev-parse --git-dir`.chomp
  File.join(dir, 'ignore-shas')
end

helper :ignore_sha_array do
  File.open( ignore_file_path ) { |yf| YAML::load( yf ) } rescue {}
end

helper :remove_ignored do |array, ignore_array|
  array.reject { |id| ignore_array[id] }
end

helper :ignore_shas do |shas|
  ignores = ignore_sha_array
  shas.each do |sha|
    puts 'ignoring ' + sha
    ignores[sha] = true
  end
  File.open( ignore_file_path, 'w' ) do |out|
    YAML.dump( ignores, out )
  end
end

helper :get_commits do |rev_array|
  list = rev_array.select { |a| has_commit?(a) }.join(' ')
  `git log --pretty=format:"%H::%ae::%s::%ar::%ad" --no-merges #{list}`.split("\n").map { |a| a.split('::') }
end

helper :get_cherry do |branch|
  `git cherry HEAD #{branch} | git name-rev --stdin`.split("\n").map { |a| a.split(' ') }
end

helper :get_common do |branch|
  `git rev-list ..#{branch} --boundary | tail -1 | git name-rev --stdin`.split(' ')[1] rescue 'unknown'
end

helper :print_commits do |our_commits, options|
  ignores = ignore_sha_array

  case options[:sort]
  when 'branch'
    our_commits.sort! { |a, b| a[0][2] <=> b[0][2] }
  when 'author'
    our_commits.sort! { |a, b| a[1][1] <=> b[1][1] }
  else
    our_commits.sort! { |a, b| Date.parse(a[1][4]) <=> Date.parse(b[1][4]) } rescue 'cant parse dates'
  end

  shown_commits = {}
  before = Date.parse(options[:before]) if options[:before] rescue puts 'cant parse before date'
  after = Date.parse(options[:after]) if options[:after] rescue puts 'cant parse after date'
  our_commits.each do |cherry, commit|
    status, sha, ref_name = cherry
    ref_name ||= ""
    next if shown_commits[sha] || ignores[sha]
    next if options[:project] && !ref_name.match(Regexp.new(options[:project]))
    ref_name = ref_name.gsub('remotes/', '')
    if status == '+' && commit
      next if options[:author] && !commit[1].match(Regexp.new(options[:author]))
      next if options[:before] && before && (before < Date.parse(commit[4]))  rescue false
      next if options[:after] && after && (after > Date.parse(commit[4])) rescue false
      applies = applies_cleanly(sha)
      next if options[:applies] && !applies
      next if options[:noapply] && applies
      if options[:shas]
        puts sha
      else
        common = options[:common] ? get_common(sha) : ''
        line = commit_line(sha, ref_name, commit)
        puts "#{line[:sha]} #{line[:branch]} #{truncate(line[:email], 21)} #{truncate(line[:message], 30)} #{truncate(line[:time_ago], 15)}" if options[:short]
        puts "#{line[:sha]} #{line[:branch]} #{line[:email]} #{line[:message]} #{line[:time_ago]}" if !options[:short]        
      end                                                            
    end                                                              
    shown_commits[sha] = true                                        
  end                                                                
end

helper :truncate do |text, length|
  end_string = ' …'
  return "" if text == nil
  words = text.split()
  words[0..(length-1)].join(' ') + (words.length > length ? end_string : '')
end

helper :commit_line do |sha, ref_name, commit|
  {:sha => sha[0,6], :branch => ref_name.ljust(25), :email => commit[1][0,30].ljust(31), :message => commit[2][0, 50].ljust(52), :time_ago => commit[3][0,25]}
end

helper :applies_cleanly do |sha|
  `git diff ...#{sha} | git apply --check >#{DEV_NULL} 2>#{DEV_NULL}`
  $?.exitstatus == 0
end

helper :remotes do
  regexp = '^remote\.(.+)\.url$'
  `git config --get-regexp '#{regexp}'`.split("\n").inject({}) do |memo, line|
    name_string, url = line.split(/ /, 2)
    m, name = *name_string.match(/#{regexp}/)
    memo[name.to_sym] = url
    memo
  end
end

helper :remote_branches_for do |user|
  `git ls-remote -h #{user} 2> #{DEV_NULL}`.split(/\n/).inject({}) do |memo, line|
    hash, head = line.split(/\t/, 2)
    head = head[%r{refs/heads/(.+)$},1] unless head.nil?
    memo[head] = hash unless head.nil?
    memo
  end if !(user.nil? || user.strip.empty?)
end

helper :remote_branch? do |user, branch|
  remote_branches_for(user).key?(branch)
end

helper :branch_dirty_from_remote? do
    branch = current_branch
    branch_dirty? ||
      !system("git diff --quiet origin/#{branch} 2>#{DEV_NULL}")
end

# see if there are any cached or tracked files that have been modified
# originally, we were going to use git-ls-files but that could only
# report modified track files...not files that have been staged
# for committal
helper :branch_dirty? do
  !( system("git diff --quiet 2>#{DEV_NULL}") || 
    !system("git diff --cached --quiet 2>#{DEV_NULL}")
  )
end

helper :tracking do
  remotes.inject({}) do |memo, (name, url)|
    if ur = user_and_repo_from(url)
      memo[name] = ur.first
    else
      memo[name] = url
    end
    memo
  end
end

helper :tracking? do |user|
  tracking.values.include?(user)
end

helper :owner do
  user_for(origin)
end

helper :current_branch do
  `git rev-parse --symbolic-full-name HEAD`.chomp.sub(/^refs\/heads\//, '')
end

helper :user_and_branch do
  raw_branch = current_branch
  user, branch = raw_branch.split(/\//, 2)
  if branch
    [user, branch]
  else
    [owner, user]
  end
end

helper :branch_user do
  user_and_branch.first
end

helper :branch_name do
  user_and_branch.last
end

helper :public_url_for_user_and_repo do |user, repo|
  "git://github.com/#{user}/#{repo}.git"
end

helper :private_url_for_user_and_repo do |user, repo|
  "git@github.com:#{user}/#{repo}.git"
end

helper :public_url_for do |user|
  public_url_for_user_and_repo user, project
end

helper :private_url_for do |user|
  private_url_for_user_and_repo user, project
end

helper :homepage_for do |user, branch|
  "https://github.com/#{user}/#{project}/tree/#{branch}"
end

helper :network_page_for do |user|
  "https://github.com/#{user}/#{project}/network"
end

helper :network_meta_for do |user|
  "https://github.com/#{user}/#{project}/network_meta"  
end

helper :issues_page_for do |user|
  "https://github.com/#{user}/#{project}/issues"
end

helper :list_issues_for do |user, state|
  "http://github.com/api/v2/yaml/issues/list/#{user}/#{project}/#{state}"
end

helper :has_launchy? do |blk|
  begin
    gem 'launchy'
    require 'launchy'
    blk.call
  rescue Gem::LoadError
    STDERR.puts "Sorry, you need to install launchy: `gem install launchy`"
  end
end

helper :open do |url|
  has_launchy? proc {
    Launchy::Browser.new.visit url
  }
end

helper :print_network_help do
  puts "
You have to provide a command :

    web [user]     - opens your web browser to the network graph page for this
                     project, or for the graph page for [user] if provided

    list           - shows the projects in your network that have commits
                     that you have not pulled in yet, and branch names

    fetch          - adds all projects in your network as remotes and fetches
                     any objects from them that you don't have yet

    commits        - will show you a list of all commits in your network that
                     you have not ignored or have not merged or cherry-picked.
                     This will automatically fetch objects you don't have yet.

      --project (user/branch)  - only show projects that match string
      --author (email)         - only show projects that match string
      --after (date)           - only show commits after date
      --before (date)          - only show commits before date
      --shas                   - only print shas (can pipe through 'github ignore')
      --applies                - filter to patches that still apply cleanly
      --sort                   - how to sort the commits (date, branch, author)
"
end

helper :print_network_cherry_help do
  $stderr.puts "
=========================================================================================
These are all the commits that other people have pushed that you have not
applied or ignored yet (see 'github ignore'). Some things you might want to do:

* You can run 'github fetch user/branch' (sans '~N') to pull into a local branch for testing
* You can run 'github cherry-pick [SHA]' to apply a single patch
* You can run 'github merge user/branch' to merge a commit and all the '~N' variants.
* You can ignore all commits from a branch with 'github ignore ..user/branch'
=========================================================================================

"
end

helper :argv do
  GitHub.original_args
end

helper :network_members do |user, options|
  data = get_network_data(user, options)
  if !data
    STDERR.puts "*** Warning: There was a problem accessing the network members data for user: #{user.inspect} with options: #{options.inspect}."
    return []
  end
  data['users'].map { |u| u['name'] }
end


helper :get_network_data do |user, options|
  if options[:cache] && has_cache?
    return get_cache
  end
  if cache_network_data(options)
    begin
      return cache_data(user)
    rescue Exception => e    
      STDERR.puts "*** Warning: There was a problem accessing the network."
      STDERR.puts e      
      rv = get_cache
      STDERR.puts "Using cached data."
      rv
    end
  else
    return get_cache
  end
end

helper :cache_commits do |commits|
  File.open( commits_cache_path, 'w' ) do |out|
    out.write(commits.to_yaml)
  end
end

helper :commits_cache do
  YAML.load(File.open(commits_cache_path))
end

helper :cache_commits_data do |options|
  cache_expired? || options[:nocache] || !has_commits_cache?
end

helper :cache_network_data do |options|
  cache_expired? || options[:nocache] || !has_cache?
end

helper :github_user do
  `git config --get github.user`.chomp
end

helper :github_token do
  `git config --get github.token`.chomp
end

helper :network_cache_path do
  dir = `git rev-parse --git-dir`.chomp
  File.join(dir, 'network-cache')
end

helper :commits_cache_path do
  dir = `git rev-parse --git-dir`.chomp
  File.join(dir, 'commits-cache')
end

helper :cache_data do |user|
  `curl -L -F 'login=#{github_user}' -F 'token=#{github_token}' #{network_meta_for(user)} -o #{network_cache_path} -s`
  get_cache  
end

helper :cache_expired? do
  return true if !has_cache?
  age = Time.now - File.stat(network_cache_path).mtime
  return true if age > (60 * 60) # 1 hour
  false
end

helper :has_cache? do
  File.file?(network_cache_path)
end

helper :has_commits_cache? do
  File.file?(commits_cache_path)
end

helper :get_cache do
  begin
    raw_data = File.read(network_cache_path)
    if !raw_data || raw_data.empty?      
      STDERR.puts "*** No network data found in cache at: #{network_cache_path}"
      return nil
    end
    data = JSON.parse(raw_data)      
  rescue Exception => e    
    STDERR.puts "*** Warning: There was a problem reading the cached network data at: #{network_cache_path}."
    STDERR.puts e
  end
end

helper :print_issues_help do
  puts <<-EOHELP
You have to provide a command :

  open           - shows open tickets for this project
  closed         - shows closed tickets for this project

    --user=<username>   - show issues from <username>'s repository
    --after=<date>      - only show issues updated after <date>

  EOHELP
end

helper :distance_of_time do |from_time, to_time|
  # this is a dumbed-down version of actionpack's helper.
  from_time = Time.parse(from_time) if from_time.is_a?(String)
  to_time   = Time.parse(to_time) if to_time.is_a?(String)

  distance_in_minutes = (((to_time - from_time).abs)/60).round
  words = case distance_in_minutes
          when 0               then "less than 1 minute"
          when 2..44           then "%d minutes" % distance_in_minutes
          when 45..89          then "about 1 hour"
          when 90..1439        then "about %d hours" % (distance_in_minutes.to_f / 60.0).round
          when 1440..2879      then "1 day"
          when 2880..43199     then "%d days" % (distance_in_minutes / 1440).round
          when 43200..86399    then "about 1 month"
          when 86400..525599   then "%d months" % (distance_in_minutes / 43200).round
          when 525600..1051199 then "about 1 year"
          else                      "over %d years" % (distance_in_minutes / 525600).round
          end

  "#{words} ago"
end

helper :format_issue do |issue, options|
  options ||= {}
  report = []
  report << "Issue ##{issue['number']} (#{issue['votes']} votes): #{issue['title']}"
  report << "*  URL: http://github.com/#{options[:user]}/#{project}/issues/#issue/#{issue['number']}" if options[:user]
  report << "*  Opened #{distance_of_time(issue['created_at'], Time.now)} by #{issue['user']}" if issue['created_at']
  report << "*  Closed #{distance_of_time(issue['closed_at'], Time.now)}" if issue['closed_at']
  report << "*  Last updated #{distance_of_time(issue['updated_at'], Time.now)}" if issue['updated_at']
  report << "*  Labels: #{issue['labels'].join(', ')}" if issue['labels'] && issue['labels'].length > 0
  report << ""
  report << issue['body']
  report << ""
  report.join("\n")
end

# Converts an array of {"name" => "foo", "description" => "some description"} items
# as a string list like:
#   foo     # some description
#   bar-tar # another description
helper :format_list do |items|
  longest_name = items.inject("") do |name, item|
    name = item["name"] if item["name"] && item["name"].size > name.size
    name
  end
  longest = longest_name.size + 1
  lines = items.map do |item|
    cmdstr = "%-#{longest}s" % item["name"]
    if (description = item["description"]) && description.length > 0
      cmdstr += "# #{description}"
    end
    cmdstr
  end.join("\n")
end

helper :filter_issue do |issue, options|
  if options[:after] && ! options[:after].instance_of?(Time)
    options[:after] = Time.parse(options[:after]) rescue (puts 'cant parse after date')
  end
  return true if options[:after] && (options[:after] > issue['updated_at']) rescue false
  return true if options[:label] && (issue['labels'].nil? || issue['labels'].empty? || ! issue['labels'].include?(options[:label]))
  return false
end

helper :print_issues do |issues, options|
  issues.sort_by {|issue| issue['updated_at']}.reverse.each do |issue|
    next if filter_issue(issue, options)
    puts "-----"
    puts format_issue(issue, options)
  end
  puts "-----"
end

helper :http_get do |url|
  parsed_url = URI.parse(url)
  http = Net::HTTP.new(parsed_url.host, parsed_url.port)
  http.use_ssl = parsed_url.scheme == 'https'
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  http.get(parsed_url.request_uri)
end

helper :url_encode do |str|
  str.to_s.gsub(/[^a-zA-Z0-9_\.\-]/n) {|s| sprintf('%%%02x', s[0])}
end

helper :http_post do |url,params|
  parsed_url = URI.parse(url)
  http = Net::HTTP.new(parsed_url.host, parsed_url.port)
  http.use_ssl = parsed_url.scheme == 'https'
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  req = Net::HTTP::Post.new(parsed_url.path)
  req.body = params.map {|k,v| "#{url_encode(k)}=#{url_encode(v)}" }.join('&')
  req.content_type = 'application/x-www-form-urlencoded'
  http.request req
end

helper :prepare_param do |name, value|
  "Content-Disposition: form-data; name=\"#{url_encode(name)}\"\r\n\r\n#{value}\r\n"
end

helper :http_post_multipart do |url, params|
  parsed_url = URI.parse(url)
  http = Net::HTTP.new(parsed_url.host, parsed_url.port)
  http.use_ssl = parsed_url.scheme == 'https'
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  boundary = "#{rand(1000000)}boundaryofdoomydoom#{rand(1000000)}"

  fp = []
  files = []

  params.each do |k,v|
    if v.respond_to?(:path) and v.respond_to?(:read) then
      filename = v.path
      content = v.read
      mime_type = MIME::Types.type_for(filename)[0] || MIME::Types["application/octet-stream"][0]
      fp.push(prepare_param("Content-Type", mime_type.simplified))
      files.push("Content-Disposition: form-data; name=\"#{url_encode(k.to_s)}\"; filename=\"#{ filename }\"\r\nContent-Type: #{ mime_type.simplified }\r\n\r\n#{ content }\r\n")
    else
      fp.push(prepare_param(k,v))
    end
  end

  http.post(parsed_url.path, "--#{boundary}\r\n" + (fp + files).join("--#{boundary}\r\n") + "--#{boundary}--", {
    "Content-Type" => "multipart/form-data; boundary=#{boundary}",
    "User-Agent" => "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/523.10.6 (KHTML, like Gecko) Version/3.0.4 Safari/523.10.6"
  })
end