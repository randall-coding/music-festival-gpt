class HomeController < ApplicationController
  def index
    # @bands = Band.all
    # params[:input] = "DJ Snake"    
    # @bands = [{"name"=>"DJ Snake", "spotifyUrl"=>"https://open.spotify.com/artist/540vIaP2JwjQb9dm3aArA4", "songs"=>[{"name"=>"Lean On (feat. MØ & DJ Snake)", "url"=>"https://open.spotify.com/track/1qE47wUKG2juJwPoLqg4C9"}, {"name"=>"Let Me Love You", "url"=>"https://open.spotify.com/track/0lYBSQXN6rCTvUZvg9S0lU"}, {"name"=>"Please Don't Change (feat. DJ Snake)", "url"=>"https://open.spotify.com/track/0k0GtcnyQLMiXrdEDbLXmJ"}]}]
    # return :index
    
    folder_script_path = Rails.root.join('..', "coachella.gpt").to_s

    if params[:input].present?
      Dir.chdir(File.dirname(folder_script_path)) do
        stdout, stderr, status = Open3.capture3("gptscript" + " " + "coachella.gpt" + " " + params[:input])
        
        if status.success?
          # example = {"bandName"=>"DJ Snake",
          #   "spotifyUrl"=>"https://open.spotify.com/artist/540vIaP2JwjQb9dm3aArA4",
          #   "songs"=>
          #    [{"name"=>"Lean On (feat. MØ & DJ Snake)",
          #      "url"=>"https://open.spotify.com/track/1qE47wUKG2juJwPoLqg4C9"},
          #     {"name"=>"Let Me Love You",
          #      "url"=>"https://open.spotify.com/track/0lYBSQXN6rCTvUZvg9S0lU"},
          #     {"name"=>"Please Don't Change (feat. DJ Snake)",
          #      "url"=>"https://open.spotify.com/track/0k0GtcnyQLMiXrdEDbLXmJ"}]}
          
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
end
