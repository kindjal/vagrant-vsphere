require 'rbvmomi'
require 'i18n'
require 'vSphere/action/vim_helpers'

module VagrantPlugins
  module VSphere
    module Action
      class PowerOn
        include VimHelpers

        def initialize(app, env)
          @app = app
        end

        def call(env)
          vm = get_object_by_uuid env[:vSphere_connection], env[:machine].id

          unless vm.nil?
            env[:ui].info I18n.t('vsphere.power_on_vm')
            vm.PowerOnVM_Task.wait_for_completion
          end

          @app.call env
        end
      end
    end
  end
end
