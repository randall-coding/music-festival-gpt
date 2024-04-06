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
        Rails.logger.info {"GPTSCRIPT_API_SPOTIFY_COM_BEARER_TOKEN=#{spotify_token} gptscript" + " " + "coachella.gpt" + " " + params[:input]}

        stdout, stderr, status = Open3.capture3("GPTSCRIPT_API_SPOTIFY_COM_BEARER_TOKEN=#{spotify_token} gptscript" + " " + "coachella.gpt" + " " + params[:input])        
        if status.success?          
          parsed_string = stdout.gsub("```json\n", "").gsub("\n```", "").strip
          json_output = JSON.parse(parsed_string)
          @bands = json_output
          if @bands["bands"]
            @bands = @bands["bands"]   
          else 
            @bands = [@bands] unless @bands.is_a? Array
          end 
          Rails.logger.info "GPTscript successful.  Output is:"
          Rails.logger.info @bands
        else
          puts "Error: #{stderr}"
          @error = stderr 
        end
      end
    end
  end

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
