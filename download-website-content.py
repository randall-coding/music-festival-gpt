import sys
import time 
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.desired_capabilities import DesiredCapabilities
from bs4 import BeautifulSoup

# Get url and filename from command line arguments
url = sys.argv[1]
filename = sys.argv[2] if len(sys.argv) > 2 else 'website.txt'
wait_time = int(sys.argv[3]) if len(sys.argv) > 3 and sys.argv[3].isdigit() else None
css_selector = sys.argv[4] if len(sys.argv) > 4 else None

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
    if css_selector and not wait_time_seconds:
      WebDriverWait(driver, 50).until(
          EC.presence_of_element_located((By.CSS_SELECTOR, css_selector))
    )
    elif wait_time:
        print(f"Waiting for {wait_time} seconds")
        time.sleep(wait_time)
    else:
        WebDriverWait(driver, 50).until(
            lambda d: d.execute_script('return document.readyState') == 'complete'
        )
    
    # Store page source in a variable
    page_source = driver.page_source
    soup = BeautifulSoup(page_source, 'html.parser')
    body_content = soup.body

    # Write page source to the specified filename
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(str(body_content))

    print(f"Page source has been saved to {filename}")

except Exception as e:
    print("Error:", str(e))
finally:
    driver.quit()