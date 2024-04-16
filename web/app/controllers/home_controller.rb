require 'pty'

class HomeController < ApplicationController
  def index    
    @uuid = params[:uuid].presence || SecureRandom.uuid

    folder_script_path = Rails.root.join('..', "coachella.gpt").to_s
    spotify_token = refresh_spotify_token

    unless spotify_token.present?
      puts "Error: spotify_token nil"
      @error = "Error:  Spotify API token returned nil.  Please contact administrator."
      return
    end 

    if params[:input].present?
      Dir.chdir(File.dirname(folder_script_path)) do
        Rails.logger.info "Command is "  # 2>&1
        command = "GPTSCRIPT_API_SPOTIFY_COM_BEARER_TOKEN=#{spotify_token} gptscript " + " " + "coachella.gpt" + " " + params[:input] 
        
        Rails.logger.info {command}
       
        trigger = "OUTPUT:"
        stdout_accumulator = "" 

        # Run command
        begin
          PTY.spawn(command) do |stdout, stdin, pid|
            begin
              stdout.each do |line|
                ActionCable.server.broadcast("command_output_#{@uuid}", { key: "Command", line: line })
                if line.include?(trigger)
                  stdout_accumulator = ""  #reset
                end
                stdout_accumulator << line 
                puts line
              end
            rescue Errno::EIO
              Rails.logger.warn "stdout error on PTY"
            ensure
              Process.wait(pid) 
            end
        end
        rescue PTY::ChildExited => e
          puts "The child process exited! #{e}"
        end

        parsed_string = stdout_accumulator.gsub("OUTPUT:\r\n\r\n","")
        puts "parsed_string"
        puts parsed_string

        json_output = JSON.parse(parsed_string)
        @bands = json_output
        if @bands["bands"]
          @bands = @bands["bands"]   
        elsif @bands["matches"]
          @bands = @bands["matches"]   
        else
          @bands = [@bands] unless @bands.is_a? Array
        end 
        Rails.logger.info "GPTscript successful.  Output is:"
        Rails.logger.info @bands
      end
    end
  end #index

  private
  def refresh_spotify_token
    client_id = ENV['SPOTIFY_CLIENT_ID']
    client_secret = ENV['SPOTIFY_CLIENT_SECRET']
    refresh_token = ENV['SPOTIFY_REFRESH_TOKEN']
    auth_header = Base64.strict_encode64("#{client_id}:#{client_secret}")

    uri = URI('https://accounts.spotify.com/api/token')
    req = Net::HTTP::Post.new(uri)
    req['Authorization'] = "Basic #{auth_header}"
    req.set_form_data('grant_type' => 'refresh_token', 'refresh_token' => refresh_token, 'redirect_uri' => 'http://localhost:8080/callback')

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end

    if res.is_a?(Net::HTTPSuccess)
      access_token = JSON.parse(res.body)['access_token']
      return access_token
    else
      Rails.logger.error 'Failed to refresh spotify access token'
      Rails.logger.error res.body
      return nil
    end
  end 

end
