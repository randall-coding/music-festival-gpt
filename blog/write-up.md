# Coachella band finder with GPTScript

GPTScript is a scripting language designed to automate interactions with OpenAI's language models. In this post, I'll share how I used it to create a useful tool for music enthusiasts. 

This script will use Coachella's music festival lineup to make personalized band recommendations along with song samples from Spotify.  It must be a lot of work right?  Well, not so much once you know how to use GPTScript.

If you're impatient skip ahead by viewing the the final script [here])(blog/coachella/files)

### Install gptscript cli
The first thing we need to do is follow these [instructions](https://github.com/gptscript-ai/gptscript) which will vary slightly depending on your operating system.  I'm running on Linux where the installation step is simple

`curl https://get.gptscript.ai/install.sh | sh` 

I then set my openai key to this environment variable:

`export OPENAI_API_KEY="your-api-key"`

### Mission 1: Capturing the Coachella Lineup

Let's start by creating our first tool to capture the upcoming coachella lineup.  The simplest way to capture a website is using the built in `sys.http.html2text?` tool.  As the name implies it converts an http request into text that chatGPT can process.  

Using coachella's official lineup page https://www.coachella.com/lineup I created a tool like so:

coachella.gpt
```
---
name: download-coachella-content
description: Content of coachella lineup page
tools: sys.http.html2text?
Visit the page "https://www.coachella.com/lineup" and pull all the names of upcoming bands playing there.  Output to console.
```

Running this script with `gptscript coachella.gpt` doesn't produce any results.  What happened?

Coachella loads its content dynamically, so we'll need a different solution.  We could create a python script that uses selenium, which I did [here](blog/coachella/download-website-content.py) but coachella's website has another problem of being really slow.  I was waiting a full minute for the page to load (I use a vpn so your results may vary). 

Eventually, I found that another website that consistently publishes the Coachella lineup, pitchfork.com.  So I focused my search there like so:

coachella.gpt
```
---
name: download-coachella-content
description: Downloads the content of coachella lineup page into file lineup.txt
tools:  sys.http.html2text?, github.com/gptscript-ai/search/brave

Search for the upcoming coachella lineup based on a specific year (either this year or next year if we passed it) and find the pitchfork.com page for it.  The search should look like "coachella lineup site:pitchfork.com".  Take that url, visit the page and output the bands you find to console
```

We run this again with `gptscript coachella` and see a list of bands:

<output> 

Great!

### Mission 2: Extracting the Lineup

But what if we want to save this lineup and use it for later?  For that, we'll need to add the `sys.write` tool. 
After adding the tool to our list we simply tell out script to write to a given filename.

```
---
name: download-coachella-content
description: Downloads the content of coachella lineup page into file lineup.txt
tools:  sys.http.html2text?, sys.write, github.com/gptscript-ai/search/brave

Search for the upcoming coachella lineup based on a specific year (either this year or next year if we passed it) and find the pitchfork.com page for it.  The search should look like "coachella lineup site:pitchfork.com".

Take that url, visit the page and save all the bands playing at coachella in lineup.txt.  
```

After running the script, voila, we find lineup.txt written with every band present.

<output>

### Mission 3: Getting Band Recommendations

First we'll need input from the user about bands or genres they like.  Let's just call that "bands". 
We'll declare the args for the main tool like so `args: bands: A list of bands you like.`

Next we need to read the contents of the file lineup.txt.  To do this we will invoke the sys.read tool.  Just like sys.write, but sys.read is for reading a file that's already been written.

After adding the apporpriate prompt we add input args to the main tool and also create a sub-tool to organize our script: 

coachella.gpt
```
...
---
name: find-similar-bands
description: Finds similar bands from concert
args: lineup.txt: Concert band lineup file
args: bands:  A list of bands you like   
tools:  sys.read, sys.write

You are a music expert. You know all abouts bands, music genres and similar bands.  Look through each band/artist in lineup.txt to find all bands in lineup.txt that the user might like based on the "bands" input.  

Write all the bands you find into matches.txt. 
```

After running the script here is the output:

<output>

Only one band and no additional suggestions.  That's not what we want.

To solve this we'll introduce the concept of LLM temperature.  The "temperature" setting in large language models (LLMs) like GPT affects the model's output randomness. A low temperature (closer to 0) makes the model's responses more predictable and deterministic, whereas a higher temperature (close to 1.0) leads to more varied and sometimes more creative responses. We'll leverage this creativity to help chatGPT find more similar bands.  GPTscript defaults to 0 temperature, so we will set it to 0.3 to increase it. 

coachella.gpt
```
...
tools:  sys.read, sys.write
temperature: 0.3
...
```

After running the script again I see matches.txt filled with bands.

<output> 

I'm seeing about a dozen bands and sometimes not the original bands input. But we always want at least the exact bands that match in addition to several suggestions (and not neceesarily a dozen).  Let's add this language to our prompt to make the output more specific "...This will include the specific bands from the input as well as several suggestions based on those band preferences."

Voila, on the next run we see a proper 7 bands output including our specific bands of choice.

### Mission 4: Fetching Songs from Spotify

To fetch songs on Spotify I first created a simple Python script.

songs.py
```
import sys
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

# Get url
url = sys.argv[1]

# Setup WebDriver options
options = webdriver.ChromeOptions()
options.add_argument("--headless")
options.add_argument("--no-sandbox")
options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36")
driver = webdriver.Chrome(options=options)

# Navigate to the page and get field
driver.get(url)
try:
    WebDriverWait(driver, 50).until(
        EC.presence_of_element_located((By.CSS_SELECTOR, "div[data-testid='tracklist-row']"))
    )

    elements = driver.find_elements(By.CSS_SELECTOR, "div[data-testid='tracklist-row']")

    songs = []
    
    for element in elements:
      link_element = element.find_element(By.CSS_SELECTOR, "div:nth-child(2) > div:last-child > a")
      song_name_element = element.find_element(By.CSS_SELECTOR, "div:nth-child(2) > div:last-child > a > div")
      songs.append({ "url": link_element.get_attribute('href'), "name": song_name_element.text})

    print(songs[0:3])
except:
    print("Error")
finally:
    driver.quit()

```

coachella.gpt
```
...
---
name: get-spotify-songs
description: get songs from url of spotify artist
args: url: spotify url for an artist
tools: github.com/gptscript-ai/search/brave
temperature: 0.2

#!python3 songs.py "$url"
```

<output Franz Ferdinand?> 

When we run our script we see No Doubt's songs are for Franz Ferdinand!  This appears to be a hallucination. Since we didn't specifically tell chatGPI how to find the artist's spotify artist pages, it just pulled from its LLM memory.  This is not the most reliable method for finding the url.
 
Luckily, I discovered someone had already created a great gptscript tool for the spotify api ([linked here]()). 

For the spotify api we use the pre-made spotify.yaml file which contains the OpenAPI tool definition.  By declaring the tool like so `tools: ./spotify.yaml` we assume spotify.yaml is in the same folder as our coachella.gpt file.

Using this new tool we can update our sub tool 'get-spotify-songs'

coachella.gpt
```
...
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

Upon running this script, we see songs output for every band we found in matches.txt.  

### Mission 5: Ensuring Reliable Outputs

  Now it seemed like everything was going well, but after 3 runs or so of the script chatGPT starts giving me back only a single output rather than alls bands found in matches.txt.  If matches.txt has 10 bands, I'm only getting back the first band.  This was strange to me as someone new to prompt engineering. 

   After trying a few different fixes, I add the magic words "do not abridge the list" to the prompt regarding the final output.  After adding that line to the prompt, I was able to see 12 successful runs in a row showing several correct band suggestions.  Well that's good enough for me.  Hopefully it holds up for 100 or more runs.

### Mission 6: Launching the App

To deploy the app I created a simple Rails web app, which calls the script and displays the results in a list form.
The end result looks like this:

![](picture_of_website_post_query)

This project showed me how AI script integrations can simplify complex tasks and provide valuable services in an accessible way.  I will definitely be integrateing gptscript into my future workflows.

