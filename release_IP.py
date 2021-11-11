def release_ip(IP, username, password, url):
     """
        This script is to release the IP from IBM ip reserve application.
     """

    protocol = "https://"
    url_path = protocol + username + ':' + password + "@"+ url

    op = Options()
    op.add_argument("--allow-running-insecure-content")
    op.add_argument("--ignore-certificate-errors")
    op.add_argument("--headless")
    driver = webdriver.Chrome(options=op)
    driver.get(url_path)
    driver.maximize_window()
    time.sleep(5)

    driver.find_element_by_xpath("//*[@id=\"left-nav\"]/div/a[3]").click()
    time.sleep(4)
    driver.find_element_by_xpath("//*[@id=\"left-nav\"]/div/div/a[3]").click()
    time.sleep(3)

    select = Select(driver.find_element_by_id('SType'))
    # select by visible text
    select.select_by_visible_text('Hostname')

    driver.find_element_by_css_selector("#HostnameSearch input[name='HostnameSearch']").send_keys(IP)
    time.sleep(2)
    driver.find_element_by_xpath("//*[@id=\"SearchForm\"]/div[1]/table/tbody/tr/td[3]/span/input[1]").click()
    time.sleep(10)
    driver.find_element_by_css_selector("input[value='Release']").click()
    time.sleep(3)
    alert = Alert(driver)
    alert.accept()
    time.sleep(10)

    mytext = driver.find_element_by_css_selector("#Message td:nth-child(2)").text
    print(mytext)

    driver.quit()


release_ip(IP="<IP address>", username="<user name>", password="<password>", url="url")
