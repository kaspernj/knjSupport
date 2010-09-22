class Win_main
	def initialize
		@glade = GladeXML.new("glades/win_main.glade"){|h|method(h)}
		@glade["window"].show_all
		
		Knj::Thread.new do
			while true
				self.refresh_status
				sleep 1
			end
		end
		
		Knj::Thread.new do
			self.open_forward
			self.open_vncserver
		end
	end
	
	def random_remote_port(host)
		0.upto(100) do
			begin
				port = Rand::range(5000, 64000)
				conn = TCPSocket.open(host, port)
				conn.close
				
				#if this in reached then port is in use - continue to look.
			rescue Exception => e
				#looks like port is not in use - return port.
				return port
			end
		end
	end
	
	def random_local_port
		0.upto(100) do
			begin
				port = Rand::range(5000, 64000)
				conn = TCPServer.open("0.0.0.0", port)
				conn.close
				
				return port
			rescue Exception => e
				#do nothing - try to find a new port.
			end
		end
	end
	
	def open_forward
		@ssh = SSHRobot.new($config_ssh_server)
		
		@ssh_remote_port = self.random_remote_port($config_ssh_server[:host])
		@vnc_remote_port = self.random_remote_port($config_ssh_server[:host])
		@vnc_local_port = self.random_local_port
		
		begin
			@forward_ssh = @ssh.forward(
				:type => "remote",
				:port_local => 22,
				:port_remote => @ssh_remote_port,
				:host => "0.0.0.0"
			)
		rescue Exception => e
			Gtk2.msgbox(sprintf(_("Could not open SSH port forward: %s"), e.message))
		end
		
		begin
			@forward_vnc = @ssh.forward(
				:type => "remote",
				:port_local => @vnc_local_port,
				:port_remote => @vnc_remote_port,
				:host => "0.0.0.0"
			)
		rescue Exception => e
			Gtk2.msgbox(sprintf(_("Could not open VNC port forward: %s"), e.message))
		end
	end
	
	def open_vncserver
		@vnc = Knj::X11VNC.new(
			:port => @vnc_local_port
		)
	end
	
	def refresh_status
		if @forward_ssh and @forward_ssh.open
			@glade["labStatusSSHPort"].label = sprintf(_("SSH port open (%s)"), @ssh_remote_port.to_s)
		else
			@glade["labStatusSSHPort"].label = _("SSH port closed")
		end
		
		if @forward_vnc and @forward_vnc.open
			@glade["labStatusVNCPort"].label = sprintf(_("VNC port open (%s)"), @vnc_remote_port.to_s)
		else
			@glade["labStatusVNCPort"].label = _("VNC port closed")
		end
		
		if @vnc and @vnc.open?
			@glade["labStatusVNCServer"].label = sprintf(_("VNC server running (%s)"), @vnc_local_port.to_s)
		else
			@glade["labStatusVNCServer"].label = _("VNC not running")
		end
	end
	
	def on_window_destroy
		Gtk.main_quit
	end
	
	def on_btnQuit_clicked
		Gtk.main_quit
	end
end