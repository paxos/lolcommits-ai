require 'net/http'
require 'json'
require 'color'

class LolcommitsAIService

  attr_accessor :video_file, :gif_file, :waiting_url, :result, :font_path, :configuration

  def initialize(font_path, video_file, gif_file, sample_frame, configuration)
    @font_path = font_path
    @video_file = video_file
    @gif_file = gif_file
    @sample_frame = sample_frame
    @configuration = configuration
  end

  def run(return_title = false)
    post_video
    wait_for_and_get_results
    annotate_image_with_result(@gif_file)

    if return_title
      return get_description
    end
  end

  def get_description
    return if @sample_frame.nil?
    uri = URI('https://api.projectoxford.ai/vision/v1.0/analyze?visualFeatures=Description')

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    data = File.open(@sample_frame, 'rb') { |io| io.read }

    request = Net::HTTP::Post.new(uri.request_uri)
    request['Ocp-Apim-Subscription-Key'] = configuration['vision_key']
    request.body = data
    request['content-type'] = 'application/octet-stream'

    response = http.request(request)
    #puts response.body
    result = JSON.parse(response.body)
    if result
      return result['description']['captions'][0]['text']
    end
  end

  def post_video
    #puts "Posting Video #{@video_file}"
    uri = URI('https://api.projectoxford.ai/emotion/v1.0/recognizeinvideo')

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    #data = File.read('tmp.wmv')
    data = File.open(@video_file, 'rb') { |io| io.read }

    request = Net::HTTP::Post.new(uri.request_uri)
    request['Ocp-Apim-Subscription-Key'] = @configuration['cognitive_key']
    request.body = data
    request['content-type'] = 'application/octet-stream'

    response = http.request(request)

    #puts response.body

    @waiting_url = response.header['operation-location']
  end

  def wait_for_and_get_results
    #puts "Getting results"

    # url = 'https://api.projectoxford.ai/emotion/v1.0/operations/5edb2c9b-dbf3-45d7-b368-c8ff43e27ee2'
    uri = URI(@waiting_url)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri.request_uri)
    request['Ocp-Apim-Subscription-Key'] = @configuration['cognitive_key']

    response = http.request(request)
    body = JSON.parse(response.body)

    while body['status'] != 'Succeeded'
      progress = body['progress']
      #puts "Result not ready. Waiting... (#{progress}%)"
      sleep 10

      response = http.request(request)
      body = JSON.parse(response.body)
    end

    if body['status'] == 'Succeeded'
      @result = JSON.parse(body['processingResult'])
      #puts body['processingResult']
    end
  end


  def annotate_image_with_result(output)
    #timescale = @result['timescale'].to_f # x ticks per second
    #framerate = @result['framerate']
    fragments = @result['fragments']

    total_tick_count = 0.0
    fragments.each do |fragment|
      total_tick_count = total_tick_count + fragment['duration']
    end

    #length_in_s = total_tick_count / timescale
    #frame_count = framerate * length_in_s
    frame_count = `identify #{@gif_file} | wc -l`.strip.to_i
    ticks_per_frame = total_tick_count / frame_count

    # For each frame, get tick and create annotation line

    # Frame to tick
    args = []
    current_emotion = ''
    for i in 0..frame_count-1
      event = event_for_tick(ticks_per_frame*(i), @result, ticks_per_frame)
      current_emotion = event_to_s(event) if !event_to_s(event).nil?
      color = emotion_to_color(current_emotion)
      args << "\\( -clone #{i} -undercolor '#00000080' -fill '#{color}' -annotate 0 '#{current_emotion}' \\) -swap #{i} +delete  "
    end

    `convert #{@gif_file} -coalesce -gravity NorthWest -font #{@font_path} -pointsize 24 -stroke '#000000' #{args.join(' ')} -layers OptimizeFrame -delay 0 -set delay 0 #{output}`
  end

  private

  def emotion_to_color(emotion)
    return Color::RGB.by_name('white').html         if emotion == 'neutral'
    return '#18ff10'                                if emotion == 'happy'
    return Color::RGB.by_name('red').html           if emotion == 'angry'
    return Color::RGB.by_name('yellow').html        if emotion == 'surprised'
    return Color::RGB.by_name('blue').html          if emotion == 'sad'
    return Color::RGB.by_name('purple').html        if emotion == 'disgusted'
    return Color::RGB.by_name('black').html         if emotion == 'fear'
    return '#10FFF9'                                if emotion == 'contempt'

    return Color::RGB.by_name('white').html
  end

  def event_to_s(events)
    return nil if events.nil?
    return nil if events.count == 0
    event = events[0]['windowFaceDistribution']

    return 'neutral'        if event['neutral'] >= 1
    return 'happy'          if event['happiness'] >= 1
    return 'surprised'      if event['surprise'] >= 1
    return 'sad'            if event['sadness'] >= 1
    return 'angry'          if event['anger'] >= 1
    return 'disgusted'      if event['disgust'] >= 1
    return 'fear'           if event['fear'] >= 1
    return 'contempt'       if event['contempt'] >= 1
    return 'none'
  end

  def event_for_tick(tick, result, ticks_per_frame)
    fragments = result['fragments']
    last_event = nil

    fragments.each do |fragment|
      start = fragment['start']
      duration = fragment['duration']
      interval = fragment['interval'] # missing if no events
      events = fragment['events']

      index = start

      #index = index + duration if events.nil?

      next if events.nil?
      event_count = 0

      events.each do |event|
        event_tick = start + (event_count * interval)

        if event_tick - (ticks_per_frame) >= tick
          return event
        end

        last_event = event

        event_count = event_count +1
        index = index + interval
      end
    end

    return last_event
  end

end