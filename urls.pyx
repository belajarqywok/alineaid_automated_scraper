import os
import time
from selenium import webdriver
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver.common.action_chains import ActionChains

options = webdriver.ChromeOptions()

options.add_argument('--headless')
options.add_argument('--no-sandbox')
options.add_argument('--disable-gpu')
options.add_argument("window-size=1200x600")
options.add_argument('--disable-web-security')
options.add_argument('--allow-running-insecure-content')
options.add_argument('--allow-cross-origin-auth-prompt')


def jscode(int iteration):
    return f"""

function saveToFile(content, filename) {{
    const blob = new Blob([content], {{ type: 'application/json' }});
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');

    a.href = url;
    a.download = filename;

    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
}}

function getToken() {{
    const scripts = document.querySelectorAll('script');
    for (const script of scripts) {{
        const scriptContent = script.textContent;
        const tokenMatch = scriptContent.match(/"_token":"(.*?)"/);
        if (tokenMatch) {{
            return tokenMatch[1];
        }}
    }}
    return null;
}}

function fetchData(nextValue, callback, errorCallback) {{
    const token = getToken();
    if (!token) {{
        errorCallback('Token not found');
        return;
    }}

    const xhr = new XMLHttpRequest();
    xhr.open("POST", "https://www.alinea.id/more", true);
    xhr.setRequestHeader("accept", "text/html, */*; q=0.01");
    xhr.setRequestHeader("content-type", "application/x-www-form-urlencoded; charset=UTF-8");
    xhr.setRequestHeader("x-requested-with", "XMLHttpRequest");

    xhr.onload = function () {{
        if (xhr.status >= 200 && xhr.status < 300) {{
            callback(xhr.responseText);
        }} else {{
            errorCallback(`HTTP error: ${{xhr.status}}`);
        }}
    }};

    xhr.onerror = function () {{
        errorCallback("Network error");
    }};

    const body = new URLSearchParams({{
        "_token": token,
        "next": nextValue,
        "categorynext": ""
    }}).toString();

    xhr.send(body);
}}

function extractUrls(text) {{
    const urlPattern = /https:\\/\\/www\\.alinea\\.id\\/peristiwa\\/[^\s'"]+/g;
    return text.match(urlPattern) || [];
}}

function fetchMultiplePages(iteration, filename) {{
    const uniqueUrls = new Set();
    let completedRequests = 0;

    for (let i = 1; i <= iteration; i++) {{
        const nextValue = (i * 10).toString();
        console.log(`Fetching URLs [${{nextValue}}]`);

        fetchData(nextValue,
            (text) => {{
                const urls = extractUrls(text);
                urls.forEach(url => uniqueUrls.add(url));
                console.log(`URLs found: ${{uniqueUrls.size}}`);

                completedRequests++;
                if (completedRequests === iteration) {{
                    finalize();
                }}
            }},
            (error) => {{
                console.error(`Error fetching data for next=${{nextValue}}:`, error);

                completedRequests++;
                if (completedRequests === iteration) {{
                    finalize();
                }}
            }}
        );
    }}

    function finalize() {{
        if (uniqueUrls.size > 0) {{
            const content = {{ links: Array.from(uniqueUrls) }};
            const jsonString = JSON.stringify(content, null, 2);
            saveToFile(jsonString, filename);
        }} else {{
            console.log('No URLs found');
        }}
    }}
}}

const iteration = {iteration};
const filename = "links";

fetchMultiplePages(iteration, filename);
    """


def save_urls(int iteration):
  browser = webdriver.Chrome(options = options)
  browser.get("https://www.alinea.id/")
  browser.execute_script(jscode(iteration))

  while True:
    if os.path.exists("links.json"): print("Success.."); break
    else: time.sleep(1)
