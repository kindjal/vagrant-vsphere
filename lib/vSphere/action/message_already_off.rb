require 'i18n'

module VagrantPlugins
  module VSphere
    module Action
      class MessageAlreadyOff
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info I18n.t('vsphere.vm_already_off')
          @app.call(env)
        end
      end
    end
  end
end
