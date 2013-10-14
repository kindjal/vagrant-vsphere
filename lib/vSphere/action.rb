require 'vagrant'
require 'vagrant/action/builder'

module VagrantPlugins
  module VSphere
    module Action
      include Vagrant::Action::Builtin

      #Vagrant commands
      def self.action_destroy
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectVSphere
          b.use Call, GetState do |env, b2|
            state = env[:machine_state_id]
            case state
              when :notcreated
                # This won't be called, Vagrant will default
                # to Virtualbox.
                b2.use MessageNotCreated
                next
              when :running
                b2.use PowerOff
              when :poweroff
                next
            end
          end
          b.use Destroy
        end
      end

      def self.action_provision
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            if !env[:result]
              b2.use MessageNotCreated
              next
            end

            b2.use Provision
            b2.use SyncFolders
          end
        end
      end

      def self.action_ssh
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            if !env[:result]
              b2.use MessageNotCreated
              next
            end

            b2.use SSHExec
          end
        end
      end

      def self.action_up
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectVSphere
          b.use Call, IsCreated do |env, b2|
            if env[:result]
              b2.use MessageAlreadyCreated
              next
            end

            b2.use Clone
          end

          b.use Call, GetState do |env, b2|
            if env[:machine_state_id].eql?(:poweroff)
              b2.use PowerOn
              next
            end
          end

          b.use CloseVSphere
          b.use Provision
          b.use SyncFolders
        end
      end

      def self.action_halt
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectVSphere
          b.use Call, GetState do |env, b2|
            state = env[:machine_state_id]
            case state
              when :notcreated
                b2.use MessageNotCreated
                next
              when :running
                b2.use PowerOff
                next
              when :poweroff
                b2.use MessageAlreadyOff
                next
              else fail "Unexepcted result from GetState"
            end
          end
        end
      end

      #vSphere specific actions
      def self.action_get_state
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectVSphere
          b.use GetState
          b.use CloseVSphere
        end
      end

      def self.action_get_ssh_info
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectVSphere
          b.use GetSshInfo
          b.use CloseVSphere
        end
      end

      #autoload
      action_root = Pathname.new(File.expand_path('../action', __FILE__))
      autoload :Clone, action_root.join('clone')
      autoload :CloseVSphere, action_root.join('close_vsphere')
      autoload :ConnectVSphere, action_root.join('connect_vsphere')
      autoload :Destroy, action_root.join('destroy')
      autoload :GetSshInfo, action_root.join('get_ssh_info')
      autoload :GetState, action_root.join('get_state')
      autoload :IsCreated, action_root.join('is_created')
      autoload :MessageAlreadyCreated, action_root.join('message_already_created')
      autoload :MessageAlreadyRunning, action_root.join('message_already_running')
      autoload :MessageAlreadyOff, action_root.join('message_already_off')
      autoload :MessageNotCreated, action_root.join('message_not_created')
      autoload :PowerOff, action_root.join('power_off')
      autoload :PowerOn, action_root.join('power_on')
      autoload :SyncFolders, action_root.join('sync_folders')
    end
  end
end

