# -*- encoding : utf-8 -*-
require_relative 'lolcommits_ai/lolcommits_ai_service'

module Lolcommits
  class LolcommitsAI < Plugin

    DEFAULT_FONT_PATH = File.join(Configuration::LOLCOMMITS_ROOT, 'vendor', 'fonts', 'Impact.ttf')

    def initialize(runner)
      super
      options.concat(%w(vision_key cognitive_key))
    end

    def self.name
      'lolcommits_ai'
    end

    def self.runner_order
      :postcapture
    end

    def run_postcapture
      return unless valid_configuration?

      # snap the raw video
      @video_file = runner.config.video_loc
      @gif_file = runner.main_image

      frames = Dir.entries(runner.config.frames_loc)
      if frames.count > 2
        frame_name = frames[frames.count / 2]
        @sample_frame = "#{runner.config.frames_loc}/#{frame_name}"
      end

      ai = LolcommitsAIService.new(DEFAULT_FONT_PATH, @video_file, @gif_file, @sample_frame, configuration)

      title = ai.run(true)
      puts title
    end

    def configured?
      !configuration['enabled'].nil? && configuration['vision_key'] && configuration['cognitive_key']
    end
  end
end
