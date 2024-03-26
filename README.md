# coachella-gpt
GPTScript based application for band recommendations at coachella

This example takes a music band name, then searchs for similar bands by using BRAVE SEARCH API.
Finally, it returns json of bands + 3 songs of each band found on coachella.

## Run the Example

```bash
# Install the packages
pip install -r requirements.txt

# Set your OpenAI key
export OPENAI_API_KEY=your-api-key
export GPTSCRIPT_BRAVE_SEARCH_TOKEN=your-api-key

# Run the example
gptscript coachella.gpt DJ Snake
```
