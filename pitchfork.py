import sys
import json
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

# Get url
url = sys.argv[1]

# Setup WebDriver options
options = webdriver.ChromeOptions()
options.add_argument("--headless")
options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.212 Safari/537.36")
driver = webdriver.Chrome(options=options)

# Navigate to the page and get field
driver.get(url)
try:
    WebDriverWait(driver, 50).until(
        EC.presence_of_element_located((By.CSS_SELECTOR, "div[class='artistGrid'] > div > div > div > div > div[class='title']"))
    )
    elements = driver.find_elements(By.CSS_SELECTOR, "div[class='artistGrid'] > div > div[class='scene artistTile']")
    
    # write elements to output.txt
    with open('output.txt', 'w') as f:
        for element in elements:
            f.write(element.get_attribute('innerHTML'))

    info = []

    for element in elements:
        name_element = element.find_element(By.CSS_SELECTOR, "div > div > div[class='title']")
        url_element = element.find_elements(By.CSS_SELECTOR, "div[class='links'] > span > a[href^='https://open.spotify.com']")
        if len(url_element) > 0:
            info.append({ "name": name_element.text, "url": url_element[0].get_attribute('href')})
    
    with open('output.txt', 'w') as f:
        for data in info:
            f.write(json.dumps(data))
            f.write("\n")

    print(json.dumps(info))
except Exception as e:
    with open('output.txt', 'w') as f:
        f.write(str(e))
    print("Error")
finally:
    driver.quit()
