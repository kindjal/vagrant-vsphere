require 'rbvmomi'
require 'i18n'
require 'vSphere/action/vim_helpers'

module VagrantPlugins
  module VSphere
    module Action
      class Clone
        include VimHelpers

        def initialize(app, env)
          @app = app
        end

        def call(env)
          config = env[:machine].provider_config
          connection = env[:vSphere_connection]
          machine = env[:machine]

          if config.template_name.include?('/')
            template = get_object_by_path(connection,config.template_name)
          else
            dc = get_datacenter connection, machine
            template = dc.find_vm config.template_name
          end
          abort "Cannot find template #{config.template_name}" unless template

          raise Error::VSphereError, :message => I18n.t('errors.missing_template') if template.nil?

          begin

            if config.resource_pool_name and config.resource_pool_name.include?('/')
              pool = get_object_by_path(connection,config.resource_pool_name)
              abort "Resource pool not found: #{config.resource_pool_name}" unless pool
            else
              # FIXME: Warn about default resource pool?
              pool = get_resource_pool(connection, machine)
            end
            abort "Cannot find resource pool #{config.resource_pool_name}" unless pool

            if config.target_folder and config.target_folder.include?('/')
              folder = get_object_by_path(connection,config.target_folder)
              abort "Target folder not found: #{config.target_folder}" unless folder
            else
              env[:ui].warning I18n.t('vsphere.using_default_target')
              folder = template.parent
            end
            abort "Cannot find target folder #{config.target_folder}" unless folder

            location = RbVmomi::VIM.VirtualMachineRelocateSpec :pool => pool
            spec = RbVmomi::VIM.VirtualMachineCloneSpec :location => location, :powerOn => true, :template => false

            env[:ui].info I18n.t('vsphere.creating_cloned_vm')
            env[:ui].info " -- Template VM: #{config.template_name}"
            env[:ui].info " -- Name: #{config.name}"

            new_vm = template.CloneVM_Task(:folder => folder, :name => config.name, :spec => spec).wait_for_completion
          rescue Exception => e
            env[:ui].error "An error occurred while cloning VM: " + e.to_s
            raise Errors::VSphereError, :message => e.message
          end

          #TODO: handle interrupted status in the environment, should the vm be destroyed?

          machine.id = new_vm.config.uuid

          # wait for SSH to be available 
          env[:ui].info(I18n.t("vsphere.waiting_for_ssh"))
          while true
            break if env[:machine].communicate.ready?
            sleep 5
          end
          env[:ui].info I18n.t('vsphere.vm_clone_success')

          @app.call env
        end
      end
    end
  end
end
