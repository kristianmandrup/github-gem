require 'fileutils'
require 'shellwords'

if RUBY_PLATFORM =~ /mswin|mingw/
  begin
    require 'win32/open3'
  rescue LoadError
    warn "You must 'gem install win32-open3' to use the github command on Windows"
    exit 1
  end
else
  require 'open3'
end

module GitHub
  class Command
    include FileUtils

    def initialize(block)
      (class << self;self end).send :define_method, :command, &block
    end

    def call(*args)
      arity = method(:command).arity
      args << nil while args.size < arity
      send :command, *args
    end

    def helper
      @helper ||= Helper.new
    end

    def options
      GitHub.options
    end

    def pgit(*command)
      puts git(*command)
    end

    def git(command)
      run :sh, command
    end

    def git_exec(command)
      run :exec, command
    end

    def run(method, command)
      if command.is_a? Array
        command = [ 'git', command ].flatten
        GitHub.learn command.join(' ')
      else
        command = 'git ' + command
        GitHub.learn command
      end

      send method, *command
    end

    def sh(*command)
      Shell.new(*command).run
    end

    def die(message)
      puts "=> #{message}"
      exit!
    end


    def github_user
      user = git("config --get github.user")
      raise "No user specified in github config" if user.empty?
      return user
    end

    def github_token
      token = git("config --get github.token")
      raise "No token specified in github config" if token.empty?
      return token
    end

    def github_post(url, hash={})
      hash = { "login" => github_user, "token" => github_token }.merge(hash)
      entries = hash.entries.sort {|x,y| x.first <=> y.first}
      sh "curl " + entries.map { |k, v| '-F '+ shellescape("#{k}=#{v}") }.join(" ") + " #{shellescape(url)}"
    end

    def shellescape(s)
      # make ruby -v ≤ v1.8.6 happy
      s.respond_to?(:shellescape) ? s.shellescape : "'#{s}'"
    end

    def editor
        e = git "config core.editor"
        e = ENV['GIT_EDITOR'] if not e or e.empty?
        e = ENV['EDITOR'] if not e or e.empty?
        e = 'vi' if not e or e.empty?
        return e
    end

    def shell_user
      ENV['USER']
    end

    def current_user?(user)
      begin
        user == github_user || user == shell_user
      rescue
        user == shell_user
      end
    end

    class Shell < String
      attr_reader :error
      attr_reader :out

      def initialize(*command)
        @command = command
      end

      def run
        GitHub.debug "sh: #{command}"

        out = err = nil
        Open3.popen3(*@command) do |_, pout, perr|
          out = pout.read.strip
          err = perr.read.strip
        end

        replace @error = err unless err.empty?
        replace @out = out unless out.empty?

        self
      end

      def command
        @command.join(' ')
      end

      def error?
        !!@error
      end

      def out?
        !!@out
      end
    end
  end

  class GitCommand < Command
    def initialize(name)
      @name = name
    end

    def command(*args)
      git_exec [ @name, args ]
    end
  end
end

