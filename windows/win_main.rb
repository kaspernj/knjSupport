class Win_main
	def initialize
		@glade = GladeXML.new("glades/win_main.glade"){|h|method(h)}
		@glade["window"].show_all
		
		Knj::Thread.new do
			while true
				self.refresh_status
				sleep 0.3
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
		
		if RUBY_PLATFORM == "i386-mingw32"
			@vnc_local_port = 5900
			@ssh_local_host = "127.0.1.1"
			@vnc_local_host = "127.0.1.1"
		else
			@vnc_local_port = self.random_local_port
			@ssh_local_host = "0.0.0.0"
			@vnc_local_host = "0.0.0.0"
		end
		
		begin
			@forward_ssh = @ssh.forward(
				:type => "remote",
				:port_local => 22,
				:port_remote => @ssh_remote_port,
				:host => @ssh_local_host
			)
		rescue Exception => e
			Gtk2.msgbox(sprintf(_("Could not open SSH port forward: %s"), e.message))
		end
		
		begin
			@forward_vnc = @ssh.forward(
				:type => "remote",
				:port_local => @vnc_local_port,
				:port_remote => @vnc_remote_port,
				:host => @vnc_local_host
			)
		rescue Exception => e
			Gtk2.msgbox(sprintf(_("Could not open VNC port forward: %s"), e.message))
		end
	end
	
	def open_vncserver
		if RUBY_PLATFORM == "i386-mingw32"
			Gtk2.msgbox($config[:tightvnc_path])
			@vnc = Knj::Win::TightVNC.new(
				:port => @vnc_local_port,
				:path => $config[:tightvnc_path]
			)
		else
			@vnc = Knj::X11VNC.new(
				:port => @vnc_local_port
			)
		end
	end
	
	def refresh_status
		if @forward_ssh and @forward_ssh.open
			newt = sprintf(_("SSH port open (%s)"), @ssh_remote_port.to_s)
		else
			newt = _("SSH port closed")
		end
		
		@glade["labStatusSSHPort"].label = newt if @glade["labStatusSSHPort"].label != newt
		
		
		if @forward_vnc and @forward_vnc.open
			newt = sprintf(_("VNC port open (%s)"), @vnc_remote_port.to_s)
		else
			newt = _("VNC port closed")
		end
		
		@glade["labStatusVNCPort"].label = newt if @glade["labStatusVNCPort"].label != newt
		
		
		if @vnc and @vnc.open?
			newt = sprintf(_("VNC server running (%s)"), @vnc_local_port.to_s)
		else
			newt = _("VNC server not running")
		end
		
		@glade["labStatusVNCServer"].label = newt if @glade["labStatusVNCServer"].label != newt
		
		id = "#{@ssh_remote_port}-#{@vnc_remote_port}-#{@vnc_local_port}"
		@glade["labStatusID"].label = id if @glade["labStatusID"].label != id
	end
	
	def on_window_destroy
		Gtk.main_quit
	end
	
	def on_btnQuit_clicked
		Gtk.main_quit
	end
end