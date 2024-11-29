import csv
import time
import json
import requests
from bs4 import BeautifulSoup
from concurrent.futures import ThreadPoolExecutor, as_completed


def fetch_and_parse(url):
  try:
    response = requests.get(url)

    if response.status_code == 200:
      soup = BeautifulSoup(response.text, 'html.parser')
      title_element = soup.select_one(
        "body > div > main > div:nth-of-type(2) >  " +
        "div:nth-of-type(1) > div:nth-of-type(1) > " +
        "div:nth-of-type(2) > div > div:nth-of-type(1) > a > h1"
      )

      if title_element:
        title = title_element.get_text()
        target_div = soup.select_one(
          "body > div > main > div:nth-of-type(2) > " +
          "div:nth-of-type(1) > div:nth-of-type(1) > div:nth-of-type(3)"
        )

        if target_div:
          paragraphs = [p.get_text() for p in target_div.find_all('p')]
          content = ' '.join(paragraphs)
          return {'title': title, 'url': url, 'content': content}

        else: print(f"[ FAILED ]: div not found for url -> {url}")

      else: print(f"[ FAILED ]: title element not found for url -> {url}")

    else: print(f"[ FAILED ]: failed to retrieve the page. status code -> {response.status_code} for url -> {url}")

  except Exception as e: print(f"[ FAILED ]: {url} :{e}"); return None


def save_contents(workers):
  with open("links.json", 'r') as file:
    data = json.load(file)

  with open("datasets.csv", 'w', newline = '', encoding = 'utf-8') as csvfile:
    fieldnames = ['title', 'url', 'content']

    writer = csv.DictWriter(csvfile, fieldnames = fieldnames)
    writer.writeheader()

    with ThreadPoolExecutor(max_workers = workers) as executor:
      future_to_url = {
        executor.submit(fetch_and_parse, url):
          url for url in data['links']
      }

      for future in as_completed(future_to_url):
        result = future.result()
        if result: writer.writerow(result); print(f"[ SUCCESS ]: {result['title']}")
