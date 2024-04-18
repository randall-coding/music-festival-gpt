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
