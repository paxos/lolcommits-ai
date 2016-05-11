# Lolcommits-AI

lolcommits enhanced with Artificial Intelligence

This is a lolcommits plugin that uses the free [Microsoft Cognitive Services](https://www.microsoft.com/cognitive-services/en-us/apis) to enhance your lolcommit experience even more!


![804a79fc234](https://cloud.githubusercontent.com/assets/121539/15093409/aece7580-143b-11e6-9346-8857b126003b.gif)

## Installation
To install it, simply drop all files (`lolcommits_ai.rb` and the `lolcommits_ai` folder) into your `LOL_DIR/.plugins` folder.

Your LOL_DIR is usually in your home directory if you have not set it otherwise.

    ~/.lolcommits

If you do something like

    export LOLCOMMITS_DIR=$HOME/Dropbox/lolcommits

in your hooks, place the `plugins` folder there.

### Requirements
This plugin requires the `color` gem. Install it using:

    gem install color

## Configuration

To configure the plugin, you need two API tokens for the Microsoft Cognitive Services:

*  Computer Vision - Preview: used to get a description of the image
*  Emotion - Preview: used to analyze animated lolcommits

You get them for free [here](https://www.microsoft.com/cognitive-services).

To enable the plugin, open up a console, navigate to the repository you want to activate the plugin in and call

    lolcommits --config
    
It should print a list of plugins - including `lolcommits_ai`. If it is missing, check if you have copied the files into the correct directory. If it is in the list, continue:

* enter `lolcommits_ai` to configure the plugin
* enter `true` to enable the plugin
* enter your vision key
* enter your emotion key (as cognitive key)

## Usage

From now on, all your lolcommit pictures of that repostory will automatically enhanced with the power of AI! As this is a long running script (as it talks to different web services), you might want to change your git hook a little bit to let the task run in background.

An example:

    export LOLCOMMITS_DIR=$HOME/Dropbox/lolcommits
    export SLACK_TOKEN=TOKEN
    nohup slackcat -c lolcommits -m "$(ls $HOME/Dropbox/lolcommits/${PWD##*/}/$(git rev-parse HEAD | cut -c1-11).*)" -T "$(echo "$(lolcommits --capture --animate=5)" | tail -1)" &>/dev/null &%


### Please Note

 This sample uses [Slackcat](https://github.com/rlister/slackcat) to upload the result to slack. *You cannot use the slack plugin of lolcommits anymore, as it gets executed BEFORE this plugin*.


