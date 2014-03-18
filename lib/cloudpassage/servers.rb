module Cloudpassage
  class Servers < Base
    include Collection

    def filter(options={})
        servers = JSON.parse(@base_resource.get(headers.merge(:params=>options)), :symbolize_names=>true)[:servers]
        servers.map { |i| get(i[:id], i) }
    end

    def singleton_class
      Server
    end

  end

  class Server < Single
    def initialize(token, base_resource, id, data=nil)
      @id = id
      super(token, RestClient::Resource.new("#{BASE_URL}/servers/"), @id, data)
    end

    def issues
      Issues.new(@token, @base_resource['issues'])
    end

    def accounts
      Accounts.new(self, @token, @base_resource['accounts'])
    end

    def retire
      # retire a 'inactive' server
      payload = {"server"=>{"retire"=>true}}
      @base_resource.put(payload.to_json, headers.merge(:content_type => :json))
    end

    def group=(group_id)
      # add server to group
      payload = {"server"=>{"group_id"=>group_id}}
      @base_resource.put(payload.to_json, headers.merge(:content_type => :json))
    end

    def commands
      Commands.new(@token, @base_resource['commands'])
    end

    def command(id)
      commands.get(id)
    end
  end

  # Accounts on a server
  class Accounts < Base
    include Collection

    def initialize(server, token, base_resource, data=nil)
      @server = server
      super(token, base_resource, data)
    end

    def singleton_class
      Account
    end

    def all
      data.map { |i| get(i[:username], i) }
    end

    # Creates username, in the given group.
    # If opts[:password] is specified, that password will be used.
    # Otherwise, password will be generated.
    def create(username, groups = '', opts = {})
      payload = {'account' => {
        :username => username,
        :comment  => '',
        :groups   => groups,
        :password => password_opts.merge(opts.fetch(:password, {})),
      }}
      @server.commands.get(post(payload)['command']['id'])
    end

    def reset(username, opts = {})
      payload = {'password' => password_opts.merge(opts)}
      JSON.parse @base_resource[username]['password'].put(payload.to_json, headers)
    end

    def remove(username)
      JSON.parse @base_resource[username].delete(headers)
    end

    def headers
      super.merge({'Content-Type'=>'application/json'})
    end

    private
    def password_opts
      {
        :length             => 25,
        :include_special    => true,
        :include_numbers    => true,
        :include_uppercase  => true
      }
    end
  end

  class Issues < Base
    include Collection

    def singleton_class
      Issue
    end
  end

  class Commands < Base
    include Collection

    def singleton_class
      Command
    end
  end

  class Command < Single
    def done?
      self.reload
      %w'completed failed'.include? self.status
    end
  end

  class Issue < Single;end
  class Account < Single;end
end
