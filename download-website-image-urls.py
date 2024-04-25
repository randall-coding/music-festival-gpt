import sys
import urllib.request
from bs4 import BeautifulSoup

url = sys.argv[1]
css_selector = sys.argv[2] if len(sys.argv) > 1 else None
filename = sys.argv[3] if len(sys.argv) > 2 else 'image_urls.txt'
print(url)
print(css_selector)
print(filename)
try:
  opener = urllib.request.URLopener()
  opener.addheader('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36')
  f = opener.open(url)
  page = f.read()
  f.close()          
  soup = BeautifulSoup(page, features="html.parser")
  content = soup.select_one(css_selector) if css_selector else soup
  with open (filename, 'w', encoding='utf-8') as f:
    for link in content.findAll("img"):
      f.write(link['src'])
      f.write('\n')
  print(f"Image urls were saved to {filename}")
except Exception as e:
    print("Error:", str(e))