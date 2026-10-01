const result = document.getElementById("result");
const pingButton = document.getElementById("pingButton");

function apiBaseUrl() {
  if (window.APP_CONFIG && window.APP_CONFIG.apiBaseUrl) {
    return window.APP_CONFIG.apiBaseUrl;
  }
  return "http://localhost:8000";
}

pingButton.addEventListener("click", async () => {
  const url = `${apiBaseUrl()}/hello`;
  result.textContent = `Calling ${url} ...`;
  try {
    const response = await fetch(url, { method: "GET" });
    const payload = await response.json();
    result.textContent = JSON.stringify(payload, null, 2);
  } catch (error) {
    result.textContent = `Request failed: ${error}`;
  }
});
