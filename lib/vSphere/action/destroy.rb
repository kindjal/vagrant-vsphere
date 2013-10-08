require 'rbvmomi'
require 'i18n'
require 'vSphere/action/vim_helpers'

module VagrantPlugins
  module VSphere
    module Action
      class Destroy
        include VimHelpers

        def initialize(app, env)
          @app = app
        end

        def call(env)
          destroy_vm env
          env[:machine].id = nil

          @app.call env
        end

        def destroy_vm(env)
          vm = get_object_by_uuid env[:vSphere_connection], env[:machine].id
          return if vm.nil?

          begin
            env[:ui].info I18n.t('vsphere.destroy_vm')
            vm.Destroy_Task.wait_for_completion
          rescue Exception => e
            raise Errors::VSphereError, :message => e.message
          end
        end
      end
    end
  end
end
