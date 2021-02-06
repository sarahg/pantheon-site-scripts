/**
 * Fill in our template with report content.
 */
fetch('json/report.json').then(response => {
  return response.json();
}).then(data => {
  console.log(data);

  // Light data massaging.
  let latest_backup = data[0].backups_latest.finished_at; // @todo convert timestamp

  // Get the first object in metrics.timeseries.
  // This has to have two records because Terminus doesn't allow for a daterange.
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
    "report-month": data[0].month, // @todo fix format
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
      .setAttribute("href", linkBase + "/" + report + ".txt");
  }

  // Create update list. @todo

}).catch(err => {
  console.error('Error loading report.json: ' + err)
});
