class CommandOutputChannel < ApplicationCable::Channel
  def subscribed
    stream_from "command_output_stream"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
