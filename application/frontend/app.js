const apiStatus = document.querySelector("#api-status");
const databaseStatus = document.querySelector("#database-status");
const overallStatus = document.querySelector("#overall-status");
const visitCount = document.querySelector("#visit-count");
const visitButton = document.querySelector("#visit-button");
const statusMessage = document.querySelector("#status-message");

async function getJson(path, options = {}) {
  const response = await fetch(path, {
    ...options,
    headers: { "Content-Type": "application/json", ...options.headers },
  });
  const body = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(body.message || `Request failed (${response.status})`);
  return body;
}

function renderStatus({ api, database }) {
  apiStatus.textContent = api;
  databaseStatus.textContent = database;
  const ready = api === "Healthy" && database === "Healthy";
  overallStatus.className = `status-pill ${ready ? "is-healthy" : "is-unhealthy"}`;
  overallStatus.innerHTML = `<span class="status-dot"></span>${ready ? "All systems go" : "Needs attention"}`;
}

async function loadDashboard() {
  try {
    const [status, visits] = await Promise.all([
      getJson("/api/status"),
      getJson("/api/visits"),
    ]);
    renderStatus({ api: "Healthy", database: status.database === "healthy" ? "Healthy" : "Unavailable" });
    visitCount.textContent = String(visits.total_visits);
    visitButton.disabled = false;
    statusMessage.textContent = "";
  } catch (error) {
    renderStatus({ api: "Unavailable", database: "Unavailable" });
    statusMessage.textContent = `Could not reach the app services. ${error.message}`;
  }
}

visitButton.addEventListener("click", async () => {
  visitButton.disabled = true;
  statusMessage.textContent = "";
  try {
    const result = await getJson("/api/visits", { method: "POST" });
    visitCount.textContent = String(result.total_visits);
  } catch (error) {
    statusMessage.textContent = `Could not record the visit. ${error.message}`;
  } finally {
    visitButton.disabled = false;
  }
});

loadDashboard();
