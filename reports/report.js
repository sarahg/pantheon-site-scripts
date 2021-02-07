/**
 * Fill in our template with report content.
 */
fetch('json/report.json').then(response => {
  return response.json();
}).then(data => {
  console.log(data);

  // Light data massaging.
  let latest_backup_unix_ts = data[0].backups_latest.finished_at;
  let backup_date = new Date(latest_backup_unix_ts * 1000);
  latest_backup = backup_date.toLocaleString();

  // Get the first object in metrics.timeseries. We will always have 2 (this month, last month).
  let metricsLatestKey = Object.keys(data[0].metrics.timeseries)[0];

  // Format numbers nicer (e.g 1234 => 1,234).
  let visits = new Intl.NumberFormat().format(
    data[0].metrics.timeseries[metricsLatestKey].visits
  );
  let pageviews = new Intl.NumberFormat().format(
    data[0].metrics.timeseries[metricsLatestKey].pages_served
  );

  // Build an object of fields/content to populate.
  let replace = {
    "report-domain": data[0].domain,
    "report-month": getReportDate(data),
    "report-uptime": data[0].uptime,
    "report-backups-auto": data[0].backups_on,
    "report-backups-latest": latest_backup,
    "report-exploits": data[0].exploits,
    "report-visits": visits,
    "report-pageviews": pageviews,
  };
  // Update our HTML.
  for (const element in replace) {
    document
      .querySelector(`.${element}`)
      .insertAdjacentHTML("afterbegin", replace[element]);
  }

  // Fill in links for SEO reports.
  let linkBase = data[0].trafficURL;
  let seoReports = ['404s', 'broken-links'];
  for (const report of seoReports) {
    document
      .querySelector(`.report-${report}-url`)
      .setAttribute("href", linkBase + "/" + data[0].month + '-' + report + ".txt");
  }

  // Create update list.
  let updates = data[0].updates;
  let updatesMarkup = "";
  if (updates === undefined || updates.length == 0) {
    updatesMarkup = "<p>No updates needed this month.</p>";
  }
  else {
    updatesMarkup = "<ul>";
    for (const update in updates) {
        // Format the date better.
        let d = new Date(updates[update].datetime);
        let updateDate = d.toLocaleString("en-US", {
          month: "short",
          day: "2-digit",
        });
        updatesMarkup += `<li>${updates[update].message}<br><small>${updateDate}</small></li>`;
    }
    updatesMarkup += "</ul>";
  }
  document.querySelector("#report-updates").insertAdjacentHTML('afterbegin', updatesMarkup)

}).catch(err => {
  console.error('Error loading report.json: ' + err)
});

// https://reactgo.com/javascript-get-previous-month-name/
const getReportDate = (data) => {
  const current = new Date();
  current.setMonth(current.getMonth() - 1);
  let month = current.toLocaleString("default", { month: "long" });
  let reportYear = data[0].month.split("-")[0];
  return `${month} ${reportYear}`;
};