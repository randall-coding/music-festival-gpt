class HomeController < ApplicationController
  def index
    # @bands = Band.all
    # params[:input] = "DJ Snake"    
    # @bands = [{"name"=>"DJ Snake", "spotifyUrl"=>"https://open.spotify.com/artist/540vIaP2JwjQb9dm3aArA4", "songs"=>[{"name"=>"Lean On (feat. MØ & DJ Snake)", "url"=>"https://open.spotify.com/track/1qE47wUKG2juJwPoLqg4C9"}, {"name"=>"Let Me Love You", "url"=>"https://open.spotify.com/track/0lYBSQXN6rCTvUZvg9S0lU"}, {"name"=>"Please Don't Change (feat. DJ Snake)", "url"=>"https://open.spotify.com/track/0k0GtcnyQLMiXrdEDbLXmJ"}]}]
    # return :index
    
    folder_script_path = Rails.root.join('..', "coachella.gpt").to_s
    spotify_token = refresh_spotify_token

    unless spotify_token.present?
      puts "Error: spotify_token nil"
      @error = "Error:  Spotify API token returned nil.  Please contact administrator."
      return
    end 

    if params[:input].present?
      Dir.chdir(File.dirname(folder_script_path)) do
        Rails.logger.info "Command is "
        command = "GPTSCRIPT_API_SPOTIFY_COM_BEARER_TOKEN=#{spotify_token} stdbuf -oL -eL  gptscript --cache=false " + " " + "coachella.gpt" + " " + params[:input]
        command = "GPTSCRIPT_API_SPOTIFY_COM_BEARER_TOKEN=#{spotify_token} stdbuf -i0 -o0 -e0   gptscript --cache=false " + " " + "coachella.gpt" + " " + params[:input]
        
        Rails.logger.info {command}

        # stdout, stderr, status = Open3.capture3(command)        
        # if status.success? 
        #   parsed_string = stdout.gsub("```json\n", "").gsub("\n```", "").strip
        #   json_output = JSON.parse(parsed_string)
        #   @bands = json_output
        #   if @bands["bands"]
        #     @bands = @bands["bands"]   
        #   else 
        #     @bands = [@bands] unless @bands.is_a? Array
        #   end 
        #   Rails.logger.info "GPTscript successful.  Output is:"
        #   Rails.logger.info @bands
        # else
        #   puts "Error: #{stderr}"
        #   @error = stderr 
        # end

        Open3.popen3(command) do |stdin, stdout, stderr, thread|
          stdout_accumulator = ""
          trigger = "OUTPUT:"
          ActionCable.server.broadcast("command_output_stream", { key: "Test", line: "Running command" })
          
          # Broadcast output
          Thread.new do
            begin
              stdout.each do |line|
                # console.log("real time stdout #{line}")
                # Detect the trigger to reset accumulator
                puts "OK 1"
                stdout_accumulator = "" if line&.include?(trigger)
                puts "OK 2"
                stdout_accumulator += line.to_s unless stdout_accumulator.empty?
                puts "OK 3"

                # Broadcast all output lines for real-time display
                ActionCable.server.broadcast("command_output_stream", { key: "out", line: line })
                puts "OK 4"
              end
            rescue IOError => e
              # Handle the closed stream error, e.g., log it or silently ignore
              Rails.logger.error("Stdout stream closed unexpectedly: #{e.message}")
            end
          end
          
          # Broadcast errors
          # Thread.new do
          #   stderr.each do |line|
          #     # console.log("real time stderr #{line}")
          #     ActionCable.server.broadcast("command_output_stream", { key: "err", line: line })
          #   end
          # end

          thread.join
          
          byebug

          if thread.value.success?
            Rails.logger.info ("accumulator")
            Rails.logger.info (stdout_accumulator)
            return
            parsed_string = stdout_accumulator.gsub("```json\n", "").gsub("\n```", "").strip
            json_output = JSON.parse(parsed_string)
            @bands = json_output
            if @bands["bands"]
              @bands = @bands["bands"]   
            else 
              @bands = [@bands] unless @bands.is_a? Array
            end 
            Rails.logger.info "GPTscript successful.  Output is:"
            Rails.logger.info @bands
          else  #command error
            ActionCable.server.broadcast("command_output_stream", { key: "error", line: "Command execution failed." })
          end
        end 
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
      Rails.logger.error 'Failed to refresh access token'
      Rails.logger.error res.body
      return nil
    end
  end 

end
