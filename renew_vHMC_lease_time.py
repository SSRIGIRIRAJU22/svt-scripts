def renew_vHMC_lease_time(USERNAME, PASSWORD, URL):

    op = Options()
    op.add_argument("--allow-running-insecure-content")
    op.add_argument("--ignore-certificate-errors")
    op.add_argument("--headless")
    driver = webdriver.Chrome(options=op)
    driver.get(URL)
    driver.maximize_window()
    time.sleep(5)

    driver.find_element_by_id("login").click()
    time.sleep(5)
    driver.find_element_by_id("email").send_keys(USERNAME)
    driver.find_element_by_id("password").send_keys(PASSWORD)
    driver.find_element_by_id("submit").click()
    time.sleep(5)

    driver.find_element_by_id("x86-tab").click()
    time.sleep(4)
    driver.find_element_by_css_selector("a[class='action btn btn-sm btn-primary']").click()
    time.sleep(2)
    driver.find_element_by_css_selector("button[class='renewlease btn btn-success']").click()
    time.sleep(15)

    driver.find_element_by_id("power-tab").click()
    time.sleep(5)
    driver.find_element_by_css_selector("a[class='action btn btn-sm btn-primary']").click()
    time.sleep(3)
    driver.find_element_by_css_selector("button[class='renewlease btn btn-success']").click()
    time.sleep(15)

    driver.find_element_by_id("logout").click()
    time.sleep(5)
    driver.quit()

renew_vHMC_lease_time(USERNAME="<username>", PASSWORD="<password>", URL="<URL>")
