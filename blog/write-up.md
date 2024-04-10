# Coachella band finder with GPTScript

GPTScript is a scripting language designed to automate interactions with OpenAI's language models. In this post, I'll share how I used it to create a useful tool for music enthusiasts. 

This script will use Coachella's music festival lineup to make personalized band recommendations along with song samples from Spotify.  To skip ahead, the final script is [here](https://github.com/randall-coding/coachella-gpt/blob/master/blog/coachella/coachella.gpt)

![render_input](https://github.com/randall-coding/coachella-gpt/assets/39175191/1b768d71-3d3a-4791-91a2-3254967b239b)

## Install GPTScript
The first thing we need to do is follow these [instructions](https://github.com/gptscript-ai/gptscript) which will vary slightly depending on your operating system.  I'm running on Linux where the installation step is simply:

`curl https://get.gptscript.ai/install.sh | sh` 

I then set my OpenAI key to this environment variable:

`export OPENAI_API_KEY=your-api-key`

We will also need a variable for Brave Search token set for the search tool:

`export GPTSCRIPT_BRAVE_SEARCH_TOKEN=your-api-key`

## Mission 1: Capturing the Coachella Lineup

Let's start by creating our first tool to capture the upcoming coachella lineup.  The simplest way to capture a website with GPTscript is using the built in `sys.http.html2text?` tool.  As the name implies it converts an http request into text that ChatGPT can process.  

Using coachella's official lineup page https://www.coachella.com/lineup I created a tool like this:

[*coachella.gpt*]
```
---
name: download-coachella-content
description: Content of coachella lineup page
tools: sys.http.html2text?
Visit the page "https://www.coachella.com/lineup" and pull all the names of upcoming bands playing there.  Output to console.
```

Running this script with `gptscript coachella.gpt` doesn't produce any results.  What happened?

Coachella loads its content dynamically, so we'll need a different solution.  We could create a python script that uses selenium, which I did [here](https://github.com/randall-coding/coachella-gpt/blob/master/download-website-content.py) but coachella's website has another problem of being slow and sometimes not returning data at all. So I found another website that publishes the Coachella lineup each year called pitchfork.com.  The new tool uses the brave search feature:

[*coachella.gpt*]
```
---
name: download-coachella-content
description: Downloads the content of coachella lineup page into file lineup.txt
tools:  sys.http.html2text?, github.com/gptscript-ai/search/brave

Search for the upcoming coachella lineup based on a specific year (either this year or next year if we passed it) and find the pitchfork.com page for it.
The search should look like "coachella lineup site:pitchfork.com".  Take that url, visit the page and output the bands you find to console
```

We run this again with `gptscript coachella` and see a list of bands:

![output_lineup_only](https://github.com/randall-coding/coachella-gpt/assets/39175191/98a712fa-1a60-4aae-8f09-c0b8d634fc90)

## Mission 2: Saving the Lineup

What if we want to save the lineup and use it for later?  For that, we'll need to use the `sys.write` tool. 
After we add the tool to our tools list we simply tell out script to write to a given filename as shown below:

[*coachella.gpt*]
```
---
name: download-coachella-content
description: Downloads the content of coachella lineup page into file lineup.txt
tools:  sys.http.html2text?, sys.write, github.com/gptscript-ai/search/brave

Search for the upcoming coachella lineup based on a specific year (either this year or next year if we passed it) and find the pitchfork.com page for it.  The search should look like "coachella lineup site:pitchfork.com".

Take that url, visit the page and save all the bands playing at coachella in lineup.txt.  
```

After running the script, voila, we find `lineup.txt` written with every band present.

![lineup_file_img](https://github.com/randall-coding/coachella-gpt/assets/39175191/ccc5d4db-6673-4df7-a788-9a081cefdb3f)

## Mission 3: Getting Band Recommendations

First we'll need input from the user about bands or genres they like.  Let's just call that input "bands". 
We'll declare the args for the main tool with `args: bands: A list of bands you like.`

Next we need to read the contents of `lineup.txt`.  To do this we will invoke the `sys.read` tool.  As the name implies `sys.read` is for reading a file.

The main tool at the top of the script manages the smaller tools we've created.  Note that the main tool doesn't require a `name` parameter and is located at the top of the script.

[*coachella.gpt*]
```
description: "Make band suggestions at Coachella based on input"
tools: download-coachella-content, find-similar-bands, sys.read, sys.write
args: bands: A list of bands or genres of music you like

Take in user input an output a list of the same + similar bands playing at coachella that the user might like.

---
name: find-similar-bands
description: Finds similar bands from concert
args: lineup.txt: Concert band lineup file
args: bands:   A list of bands or genres of music you like  
tools:  sys.read, sys.write

You are a music expert. You know all abouts bands, music genres and similar bands.  Look through each band/artist in lineup.txt to find all bands in lineup.txt that the user might like based on the "bands" input.  

Write all the bands you find into matches.txt. 

---
name: download-coachella-content
description: Downloads the content of coachella lineup page into file lineup.txt
tools:  sys.http.html2text?, sys.write, github.com/gptscript-ai/search/brave

Search for the upcoming coachella lineup based on a specific year (either this year or next year if we passed it) and find the pitchfork.com page for it.  The search should look like "coachella lineup site:pitchfork.com".

Take that url, visit the page and save all the bands playing at coachella in lineup.txt.  

```

After running the script we see this output:

![similar-exact-bands-only](https://github.com/randall-coding/coachella-gpt/assets/39175191/1496da7f-1f1a-4798-baf0-7544398a5bb5)

That has only the exact bands we mentioned and no additional suggestions which is not what we want.

To solve this we'll introduce the concept of LLM **temperature**.  The temperature setting in large language models (LLMs) like GPT affects the model's output randomness. A low temperature (closer to 0) makes the model's responses more predictable and deterministic, whereas a higher temperature (closer to 1.0) leads to more varied and sometimes more creative responses. GPTscript defaults to 0 temperature, so we will set it to 0.3 to increase it and see what happens. 

[*coachella.gpt*]
```
tools:  sys.read, sys.write
temperature: 0.3
```

After running the script again I see `matches.txt` filled with bands.

![longer_matches_console_output](https://github.com/randall-coding/coachella-gpt/assets/39175191/e1d1bbdf-a613-44be-9d04-dd750ab9da6c)

Better!  But now I'm seeing about a dozen bands and sometimes not the original bands input. We always want at least the exact bands that match in addition to several suggestions (and not neceesarily a dozen).  Let's add some language to our prompt to make the output more specific *"...This will include the specific bands from the input as well as several suggestions based on those band preferences."*

## Mission 4: Fetching Songs from Spotify

To fetch songs on Spotify I first created a simple Python script [songs.py](https://github.com/randall-coding/coachella-gpt/blob/master/songs.py).

Then I integrated the script into the get-spotify-songs tool like this:

[*coachella.gpt*]
```
---
name: get-spotify-songs
description: get songs from url of spotify artist
args: url: spotify url for an artist
tools: github.com/gptscript-ai/search/brave
temperature: 0.2

#!python3 songs.py "$url"
```

But when we run our script we see No Doubt's songs are for Franz Ferdinand! 

![franz_ferdinand_small](https://github.com/randall-coding/coachella-gpt/assets/39175191/2197a400-6b13-4f9a-851a-0f9243814917)

This appears to be a hallucination. Since we didn't specifically tell chatGPI how to find the artist's spotify artist pages, it just pulled from its training material.  This seems to not be the most reliable method for finding the spotify page.
 
Luckily, I discovered someone had already created a gptscript tool for the Spotify api ([credit to Grant Linville](https://github.com/g-linville)). 

For the Spotify api we use the pre-made [spotify.yaml](https://github.com/randall-coding/coachella-gpt/blob/master/blog/coachella/spotify.yaml) file which contains the OpenAPI tool definition. This also requires us to OAuth into Spotify as details [here](https://github.com/randall-coding/coachella-gpt/blob/master/blog/coachella/spotify-oauth.md).

Now we update our tool `get-spotify-songs` like so:

[*coachella.gpt*]
```
---
name: get-spotify-songs
description: get songs for each artist or band
args: bands: a list of band
args: numberOfSongs: number of songs to obtain per band or artist
tools: ./spotify.yaml, sys.read, sys.write
temperature: 0.2
internal prompt: false 

For all bands in the list find 3 spotify song for each.  Name and url. For each band wait 1 second between each api call.  Write the bands+songs output to band_spotify.txt file; create it if it doesn't exist.
```    

Upon running this script, we see songs output for every band we found in `matches.txt`.  

![matches_txt_good](https://github.com/randall-coding/coachella-gpt/assets/39175191/c9c8a301-02a0-46e4-b795-d8f4569c15c9)

## Mission 5: Ensure Reliable Outputs

After 3 runs of the script or so ChatGPT started returning only a single output rather than alls bands found in `matches.txt`.  

![single_output_error_console](https://github.com/randall-coding/coachella-gpt/assets/39175191/d072bea5-8c2a-4a47-bb95-ec2a77e20261)
 
If `matches.txt` has 10 bands, I'm only getting back the first band.

After trying a few different fixes, I added the magic words *"do not abridge the list"* to the prompt regarding the final output.  After adding this line, I was able to perform 12 successful runs in a row.  We'll call that reliable enough for now.

## Mission 6: The final script

Putting all the tools we made together, here is the final working script:

[*coachella.gpt*]
```
tools: sys.read, sys.write, search-coachella, sys.http.html2text?, get-spotify-songs
args: bands: A list of bands you like.
json response: true
temperature: 0.2

Perform the following steps in order:

You are a music expert, concert expert, and expert web researcher.

Based on the user input, find bands on coachella's lineup page which the user would like that are playing.  This will include both the specific bands the user mentioned, arists in a genre, along with similar artists you suggest.  
  
If you found bands playing next at Coachella (matches.txt) find 3 spotify songs for each artist on that list.

The final output will be all the bands+song information from band_spotify.txt you found.  Return it as json format as an array where each object has the following structure { "name": <band name string>, "spotifyUrl": url_value, songs: [{"name": value, "url": song_url_value}] }.

Do not abridge the list or miss any!  Return the final output

---
name: search-coachella
description: Find bands you might like at coachella
args: bands: A list of bands you like.
tools: sys.http.html2text?, sys.read, sys.write, download-coachella-content, find-similar-bands

Do the following in order:

Write down the input bands you've parsed from the input into input.txt file.

Download the contents of coachella lineup into lineup.txt

Next find bands from the input who are playing along with similar bands which are playing at coachella and write the output into matches.txt.

Return all the bands from matches.txt.

---
name: download-coachella-content
description: Downloads the content of coachella lineup page into file lineup.txt
tools:  sys.http.html2text?, sys.read, sys.write, github.com/gptscript-ai/search/brave

If lineup.txt already exists and is for the upcoming show (today's date is before the concert) then skip running tool and output "OK lineup.txt up to date".  Otherwise...

Search for the upcoming coachella lineup based on a specific year (either this year or next year if we passed it) and find the pitchfork.com page for it.  Search should look like "coachella lineup site:pitchfork.com"

Take that url, visit the page and save all the bands playing at coachella in lineup.txt.  

---
name: find-similar-bands
description: Finds similar bands from concert
args: lineup.txt: Concert band lineup file
args: bands:  A list of bands you like   
tools:  sys.read, sys.write
temperature: 0.6
internal prompt: false

You are a music expert. You know all abouts bands, music genres and similar bands.  Look through each band/artist in lineup.txt to find all bands in lineup.txt that the user might like based on the "bands" input.  
This will include the specific bands from the input (all of them) as well as several suggestions based on those band preferences or genres (no more than 3 similar bands if you found specific bands, and no more than 5 similar/genre based bands otherwise). 

Write all the bands you find into matches.txt. 

The matches.txt format will have band names separated by newline instead of comma and no more than 7 total.  

---
name: get-spotify-songs
description: get songs for each artist or band
args: bands: a list of band
args: numberOfSongs: number of songs to obtain per band or artist
tools: search from ./spotify.yaml,get-an-artists-top-tracks from ./spotify.yaml, sys.read, sys.write
#tools: ./spotify.yaml
temperature: 0.2
internal prompt: false 

For all bands in the list find 3 spotify song for each.  Name and url. Write the bands+songs output to band_spotify.txt file; create it if it doesn't exist.
```

## Mission 7: Launching the App

To deploy the app I created a simple Rails [web app](https://github.com/randall-coding/coachella-gpt/tree/master/web) which calls the script and displays the results in a list form.
The end result looks like this:

![good_results_2](https://github.com/randall-coding/coachella-gpt/assets/39175191/73cb38fe-459e-4b49-ba8e-22f0345e5766)

The deployment is live [here](https://coachella-gpt.onrender.com) to try.  It takes a minute to get results right now, but optimizing our script will be the subject of our next blog.

Nevertheless, this shows the power of AI integrations.  We didn't have to write a single api call or complex logic to find / compare similar bands.  I will definitely be integrating GPTScript into my future workflows.
