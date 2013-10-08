require 'rbvmomi'

module VagrantPlugins
  module VSphere
    module Action
      class ConnectVSphere
        def initialize(app, env)
          @app = app
        end

        def call(env)
          config = env[:machine].provider_config

          begin
            config_hash = config.instance_variables.each_with_object({}) { |var, hash|
              hash[var.to_s.delete("@").to_sym] = config.instance_variable_get (var)
            }
            env[:vSphere_connection] = RbVmomi::VIM.connect config_hash
            @app.call env
          rescue Exception => e
            puts "An error occurred while connecting to vSphere: " + e.to_s
            raise VagrantPlugins::VSphere::Errors::VSphereError, :message => e.message
          end
        end
      end
    end
  end
end
