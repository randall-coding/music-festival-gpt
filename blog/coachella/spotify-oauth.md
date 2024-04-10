First, go to https://developer.spotify.com/dashboard and create a new app. Set the redirect URI to http://localhost:8080/callback and select the Web API.

Then, run this little Go webserver with `go run <file>`:

```
package main

import (
    "fmt"
    "log"
    "net/http"
)

func main() {
    http.HandleFunc("/callback", func(w http.ResponseWriter, r *http.Request) {
        code := r.URL.Query().Get("code")
        if code == "" {
            fmt.Fprintf(w, "Authorization code not found\n")
        } else {
            fmt.Fprintf(w, "Authorization code: %s\n", code)
            // Now, you can exchange this code for an access token.
        }
    })

    fmt.Println("Server starting on http://localhost:8080/callback")
    log.Fatal(http.ListenAndServe(":8080", nil))
}
```

Next, go to your app's settings in the Spotify dashboard and copy the client ID. Paste it into its place in this URL, and go to this URL in your browser:

`https://accounts.spotify.com/authorize?response_type=code&client_id=<CLIENT ID>&scope=user-library-read,user-library-modify,user-top-read,playlist-read-private,playlist-read-collaborative,playlist-modify-public,playlist-modify-private,user-read-private,user-read-email,user-follow-read,user-follow-modify&redirect_uri=http%3a%2f%2flocalhost%3a8080%2fcallback&state=asdfasdfasdf`

In your browser, authorize the app to access your Spotify account. You should get redirected to a page served by your Go webserver. Copy the authorization code that you have there.

Next, run this curl command: `curl -X POST -H "Authorization: Basic $(echo -n <client ID>:<client secret> | base64 -w 0)" -d grant_type=authorization_code -d code=<authorization code> -d redirect_uri=http://localhost:8080/callback https://accounts.spotify.com/api/token` , 

but add your app's client ID and secret into it, as well as the authorization code you got. You should get an access token and a refresh token in the response. The access token is only valid for one hour.

To use the refresh token to get a new access token, run this curl command: `curl -X POST -H "Authorization: Basic $(echo -n <client ID>:<client secret> | base64 -w 0)" -d grant_type=refresh_token -d refresh_token=<refresh token> -d redirect_uri=http://localhost:8080/callback https://accounts.spotify.com/api/token`

Save your access token to GPTSCRIPT_API_SPOTIFY_COM_BEARER_TOKEN.