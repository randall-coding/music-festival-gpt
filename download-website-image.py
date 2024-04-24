import sys
import time
import urllib.request
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.desired_capabilities import DesiredCapabilities
from bs4 import BeautifulSoup

# Get url and filename from command line arguments
url = sys.argv[1]
filename = sys.argv[2] if len(sys.argv) > 2 else 'website.jpg'
css_selector = sys.argv[3] if len(sys.argv) > 3 else None

with open("input.txt", "w") as f:
    f.write(f"url: {url}\nfilename: {filename}\ncss_selector: {css_selector}")

# Setup WebDriver options
options = webdriver.ChromeOptions()
options.add_argument("--headless")
options.add_argument("window-size=1200x600")
options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36")
driver = webdriver.Chrome(options=options)

driver.get(url)

try:
    # Wait for the page to be fully loaded
    print(f"Testing output to stdout")
    WebDriverWait(driver, 50).until(
          EC.presence_of_element_located((By.CSS_SELECTOR, css_selector))
    )
    with open("output.txt", "w") as f:
        f.write("Testing output 2 to stdout\n")
    image_tag = driver.find_element(By.CSS_SELECTOR, css_selector).find_element(By.TAG_NAME, 'img')
    opener = urllib.request.URLopener()
    opener.addheader('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36')
    opener.retrieve(image_tag.get_attribute('src'), filename)

    print(f"Image saved to {filename}")
except Exception as e:
    print("Error:", str(e))
    with open("error.txt", "w") as f:
        f.write(str(e))
finally:
    driver.quit()